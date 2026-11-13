<?php
declare(strict_types=1);

/**
 * Cikoko PPSU leave API, mounted from index.php before its main auth/router.
 * Requires migrate_pjlp_leave.sql and existing mobile_auth(), mobile_db().
 * Official QR files are server-private and appear only on an approved PDF.
 */
function pjlp_fail(string $message, int $status=422):void { mobile_error($message,$status); }
function pjlp_admin(array $actor):bool { return in_array((string)$actor['user_role'],['admin','admin_kelurahan'],true); }
function pjlp_date(string $raw):?DateTimeImmutable {
 if(!preg_match('/^\d{4}-\d{2}-\d{2}$/D',$raw))return null;
 $d=DateTimeImmutable::createFromFormat('!Y-m-d',$raw);
 return $d&&$d->format('Y-m-d')===$raw?$d:null;
}
function pjlp_employee(PDO $db,string $uid):?array {
 $s=$db->prepare('SELECT * FROM pjlp_employees WHERE user_id=? AND active=1');
 $s->execute([$uid]);return $s->fetch(PDO::FETCH_ASSOC)?:null;
}
function pjlp_audit(PDO $db,?int $requestId,string $actor,string $event,array $details=[]):void {
 $s=$db->prepare('INSERT INTO pjlp_leave_audit(request_id,actor_user_id,event_name,details_json) VALUES(?,?,?,?)');
 $s->execute([$requestId,$actor,$event,json_encode($details,JSON_UNESCAPED_UNICODE)]);
}
function pjlp_notify(PDO $db,string $recipient,string $title,string $message):void {
 try{
  $s=$db->prepare("INSERT INTO mobile_events(category,title,message,audience,recipient) VALUES('leave',?,?,'private',?)");
  $s->execute([$title,$message,$recipient]);
 }catch(Throwable $e){error_log('PJLP leave notification: '.$e->getMessage());}
}
function pjlp_valid_official(PDO $db,string $uid):?array {
 $s=$db->prepare('SELECT * FROM pjlp_officials WHERE user_id=?');
 $s->execute([$uid]);return $s->fetch(PDO::FETCH_ASSOC)?:null;
}
function pjlp_days(PDO $db,DateTimeImmutable $start,DateTimeImmutable $end):int {
 $s=$db->prepare('SELECT holiday_date FROM pjlp_holidays WHERE holiday_date BETWEEN ? AND ?');
 $s->execute([$start->format('Y-m-d'),$end->format('Y-m-d')]);
 $off=array_flip($s->fetchAll(PDO::FETCH_COLUMN));
 $n=0;
 for($d=$start;$d<=$end;$d=$d->modify('+1 day')){
  if((int)$d->format('N')<=5&&!isset($off[$d->format('Y-m-d')]))$n++;
 }
 return $n;
}
function pjlp_request(PDO $db,int $id,bool $lock=false):?array {
 $sql='SELECT r.*,e.user_id,e.id_phl,e.full_name,e.position_name,e.work_unit,e.hired_on,e.supervisor_user_id FROM pjlp_leave_requests r JOIN pjlp_employees e ON e.id=r.employee_id WHERE r.id=?'.($lock?' FOR UPDATE':'');
 $s=$db->prepare($sql);$s->execute([$id]);return $s->fetch(PDO::FETCH_ASSOC)?:null;
}
function pjlp_allow_view(array $r,array $u):bool {
 return pjlp_admin($u)||in_array((string)$u['user_role'],['lurah'],true)||(string)$r['user_id']===(string)$u['user_id']||(string)$r['supervisor_user_id']===(string)$u['user_id'];
}
function pjlp_user(array $actor):array {
 $profile=null;
 foreach(db_read('portal_users') as $p){
  if((string)($p['id']??'')===(string)$actor['user_id']&&($p['active']??false)){$profile=$p;break;}
 }
 return $profile??[];
}
function pjlp_private_dir(string $part):string {
 $base=__DIR__.'/private/pjlp/'.$part;
 if(!is_dir($base)&&!mkdir($base,0750,true)&&!is_dir($base))pjlp_fail('Penyimpanan berkas cuti belum siap',503);
 return $base;
}
/**
 * Fetch a QR PNG encoding only the public random-token URL (no personal data).
 * QuickChart is a QR rendering service; never send private profile fields.
 */
