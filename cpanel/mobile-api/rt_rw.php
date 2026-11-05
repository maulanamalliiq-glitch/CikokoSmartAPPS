<?php
declare(strict_types=1);
/**
 * RT/RW correspondence endpoints. Account/area authorization is enforced on
 * the server for every read and mutation. No blanket staff access.
 */
function cikoko_rt_rw_schema(PDO $db):void {
 static $done=false;if($done)return;
 $db->exec('CREATE TABLE IF NOT EXISTS mobile_rt_rw_letters (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id VARCHAR(80) NOT NULL,
  applicant_name VARCHAR(160) NOT NULL,
  rt CHAR(2) NOT NULL, rw CHAR(2) NOT NULL,
  subject VARCHAR(200) NOT NULL,
  form_json LONGTEXT NOT NULL,
  status VARCHAR(24) NOT NULL DEFAULT "menunggu_rt",
  rt_actor VARCHAR(80) NULL, rw_actor VARCHAR(80) NULL,
  rt_signature VARCHAR(100) NULL,rt_stamp VARCHAR(100) NULL,
  rw_signature VARCHAR(100) NULL,rw_stamp VARCHAR(100) NULL,
  rt_signed_at DATETIME NULL,rw_signed_at DATETIME NULL,
  notes TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_user(user_id,id),INDEX idx_area(rt,rw,status,id)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
 $db->exec('CREATE TABLE IF NOT EXISTS mobile_rt_rw_signers (
   user_id VARCHAR(80) PRIMARY KEY, signature_file VARCHAR(100) NOT NULL,
   stamp_file VARCHAR(100) NOT NULL, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
 $done=true;
}
function cikoko_area_value($raw):string {
 $v=trim((string)$raw);
 if(!preg_match('/^[0-9]{1,2}$/',$v)||(int)$v<1||(int)$v>99)mobile_error('RT/RW harus 01–99.',422);
 return str_pad((string)(int)$v,2,'0',STR_PAD_LEFT);
}
function cikoko_area_user(string $id):?array {
 if($id==='admin'){return ['id'=>'admin','role'=>'admin','active'=>true];}
 foreach(db_read('portal_users') as $r) {
  if((string)($r['id']??'')===$id&&($r['active']??false))return $r;
 }
 return null;
}
function cikoko_area_officer(string $role,string $rt,string $rw):?array {
 foreach(db_read('portal_users') as $r){
  if(($r['active']??false)!==true||($r['role']??'')!==$role)continue;
  $theirRw=trim((string)($r['rw']??''));
  if(!preg_match('/^[0-9]{1,2}$/',$theirRw))continue;
  if(str_pad((string)(int)$theirRw,2,'0',STR_PAD_LEFT)!==$rw)continue;
  if($role==='rt'){
   $theirRt=trim((string)($r['rt']??''));
   if(!preg_match('/^[0-9]{1,2}$/',$theirRt))continue;
   if(str_pad((string)(int)$theirRt,2,'0',STR_PAD_LEFT)!==$rt)continue;
  }
  return $r;
 }
 return null;
}
function cikoko_area_actor(array $user,array $letter):bool {
 $uid=(string)$user['user_id'];$role=(string)$user['user_role'];
 if($role==='admin')return true;
 if($uid===(string)$letter['user_id'])return true;
 if($role==='rt'&&$letter['rt_actor']===$uid)return true;
 if($role==='rw'&&$letter['rw_actor']===$uid)return true;
 return false;
}
function cikoko_area_user_password(array $user,string $password):void{
 $actor=cikoko_area_user((string)$user['user_id']);
 if($password===''||!$actor||!password_verify($password,(string)($actor['password_hash']??''))){
  mobile_error('Password petugas tidak sesuai.',403);
 }
}
function cikoko_area_signer(PDO $db,string $uid):?array {
 $q=$db->prepare('SELECT signature_file,stamp_file FROM mobile_rt_rw_signers WHERE user_id=?');
 $q->execute([$uid]);$record=$q->fetch(PDO::FETCH_ASSOC);
 if(!$record)return null;
 foreach(['signature_file','stamp_file'] as $key){
  $name=(string)$record[$key];
  if(!preg_match('/^[a-f0-9]{40}\.(jpg|jpeg|png|webp)$/i',$name)||
     !is_file(__DIR__.'/private/'.$name))return null;
 }
 return $record;
}
function cikoko_area_letter(PDO $db,int $id,array $user,bool $lock=false):array {
 if($id<1)mobile_error('ID surat tidak valid.',422);
 $q=$db->prepare('SELECT * FROM mobile_rt_rw_letters WHERE id=?'.($lock?' FOR UPDATE':''));
 $q->execute([$id]);$letter=$q->fetch(PDO::FETCH_ASSOC);
 if(!$letter)mobile_error('Surat pengantar tidak ditemukan.',404);
 if(!cikoko_area_actor($user,$letter))mobile_error('Surat tidak tersedia untuk akun ini.',403);
 return $letter;
}
function cikoko_area_dispatch(string $action,string $method,PDO $db,array $user):void {
 cikoko_rt_rw_schema($db);
 $uid=(string)$user['user_id'];$role=(string)$user['user_role'];
 if($action==='rt_rw_signer_status'){
  if($method!=='GET')mobile_error('Metode tidak diizinkan.',405);
  if(!in_array($role,['rt','rw'],true))mobile_error('Hanya Ketua RT/RW.',403);
  mobile_json(['ok'=>true,'ready'=>cikoko_area_signer($db,$uid)!==null]);
 }
 if($action==='rt_rw_signer_upload'){
  if($method!=='POST')mobile_error('Metode tidak diizinkan.',405);
  if(!in_array($role,['rt','rw'],true))mobile_error('Hanya Ketua RT/RW.',403);
  cikoko_area_user_password($user,(string)($_POST['password']??''));
  $signature=mobile_file('signature',true);
  $stamp=mobile_file('stamp',true);
  $q=$db->prepare('INSERT INTO mobile_rt_rw_signers(user_id,signature_file,stamp_file) VALUES(?,?,?) ON DUPLICATE KEY UPDATE signature_file=VALUES(signature_file),stamp_file=VALUES(stamp_file)');
  $q->execute([$uid,$signature,$stamp]);
  mobile_json(['ok'=>true,'ready'=>true]);
 }
 if($action==='rt_rw_officers'){
  if($method!=='GET')mobile_error('Metode tidak diizinkan.',405);
  if($role!=='admin')mobile_error('Hanya Admin Utama.',403);
  $rows=[];
  foreach(db_read('portal_users') as $entry)if(in_array($entry['role']??'',['rt','rw'],true)){
   $rows[]=['id'=>$entry['id'],'name'=>$entry['name']??'',
    'role'=>$entry['role'],'rt'=>$entry['rt']??'','rw'=>$entry['rw']??'',
    'active'=>($entry['active']??false)===true];
  }
  mobile_json(['ok'=>true,'items'=>$rows]);
 }
 if($action==='rt_rw_officer_assign'){
  if($method!=='POST')mobile_error('Metode tidak diizinkan.',405);
  if($role!=='admin')mobile_error('Hanya Admin Utama.',403);
  $body=mobile_body();$id=trim((string)($body['officer_id']??''));
  if($id==='')mobile_error('Pilih petugas.',422);
  $users=db_read('portal_users');$found=false;
  foreach($users as &$entry){
   if((string)($entry['id']??'')!==$id)continue;
   if(!in_array($entry['role']??'',['rt','rw'],true))mobile_error('Petugas bukan Ketua RT/RW.',403);
   $entry['rw']=cikoko_area_value($body['rw']??'');
   $entry['rt']=$entry['role']==='rt'?cikoko_area_value($body['rt']??''):'';
   $found=true;break;
  }unset($entry);
  if(!$found)mobile_error('Petugas tidak ditemukan.',404);
  if(!db_write('portal_users',$users))mobile_error('Penugasan gagal disimpan.',503);
  mobile_json(['ok'=>true,'message'=>'Penugasan wilayah tersimpan.']);
 }
 if($action==='rt_rw_submit'){
  if($method!=='POST')mobile_error('Metode tidak diizinkan.',405);
  if($role!=='warga')mobile_error('Hanya warga dapat mengajukan surat.',403);
  $actor=cikoko_area_user($uid);
  if(!$actor)mobile_error('Akun warga belum aktif.',403);
  $rt=cikoko_area_value($actor['rt']??'');
  $rw=cikoko_area_value($actor['rw']??'');
  $rtOfficer=cikoko_area_officer('rt',$rt,$rw);
  $rwOfficer=cikoko_area_officer('rw',$rt,$rw);
  if(!$rtOfficer||!$rwOfficer)mobile_error('Ketua RT/RW wilayah Anda belum ditugaskan. Hubungi admin.',409);
  $input=mobile_body();$raw=$input['form']??null;
  if(!is_array($raw))mobile_error('Data permohonan belum lengkap.',422);
  $allowed=['nama','tempat_lahir','tanggal_lahir','no_ktp_kk','agama',
   'kewarganegaraan','pendidikan','jenis_kelamin','status','pekerjaan',
   'alamat','maksud_keperluan'];
  $form=[];
  foreach($allowed as $key){
   $str=trim((string)($raw[$key]??''));
   if($str===''||mobile_strlen($str)>1500)mobile_error('Periksa kolom '.$key,422);
   $form[$key]=mobile_text($str,1500);
  }
  if(!preg_match('/^\d{4}-\d{2}-\d{2}$/',$form['tanggal_lahir'])||
     !checkdate((int)substr($form['tanggal_lahir'],5,2),(int)substr($form['tanggal_lahir'],8,2),(int)substr($form['tanggal_lahir'],0,4))){
   mobile_error('Tanggal lahir tidak valid.',422);
  }
  $subject=mobile_text($form['maksud_keperluan'],200);
  $q=$db->prepare('INSERT INTO mobile_rt_rw_letters(user_id,applicant_name,rt,rw,subject,form_json,status,rt_actor,rw_actor) VALUES(?,?,?,?,?,?,"menunggu_rt",?,?)');
  $q->execute([$uid,mobile_text($form['nama'],160),$rt,$rw,$subject,
   json_encode($form,JSON_UNESCAPED_UNICODE|JSON_THROW_ON_ERROR),
   (string)$rtOfficer['id'],(string)$rwOfficer['id']]);
  $id=(int)$db->lastInsertId();
  mobile_emit('rt_rw_status','Pengajuan surat terkirim','Nomor register '.$id,'personal',$uid);
  mobile_emit('rt_rw_surat','Pengajuan baru untuk Ketua RT','Surat wilayah RT '.$rt.' / RW '.$rw,'personal',(string)$rtOfficer['id']);
  mobile_json(['ok'=>true,'id'=>$id,'status'=>'menunggu_rt']);
 }
 if($action==='rt_rw_list'){
  if($method!=='GET')mobile_error('Metode tidak diizinkan.',405);
  if($role==='admin'){
   $q=$db->query('SELECT * FROM mobile_rt_rw_letters ORDER BY id DESC LIMIT 100');
  }else{
   $where=$role==='warga'?'user_id=?':($role==='rt'?'rt_actor=?':($role==='rw'?'rw_actor=?':''));
   if(!$where)mobile_error('Tidak memiliki izin melihat surat.',403);
   $q=$db->prepare('SELECT * FROM mobile_rt_rw_letters WHERE '.$where.' ORDER BY id DESC LIMIT 100');
   $q->execute([$uid]);
  }
  $rows=[];
  foreach($q->fetchAll(PDO::FETCH_ASSOC) as $r){
   $rows[]=[
    'id'=>(int)$r['id'],'subject'=>$r['subject'],
    'applicant_name'=>$r['applicant_name'],'rt'=>$r['rt'],'rw'=>$r['rw'],
    'status'=>$r['status'],'notes'=>$r['notes']??'',
    'form'=>json_decode((string)$r['form_json'],true)?:[],
    'created_at'=>$r['created_at'],
    'requires_reaffirm'=>false,
    'pdf_ready'=>$r['status']==='terverifikasi'&&
      $r['rt_signed_at']!==null&&$r['rw_signed_at']!==null,
   ];
  }
  mobile_json(['ok'=>true,'items'=>$rows]);
 }
 if($action==='rt_rw_decide'||$action==='rt_rw_reaffirm'){
  if($method!=='POST')mobile_error('Metode tidak diizinkan.',405);
  if(!in_array($role,['rt','rw'],true))mobile_error('Hanya Ketua RT/RW yang berwenang.',403);
  $b=mobile_body();$id=(int)($b['id']??0);
  $decision=(string)($b['decision']??'');
  if(!in_array($decision,['approve','reject'],true))mobile_error('Keputusan tidak valid.',422);
  $note=mobile_text($b['note']??'',900);
  if($decision==='reject'&&$note==='')mobile_error('Alasan penolakan wajib.',422);
  cikoko_area_user_password($user,(string)($b['current_password']??''));
  $signed=$decision==='approve'?cikoko_area_signer($db,$uid):null;
  if($decision==='approve'&&$signed===null)mobile_error('Lengkapi gambar TTD dan stempel sebelum verifikasi.',409);
  $db->beginTransaction();
  try {
   $letter=cikoko_area_letter($db,$id,$user,true);
   if($role==='rt'&&($letter['rt_actor']!==$uid||$letter['status']!=='menunggu_rt'))mobile_error('Tahap RT bukan kewenangan akun ini.',403);
   if($role==='rw'&&($letter['rw_actor']!==$uid||$letter['status']!=='menunggu_rw'))mobile_error('Tahap RW bukan kewenangan akun ini.',403);
   $next=$decision==='reject'?'ditolak':($role==='rt'?'menunggu_rw':'terverifikasi');
   $sign=$decision==='approve';
   if($role==='rt'){
    $q=$db->prepare('UPDATE mobile_rt_rw_letters SET status=?,notes=?,rt_signature=?,rt_stamp=?,rt_signed_at=IF(?,NOW(),NULL) WHERE id=?');
    $q->execute([$next,$note,$sign?$signed['signature_file']:null,
     $sign?$signed['stamp_file']:null,$sign?1:0,$id]);
   }else{
    $q=$db->prepare('UPDATE mobile_rt_rw_letters SET status=?,notes=?,rw_signature=?,rw_stamp=?,rw_signed_at=IF(?,NOW(),NULL) WHERE id=?');
    $q->execute([$next,$note,$sign?$signed['signature_file']:null,
     $sign?$signed['stamp_file']:null,$sign?1:0,$id]);
   }
   $db->commit();
  }catch(Throwable $e){
   if($db->inTransaction())$db->rollBack();
   throw $e;
  }
  mobile_emit('rt_rw_status','Status Surat Pengantar diperbarui','Status: '.$next,'personal',(string)$letter['user_id']);
  if($next==='menunggu_rw')mobile_emit('rt_rw_surat','Surat menunggu Ketua RW','Pengantar RT '.$letter['rt'].' / RW '.$letter['rw'],'personal',(string)$letter['rw_actor']);
  mobile_json(['ok'=>true,'id'=>$id,'status'=>$next]);
 }
 if($action==='rt_rw_pdf'){
  if($method!=='GET')mobile_error('Metode tidak diizinkan.',405);
  $id=(int)($_GET['id']??0);$record=cikoko_area_letter($db,$id,$user);
  if($record['status']!=='terverifikasi'||!$record['rt_signed_at']||!$record['rw_signed_at']){
   mobile_error('Dokumen belum disetujui lengkap oleh Ketua RT dan RW.',409);
  }
  require_once __DIR__.'/rt_rw_pdf.php';
  cikoko_rt_rw_output_pdf($record);
 }
 mobile_error('Endpoint Surat Pengantar tidak dikenal.',404);
}