function pjlp_generate_public_qr(string $token):string {
 $public='https://datawebs.my.id/mobile-api/pjlp_profile.php?id='.$token;
 $service='https://quickchart.io/qr?size=360&margin=2&format=png&text='.rawurlencode($public);
 if(!function_exists('curl_init'))pjlp_fail('Hosting memerlukan ekstensi cURL untuk membuat QR otomatis',503);
 $ch=curl_init($service);
 curl_setopt_array($ch,[CURLOPT_RETURNTRANSFER=>true,CURLOPT_FOLLOWLOCATION=>false,
  CURLOPT_CONNECTTIMEOUT=>5,CURLOPT_TIMEOUT=>15,CURLOPT_SSL_VERIFYPEER=>true,
  CURLOPT_MAXREDIRS=>0,CURLOPT_HTTPHEADER=>['Accept: image/png']]);
 $bytes=curl_exec($ch);$code=(int)curl_getinfo($ch,CURLINFO_HTTP_CODE);curl_close($ch);
 if(!is_string($bytes)||$code!==200||strlen($bytes)>300000||strlen($bytes)<100)
  pjlp_fail('Layanan pembuatan QR sedang tidak tersedia. Silakan coba lagi.',503);
 $info=@getimagesizefromstring($bytes);
 if(!$info||($info[2]??0)!==IMAGETYPE_PNG||$info[0]<200||$info[0]>800||$info[1]<200||$info[1]>800)
  pjlp_fail('Gambar QR dari layanan eksternal tidak valid',503);
 $filename=bin2hex(random_bytes(16)).'.png';
 if(file_put_contents(pjlp_private_dir('qr').'/'.$filename,$bytes,LOCK_EX)===false)
  pjlp_fail('Tidak dapat menyimpan QR pimpinan',503);
 return $filename;
}
function pjlp_store_photo(string $encoded):string {
 if(strlen($encoded)>2900000)pjlp_fail('Foto maksimal 2 MB');
 $bytes=base64_decode($encoded,true);
 if($bytes===false||strlen($bytes)<100||strlen($bytes)>2097152)pjlp_fail('Foto tidak valid');
 $info=@getimagesizefromstring($bytes);
 if(!$info||$info[0]<100||$info[1]<100||$info[0]>2400||$info[1]>2400||$info[0]*$info[1]>4000000)
  pjlp_fail('Resolusi foto tidak sesuai');
 $ext=[IMAGETYPE_JPEG=>'jpg',IMAGETYPE_PNG=>'png'][$info[2]??0]??null;
 if(!$ext)pjlp_fail('Foto harus JPG/PNG');
 $filename=bin2hex(random_bytes(16)).'.'.$ext;
 if(file_put_contents(pjlp_private_dir('photos').'/'.$filename,$bytes,LOCK_EX)===false)
  pjlp_fail('Foto gagal disimpan',503);
 return $filename;
}
function pjlp_mobile_dispatch(string $action,string $method):void {
 $actor=mobile_auth();$db=mobile_db();$uid=(string)$actor['user_id'];
 $role=(string)$actor['user_role'];$admin=pjlp_admin($actor);
 $staff=in_array($role,['ppsu','pjlp','lurah','asn','admin','admin_kelurahan'],true);
 if(!$staff)pjlp_fail('Fitur ini hanya untuk petugas PPSU dan pejabat berwenang',403);
 $self=in_array($role,['ppsu','pjlp'],true)?pjlp_employee($db,$uid):null;
 if($action==='pjlp_me'&&$method==='GET'){
  if(!in_array($role,['ppsu','pjlp'],true))pjlp_fail('Hanya untuk akun PPSU',403);
  $balance=null;
  if($self){
   $s=$db->prepare("SELECT b.allowance_days,b.adjustment_days,COALESCE((SELECT SUM(r.requested_days) FROM pjlp_leave_requests r WHERE r.employee_id=b.employee_id AND r.leave_year=b.leave_year AND r.status='approved'),0) used_days,COALESCE((SELECT SUM(r.requested_days) FROM pjlp_leave_requests r WHERE r.employee_id=b.employee_id AND r.leave_year=b.leave_year AND r.status IN ('pending_admin','pending_supervisor','pending_lurah')),0) held_days FROM pjlp_leave_balances b WHERE b.employee_id=? AND b.leave_year=?");
   $s->execute([(int)$self['id'],(int)date('Y')]);$balance=$s->fetch(PDO::FETCH_ASSOC)?:null;
  }
  mobile_json(['ok'=>true,'employee'=>$self,'balance'=>$balance]);
 }
 if($action==='pjlp_list'&&$method==='GET'){
  if(in_array($role,['ppsu','pjlp'],true)){
   if(!$self)mobile_json(['ok'=>true,'items'=>[]]);
   $s=$db->prepare('SELECT r.* FROM pjlp_leave_requests r WHERE r.employee_id=? ORDER BY r.id DESC LIMIT 150');
   $s->execute([(int)$self['id']]);
  }elseif($admin||$role==='lurah'){
   $s=$db->query('SELECT r.*,e.full_name,e.id_phl,e.supervisor_user_id FROM pjlp_leave_requests r JOIN pjlp_employees e ON e.id=r.employee_id ORDER BY r.id DESC LIMIT 300');
  }else{
   $s=$db->prepare('SELECT r.*,e.full_name,e.id_phl,e.supervisor_user_id FROM pjlp_leave_requests r JOIN pjlp_employees e ON e.id=r.employee_id WHERE e.supervisor_user_id=? ORDER BY r.id DESC LIMIT 150');
   $s->execute([$uid]);
  }
  mobile_json(['ok'=>true,'items'=>$s->fetchAll(PDO::FETCH_ASSOC)]);
 }
 if($action==='pjlp_admin_accounts'&&$method==='GET'){
  if(!$admin)pjlp_fail('Akses admin diperlukan',403);
  $accounts=[];$supervisors=[];$lurah=[];
  foreach(db_read('portal_users') as $p){
   if(!($p['active']??false))continue;
   $row=['user_id'=>(string)($p['id']??''),'name'=>(string)($p['name']??''),'role'=>(string)($p['role']??'')];
   if($row['role']==='pjlp')$accounts[]=$row;
   if(in_array($row['role'],['asn','admin_kelurahan'],true))$supervisors[]=$row;
   if($row['role']==='lurah')$lurah[]=$row;
  }
  $employees=$db->query('SELECT e.*,b.allowance_days,b.adjustment_days FROM pjlp_employees e LEFT JOIN pjlp_leave_balances b ON b.employee_id=e.id AND b.leave_year=YEAR(CURDATE()) ORDER BY e.full_name')->fetchAll(PDO::FETCH_ASSOC);
  mobile_json(['ok'=>true,'accounts'=>$accounts,'supervisors'=>$supervisors,'lurah'=>$lurah,'employees'=>$employees]);
 }
 if($action==='pjlp_officials'&&$method==='GET'){
  if(!$admin)pjlp_fail('Akses admin diperlukan',403);
  $rows=$db->query('SELECT user_id,full_name,title,nip,work_unit,is_public,public_token,photo_file IS NOT NULL AS has_photo,qr_file IS NOT NULL AS has_qr FROM pjlp_officials ORDER BY full_name')->fetchAll(PDO::FETCH_ASSOC);
  mobile_json(['ok'=>true,'items'=>$rows]);
 }
 if($action==='pjlp_employee_save'&&$method==='POST'){
  if(!$admin)pjlp_fail('Akses admin diperlukan',403);
  $b=mobile_body();$userId=mobile_text($b['user_id']??'',80);$phl=mobile_text($b['id_phl']??'',40);
  $hired=mobile_text($b['hired_on']??'',10);$super=mobile_text($b['supervisor_user_id']??'',80);
  if(!$userId||!$phl||!pjlp_date($hired)||$hired>date('Y-m-d')||!$super)pjlp_fail('Akun PJLP, ID PHL, tanggal mulai bekerja, dan atasan wajib diisi');
  $found=null;$superOk=false;
  foreach(db_read('portal_users') as $p){
   if((string)($p['id']??'')===$userId&&($p['active']??false)&&($p['role']??'')==='pjlp')$found=$p;
   if((string)($p['id']??'')===$super&&($p['active']??false)&&in_array($p['role']??'', ['asn','admin_kelurahan'],true))$superOk=true;
  }
  if(!$found||!$superOk)pjlp_fail('Akun PJLP atau atasan tidak ditemukan/aktif');
  $position=mobile_text($b['position_name']??'PJLP PPSU',120);
  $unit=mobile_text($b['work_unit']??'Kantor Kelurahan Cikoko',160);
  $name=mobile_text($found['name']??'',160);
  if(!$name||!$position||!$unit)pjlp_fail('Nama, jabatan, dan unit kerja wajib tersedia');
  $check=$db->prepare('SELECT user_id FROM pjlp_employees WHERE id_phl=? AND user_id<>?');$check->execute([$phl,$userId]);
  if($check->fetchColumn()!==false)pjlp_fail('ID PHL sudah dipakai pegawai lain');
  $s=$db->prepare('INSERT INTO pjlp_employees(user_id,id_phl,full_name,position_name,work_unit,hired_on,supervisor_user_id) VALUES(?,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE id_phl=VALUES(id_phl),full_name=VALUES(full_name),position_name=VALUES(position_name),work_unit=VALUES(work_unit),hired_on=VALUES(hired_on),supervisor_user_id=VALUES(supervisor_user_id)');
  $s->execute([$userId,$phl,$name,$position,$unit,$hired,$super]);
  pjlp_audit($db,null,$uid,'employee_saved',['user_id'=>$userId,'id_phl'=>$phl]);
  mobile_json(['ok'=>true]);
 }
 if($action==='pjlp_balance_set'&&$method==='POST'){
  if(!$admin)pjlp_fail('Akses admin diperlukan',403);
  $b=mobile_body();$employee=(int)($b['employee_id']??0);$year=(int)($b['year']??date('Y'));
  $allow=(int)($b['allowance_days']??-1);
  if($employee<1||$year<2020||$year>2100||$allow<0||$allow>366)pjlp_fail('Jatah cuti tidak valid');
  try {
   $db->beginTransaction();
   $x=$db->prepare('SELECT id FROM pjlp_employees WHERE id=? FOR UPDATE');$x->execute([$employee]);
   if(!$x->fetchColumn())pjlp_fail('Pegawai tidak tersedia',404);
   $reserved=$db->prepare("SELECT COALESCE(SUM(requested_days),0) FROM pjlp_leave_requests WHERE employee_id=? AND leave_year=? AND status IN ('approved','pending_admin','pending_supervisor','pending_lurah')");
   $reserved->execute([$employee,$year]);$used=(int)$reserved->fetchColumn();
   if($allow<$used)pjlp_fail('Jatah tidak boleh lebih rendah dari cuti terpakai dan yang masih diproses');
   $s=$db->prepare('INSERT INTO pjlp_leave_balances(employee_id,leave_year,allowance_days,updated_by) VALUES(?,?,?,?) ON DUPLICATE KEY UPDATE allowance_days=VALUES(allowance_days),updated_by=VALUES(updated_by)');
   $s->execute([$employee,$year,$allow,$uid]);
   pjlp_audit($db,null,$uid,'balance_set',['employee_id'=>$employee,'year'=>$year,'days'=>$allow]);
   $db->commit();mobile_json(['ok'=>true]);
  }catch(Throwable $e){if($db->inTransaction())$db->rollBack();throw $e;}
 }
 if($action==='pjlp_holiday_set'&&$method==='POST'){
  if(!$admin)pjlp_fail('Akses admin diperlukan',403);
  $b=mobile_body();$date=mobile_text($b['date']??'',10);$description=mobile_text($b['description']??'',160);
  if(!pjlp_date($date)||!$description)pjlp_fail('Tanggal dan keterangan hari libur wajib diisi');
  $s=$db->prepare('INSERT INTO pjlp_holidays(holiday_date,description) VALUES(?,?) ON DUPLICATE KEY UPDATE description=VALUES(description)');$s->execute([$date,$description]);
  pjlp_audit($db,null,$uid,'holiday_set',['date'=>$date]);mobile_json(['ok'=>true]);
 }
 if($action==='pjlp_official_save'&&$method==='POST'){
  if(!$admin)pjlp_fail('Akses admin diperlukan',403);
  $body=mobile_body();
  $person=mobile_text($body['user_id']??'',80);
  $name=mobile_text($body['full_name']??'',160);
  $title=mobile_text($body['title']??'',160);
  $nip=mobile_text($body['nip']??'',40);
  $unit=mobile_text($body['work_unit']??'Kelurahan Cikoko',160);
  $public=($body['is_public']??true)!==false;
  if(!$person||!$name||!$title||!$nip||!$unit)pjlp_fail('Akun, nama, jabatan, NIP, dan unit kerja wajib diisi');
  $allowed=false;
  foreach(db_read('portal_users') as $p){
   if((string)($p['id']??'')===$person&&($p['active']??false)&&in_array($p['role']??'', ['lurah','asn','admin_kelurahan'],true))$allowed=true;
  }
  if(!$allowed)pjlp_fail('Akun pejabat tidak aktif atau tidak berwenang');
  $previous=pjlp_valid_official($db,$person);
  $token=(string)($previous['public_token']??'');
  if(!preg_match('/^[a-f0-9]{48}$/D',$token))$token=bin2hex(random_bytes(24));
  $qr=(string)($previous['qr_file']??'');
  if($qr===''||!is_file(pjlp_private_dir('qr').'/'.$qr))$qr=pjlp_generate_public_qr($token);
  $photo=(string)($previous['photo_file']??'');
  $encoded=(string)($body['photo_base64']??'');
  if($encoded!=='')$photo=pjlp_store_photo($encoded);
  $st=$db->prepare('INSERT INTO pjlp_officials(user_id,full_name,title,nip,qr_file,public_token,photo_file,work_unit,is_public) VALUES(?,?,?,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE full_name=VALUES(full_name),title=VALUES(title),nip=VALUES(nip),qr_file=VALUES(qr_file),public_token=VALUES(public_token),photo_file=VALUES(photo_file),work_unit=VALUES(work_unit),is_public=VALUES(is_public)');
  $st->execute([$person,$name,$title,$nip,$qr,$token,$photo,$unit,$public?1:0]);
  pjlp_audit($db,null,$uid,'official_profile_saved',['user_id'=>$person,'photo_updated'=>$encoded!=='','public'=>$public]);
  mobile_json(['ok'=>true,'profile_url'=>'https://datawebs.my.id/mobile-api/pjlp_profile.php?id='.$token]);
 }
 if($action==='pjlp_apply'&&$method==='POST'){
  if(!in_array($role,['ppsu','pjlp'],true)||!$self)pjlp_fail('Admin harus mendaftarkan akun PPSU Anda terlebih dahulu',403);
  $b=mobile_body();$a=pjlp_date((string)($b['start_date']??''));$z=pjlp_date((string)($b['end_date']??''));
  if(!$a||!$z||$z<$a||$a->format('Y')!==$z->format('Y')||$z->diff($a)->days>90)pjlp_fail('Rentang tanggal cuti tidak valid (maksimal 90 hari, satu tahun kalender)');
  $reason=mobile_text($b['reason']??'',1000);$addr=mobile_text($b['leave_address']??'',500);$phone=mobile_text($b['phone']??'',40);
  if(!$reason||!$addr||!preg_match('/^[0-9+() -]{7,40}$/D',$phone))pjlp_fail('Alasan, alamat, dan telepon harus lengkap');
  $days=pjlp_days($db,$a,$z);
  if($days<1)pjlp_fail('Rentang tanggal tidak memiliki hari kerja');
  $year=(int)$a->format('Y');
  // Named lock serializes all leave submissions across different employees.
  // Do not use a per-employee lock: that would permit simultaneous double booking.
  $calendarLock=false;
  try{
   $lockSt=$db->query("SELECT GET_LOCK('cikoko_pjlp_calendar_exclusive',15)");
   if((int)$lockSt->fetchColumn()!==1)pjlp_fail('Kalender cuti sedang diproses, silakan coba lagi',503);
   $calendarLock=true;
   $db->beginTransaction();
   $balance=$db->prepare('SELECT allowance_days,adjustment_days FROM pjlp_leave_balances WHERE employee_id=? AND leave_year=? FOR UPDATE');$balance->execute([(int)$self['id'],$year]);
   $brow=$balance->fetch(PDO::FETCH_ASSOC);
   if(!$brow)pjlp_fail('Admin belum mengatur jatah cuti Anda');
   $used=$db->prepare("SELECT COALESCE(SUM(requested_days),0) FROM pjlp_leave_requests WHERE employee_id=? AND leave_year=? AND status IN ('approved','pending_admin','pending_supervisor','pending_lurah')");
   $used->execute([(int)$self['id'],$year]);
   if($days+(int)$used->fetchColumn()>(int)$brow['allowance_days']+(int)$brow['adjustment_days'])pjlp_fail('Sisa cuti tidak mencukupi');
   // Exclusive calendar: pending and approved requests reserve their full date range,
   // including weekends and holidays inside that range. Rejected/deferred/revision
   // requests release their dates for another employee.
   $overlap=$db->prepare("SELECT r.id,e.full_name FROM pjlp_leave_requests r JOIN pjlp_employees e ON e.id=r.employee_id WHERE r.start_date<=? AND r.end_date>=? AND r.status IN ('approved','pending_admin','pending_supervisor','pending_lurah') ORDER BY r.start_date,r.id LIMIT 1");
   $overlap->execute([$z->format('Y-m-d'),$a->format('Y-m-d')]);
   if($overlap->fetch(PDO::FETCH_ASSOC))pjlp_fail('Tanggal cuti sudah dipesan pegawai lain atau masih menunggu persetujuan. Pilih tanggal lain.',409);
   $save=$db->prepare('INSERT INTO pjlp_leave_requests(employee_id,leave_year,start_date,end_date,requested_days,reason,leave_address,phone) VALUES(?,?,?,?,?,?,?,?)');
   $save->execute([(int)$self['id'],$year,$a->format('Y-m-d'),$z->format('Y-m-d'),$days,$reason,$addr,$phone]);
   $id=(int)$db->lastInsertId();
   pjlp_audit($db,$id,$uid,'submitted',['days'=>$days]);
   $db->commit();
   $db->query("SELECT RELEASE_LOCK('cikoko_pjlp_calendar_exclusive')");$calendarLock=false;
   pjlp_notify($db,'admin','Cuti PJLP baru','Pengajuan cuti nomor '.$id.' menunggu verifikasi');
   mobile_json(['ok'=>true,'id'=>$id,'requested_days'=>$days]);
  }catch(Throwable $e){if($db->inTransaction())$db->rollBack();throw $e;}
  finally{if($calendarLock)$db->query("SELECT RELEASE_LOCK('cikoko_pjlp_calendar_exclusive')");}
 }
 if($action==='pjlp_number_set'&&$method==='POST'){
  if(!$admin)pjlp_fail('Hanya admin yang dapat mengisi nomor surat',403);
  $b=mobile_body();$id=(int)($b['request_id']??0);$number=mobile_text($b['official_number']??'',100);
  if($id<1||!preg_match('/^[a-zA-Z0-9.\/ -]{4,100}$/D',$number))pjlp_fail('Nomor surat tidak valid');
  $s=$db->prepare("UPDATE pjlp_leave_requests SET official_number=? WHERE id=? AND status='pending_admin'");
  $s->execute([$number,$id]);if($s->rowCount()!==1)pjlp_fail('Nomor surat diisi sebelum persetujuan admin',409);
  pjlp_audit($db,$id,$uid,'letter_number_set',['number'=>$number]);mobile_json(['ok'=>true]);
 }
 if($action==='pjlp_review'&&$method==='POST'){
  $b=mobile_body();$id=(int)($b['request_id']??0);$decision=(string)($b['decision']??'');
  $reason=mobile_text($b['reason']??'',1000);
  if($id<1||!in_array($decision,['approve','revision','defer','reject'],true))pjlp_fail('Keputusan tidak valid');
  if($decision!=='approve'&&$reason==='')pjlp_fail('Alasan perubahan/penangguhan/penolakan wajib diisi');
  $pdfPath='';$numberLock=false;
  try {
   if($decision==='approve'){
    $lockSt=$db->query("SELECT GET_LOCK('cikoko_pjlp_letter_number',15)");
    if((int)$lockSt->fetchColumn()!==1)pjlp_fail('Penomoran surat sedang diproses, coba kembali',503);
    $numberLock=true;
   }
   $db->beginTransaction();$r=pjlp_request($db,$id,true);
   if(!$r)pjlp_fail('Pengajuan tidak ditemukan',404);
   // Satu tahap: admin Kelurahan memberi keputusan langsung, tanpa antrean akun atasan/Lurah.
   // Data pejabat pada formulir adalah referensi jabatan; keputusan elektronik dicatat atas nama admin.
   if(!$admin||!in_array((string)$r['status'],['pending_admin','pending_supervisor','pending_lurah'],true))
    pjlp_fail('Hanya admin yang dapat memutuskan pengajuan yang masih diproses',403);
   $stage='admin';
   $next=$decision==='approve'?'approved':(['revision'=>'revision','defer'=>'deferred','reject'=>'rejected'][$decision]);
   if($next==='approved'){
    // Admin may set/edit the official number in the same approval transaction.
    $number=mobile_text($b['official_number']??$r['official_number']??'',100);
    if($number===''){
     $max=34;
     $existing=$db->query("SELECT official_number FROM pjlp_leave_requests WHERE official_number IS NOT NULL");
     foreach($existing->fetchAll(PDO::FETCH_COLUMN) as $oldNumber){
      if(preg_match('~^([0-9]+)/KG 11\\.01$~D',(string)$oldNumber,$m))$max=max($max,(int)$m[1]);
     }
     $number=($max+1).'/KG 11.01';
    }
    if(!preg_match('/^[a-zA-Z0-9.\/ -]{4,100}$/D',$number))pjlp_fail('Nomor surat tidak valid');
    if($number!==(string)$r['official_number']){
     $numSt=$db->prepare('UPDATE pjlp_leave_requests SET official_number=? WHERE id=?');
     $numSt->execute([$number,$id]);
     pjlp_audit($db,$id,$uid,'letter_number_set',['number'=>$number]);
     $r['official_number']=$number;
    }
    if(trim((string)$r['official_number'])==='')pjlp_fail('Isi nomor surat sebelum menyetujui cuti');
    $sup=pjlp_valid_official($db,(string)$r['supervisor_user_id']);
    $lurahRow=$db->query("SELECT user_id FROM pjlp_officials WHERE LOWER(title) LIKE '%lurah%' ORDER BY id LIMIT 1")->fetch(PDO::FETCH_ASSOC);
    $lurah=$lurahRow?pjlp_valid_official($db,(string)$lurahRow['user_id']):null;
    if(!$sup||!$lurah)pjlp_fail('Admin harus melengkapi data atasan langsung dan Lurah');
    // QR pejabat hanya boleh dicetak jika admin memang berwenang memakai QR tetap mereka.
    foreach([$sup,$lurah] as $off){
     if(empty($off['qr_file'])||!is_file(pjlp_private_dir('qr').'/'.$off['qr_file']))
      pjlp_fail('QR resmi atasan/Lurah belum tersedia');
    }
   }
   $st=$db->prepare('INSERT INTO pjlp_leave_approvals(request_id,stage,actor_user_id,decision,reason) VALUES(?,?,?,?,?)');
   $st->execute([$id,$stage,$uid,$decision,$reason]);
   $s=$db->prepare("UPDATE pjlp_leave_requests SET status=?,verified_at=CASE WHEN ?='approved' THEN NOW() ELSE verified_at END WHERE id=?");
   $s->execute([$next,$next,$id]);
   pjlp_audit($db,$id,$uid,'decision',['stage'=>$stage,'decision'=>$decision,'status'=>$next]);
   if($next==='approved'){
    require_once __DIR__.'/pjlp_leave_pdf.php';
    $r=pjlp_request($db,$id);
    $pdf=pjlp_pdf_build($db,$r);
    $pdfPath=pjlp_private_dir('letters').'/'.$id.'.pdf';
    if(is_file($pdfPath))pjlp_fail('Surat sudah pernah diterbitkan',409);
    if(file_put_contents($pdfPath,$pdf,LOCK_EX)===false)pjlp_fail('Surat PDF gagal disimpan',503);
    $sha=hash('sha256',$pdf);
    $shaSt=$db->prepare('UPDATE pjlp_leave_requests SET pdf_sha256=? WHERE id=?');$shaSt->execute([$sha,$id]);
   }
   $db->commit();
   pjlp_notify($db,(string)$r['user_id'],'Status cuti PPSU','Pengajuan nomor '.$id.' berstatus '.$next);
   mobile_json(['ok'=>true,'status'=>$next]);
  }catch(Throwable $e){
   if($db->inTransaction())$db->rollBack();
   if($numberLock)$db->query("SELECT RELEASE_LOCK('cikoko_pjlp_letter_number')");
   if($pdfPath!==''&&is_file($pdfPath))@unlink($pdfPath);
   throw $e;
  }
 }
 if($action==='pjlp_pdf'&&$method==='GET'){
  $id=(int)($_GET['id']??0);$r=pjlp_request($db,$id);
  if(!$r)pjlp_fail('Surat tidak ditemukan',404);
  if(!pjlp_allow_view($r,$actor))pjlp_fail('Tidak berwenang melihat surat ini',403);
  if($r['status']!=='approved'||empty($r['pdf_sha256']))pjlp_fail('PDF final hanya tersedia sesudah pengesahan',409);
  $path=__DIR__.'/private/pjlp/letters/'.$id.'.pdf';
  if(!is_file($path)||!hash_equals((string)$r['pdf_sha256'],hash_file('sha256',$path)))pjlp_fail('Arsip PDF tidak tersedia atau integritas berubah',503);
  header('Content-Type: application/pdf');header('Content-Disposition: inline; filename="Cuti-PPSU-'.$id.'.pdf"');
  header('Cache-Control: private, no-store');header('Content-Length: '.filesize($path));
  readfile($path);exit;
 }
 pjlp_fail('Aksi tidak tersedia',404);
}
