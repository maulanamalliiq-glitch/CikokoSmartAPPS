<?php
declare(strict_types=1);
/**
 * Authorized Cikoko LPJ finance and approval API.
 * All server authorization uses the authenticated role and registered area.
 */
function cikoko_civic_schema(PDO $db):void{
 static $done=false;if($done)return;
 $db->exec('CREATE TABLE IF NOT EXISTS mobile_civic_lpj (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  kind VARCHAR(24) NOT NULL,creator_id VARCHAR(80) NOT NULL,
  creator_name VARCHAR(160) NOT NULL,rt CHAR(2) NOT NULL DEFAULT "",
  rw CHAR(2) NOT NULL DEFAULT "",period CHAR(7) NOT NULL,
  payload_json LONGTEXT NOT NULL,status VARCHAR(30) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_creator(creator_id,id),INDEX idx_area(rw,rt,kind,status)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
 $db->exec('CREATE TABLE IF NOT EXISTS mobile_civic_lpj_approvals(
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  document_id BIGINT UNSIGNED NOT NULL,
  user_id VARCHAR(80) NOT NULL,duty VARCHAR(30) NOT NULL,
  action VARCHAR(24) NOT NULL,notes TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_document(document_id,id)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
 $db->exec('CREATE TABLE IF NOT EXISTS mobile_civic_pins(
  user_id VARCHAR(80) PRIMARY KEY,pin_hash VARCHAR(255) NOT NULL,
  failed_count INT NOT NULL DEFAULT 0,lock_until DATETIME NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
 $done=true;
}
function cikoko_civic_area($v):string{
 $value=trim((string)$v);
 if(!preg_match('/^[0-9]{1,3}$/',$value))return '';
 $number=(int)$value;
 return $number>=1&&$number<=99?str_pad((string)$number,2,'0',STR_PAD_LEFT):'';
}
function cikoko_civic_scope(array $user):array{
 $role=(string)$user['user_role'];$id=(string)$user['user_id'];
 $profile=$role==='admin'?null:cikoko_area_user($id);
 $rw=cikoko_civic_area($profile['rw']??'');
 $rt=cikoko_civic_area($profile['rt']??'');
 return ['duty'=>$role,'rt'=>$rt,'rw'=>$rw];
}
function cikoko_civic_money($raw,string $field):int{
 if(!is_int($raw)&&!(is_string($raw)&&preg_match('/^[0-9]{1,12}$/',$raw)))
  mobile_error('Nominal '.$field.' tidak valid.',422);
 $amount=(int)$raw;
 if($amount<0||$amount>999999999999)mobile_error('Nominal '.$field.' melebihi batas.',422);
 return $amount;
}
function cikoko_civic_can_read(array $user,array $row,array $scope):bool{
 $role=(string)$user['user_role'];$uid=(string)$user['user_id'];
 if($role==='admin'||$uid===(string)$row['creator_id'])return true;
 if($scope['rw']===''||$scope['rw']!==(string)$row['rw'])return false;
 if($role==='rt')return $row['kind']==='lpj_rt'&&$scope['rt']===$row['rt'];
 if($role==='rw')return $row['kind']==='lpj_rw';
 if($role==='lmk')return str_starts_with((string)$row['kind'],'lpj_lmk_');
 return false;
}
function cikoko_civic_row(PDO $db,int $id,array $user,array $scope,bool $lock=false):array{
 if($id<=0)mobile_error('ID LPJ tidak valid.',422);
 $q=$db->prepare('SELECT * FROM mobile_civic_lpj WHERE id=?'.($lock?' FOR UPDATE':''));
 $q->execute([$id]);$row=$q->fetch(PDO::FETCH_ASSOC);
 if(!$row)mobile_error('LPJ tidak ditemukan.',404);
 if(!cikoko_civic_can_read($user,$row,$scope))mobile_error('LPJ bukan kewenangan akun Anda.',403);
 return $row;
}
function cikoko_civic_serialized(array $r,?array $approvals=null):array{
 $data=json_decode((string)$r['payload_json'],true)?:[];
 $record=['id'=>(int)$r['id'],'kind'=>$r['kind'],'period'=>$r['period'],
  'rt'=>$r['rt'],'rw'=>$r['rw'],'status'=>$r['status'],
  'creator_name'=>$r['creator_name'],'created_at'=>$r['created_at']];
 if($approvals!==null){
  $record['payload']=$data;
  $record['approvals']=$approvals;
 }
 return $record;
}
function cikoko_civic_next_officer(string $kind,string $rt,string $rw,string $phase,string $exclude=''):?array{
 $target=($phase==='menunggu_ketua'
  ?($kind==='lpj_rt'?'rt':($kind==='lpj_rw'?'rw':'lmk'))
  :($kind==='lpj_rt'?'bendahara_rt':($kind==='lpj_rw'?'bendahara_rw':'lmk')));
 foreach(db_read('portal_users') as $u){
  if(($u['active']??false)!==true||($u['role']??'')!==$target||
    (string)($u['id']??'')===$exclude)continue;
  if(cikoko_civic_area($u['rw']??'')!==$rw)continue;
  if(in_array($target,['rt','bendahara_rt'],true)&&cikoko_civic_area($u['rt']??'')!==$rt)continue;
  return $u;
 }
 return null;
}
function cikoko_civic_dispatch(string $action,string $method,PDO $db,array $user):void{
 cikoko_civic_schema($db);
 $role=(string)$user['user_role'];$uid=(string)$user['user_id'];
 $scope=cikoko_civic_scope($user);
 if($action==='civic_catalog'){
  if($method!=='GET')mobile_error('Metode tidak didukung.',405);
  mobile_json(['ok'=>true,'scope'=>$scope,'kinds'=>['lpj_rt','lpj_rw','lpj_lmk_a','lpj_lmk_b']]);
 }
 if($action==='civic_list'){
  if($method!=='GET')mobile_error('Metode tidak didukung.',405);
  if($role==='admin'){
   $q=$db->query('SELECT * FROM mobile_civic_lpj ORDER BY id DESC LIMIT 120');
  }elseif(in_array($role,['bendahara_rt','bendahara_rw'],true)){
   $q=$db->prepare('SELECT * FROM mobile_civic_lpj WHERE creator_id=? ORDER BY id DESC LIMIT 120');
   $q->execute([$uid]);
  }elseif($role==='rt'&&$scope['rt']!==''&&$scope['rw']!==''){
   $q=$db->prepare('SELECT * FROM mobile_civic_lpj WHERE kind="lpj_rt" AND rt=? AND rw=? ORDER BY id DESC LIMIT 120');
   $q->execute([$scope['rt'],$scope['rw']]);
  }elseif($role==='rw'&&$scope['rw']!==''){
   $q=$db->prepare('SELECT * FROM mobile_civic_lpj WHERE kind="lpj_rw" AND rw=? ORDER BY id DESC LIMIT 120');
   $q->execute([$scope['rw']]);
  }elseif($role==='lmk'&&$scope['rw']!==''){
   $q=$db->prepare('SELECT * FROM mobile_civic_lpj WHERE kind IN ("lpj_lmk_a","lpj_lmk_b") AND rw=? ORDER BY id DESC LIMIT 120');
   $q->execute([$scope['rw']]);
  }else{
   mobile_json(['ok'=>true,'items'=>[]]);
  }
  $rows=[];
  foreach($q->fetchAll(PDO::FETCH_ASSOC) as $r)if(cikoko_civic_can_read($user,$r,$scope))$rows[]=cikoko_civic_serialized($r);
  mobile_json(['ok'=>true,'items'=>$rows]);
 }
 if($action==='civic_submit'){
  if($method!=='POST')mobile_error('Metode tidak didukung.',405);
  $body=mobile_body();$kind=(string)($body['kind']??'');
  $required=['lpj_rt'=>'bendahara_rt','lpj_rw'=>'bendahara_rw',
   'lpj_lmk_a'=>'lmk','lpj_lmk_b'=>'lmk'];
  if(!isset($required[$kind])||$role!==$required[$kind])mobile_error('Jabatan tidak berhak mengajukan LPJ ini.',403);
  if($scope['rw']===''||($kind==='lpj_rt'&&$scope['rt']===''))mobile_error('Wilayah akun belum ditugaskan admin.',409);
  $period=(string)($body['period']??'');
  if(!preg_match('/^20[0-9]{2}-(0[1-9]|1[0-2])$/',$period))mobile_error('Periode LPJ harus YYYY-MM.',422);
  $fields=$body['fields']??null;
  if(!is_array($fields))mobile_error('Isi LPJ belum lengkap.',422);
  $opening=cikoko_civic_money($fields['opening']??null,'saldo awal');
  $income=cikoko_civic_money($fields['income']??null,'penerimaan');
  $entries=$fields['entries']??null;
  if(!is_array($entries)||count($entries)>60)mobile_error('Rincian pengeluaran tidak valid.',422);
  $clean=[];$total=0;
  foreach($entries as $item){
   if(!is_array($item))mobile_error('Rincian LPJ tidak valid.',422);
   $activity=trim((string)($item['activity']??''));
   $notes=trim((string)($item['notes']??''));
   if(mobile_strlen($activity)<3||mobile_strlen($activity)>160||mobile_strlen($notes)>500)
    mobile_error('Periksa nama kegiatan dan keterangan.',422);
   $amount=cikoko_civic_money($item['amount']??null,'pengeluaran');
   $total+=$amount;
   if($total>999999999999)mobile_error('Total pengeluaran melebihi batas.',422);
   $clean[]=['activity'=>$activity,'amount'=>$amount,'notes'=>$notes];
  }
  if($total>$opening+$income)mobile_error('Pengeluaran melebihi penerimaan.',422);
  $status=str_starts_with($kind,'lpj_lmk_')?'menunggu_lmk':'menunggu_ketua';
  $target=cikoko_civic_next_officer($kind,$scope['rt'],$scope['rw'],$status,$uid);
  if(!$target)mobile_error('Petugas peninjau LPJ wilayah belum tersedia. Hubungi Admin Utama.',409);
  $payload=['opening'=>$opening,'income'=>$income,'entries'=>$clean,
   'total_expenses'=>$total,'closing'=>$opening+$income-$total];
  $q=$db->prepare('INSERT INTO mobile_civic_lpj(kind,creator_id,creator_name,rt,rw,period,payload_json,status) VALUES(?,?,?,?,?,?,?,?)');
  $q->execute([$kind,$uid,mobile_text(cikoko_area_user($uid)['name']??$user['username'],160),$scope['rt'],$scope['rw'],$period,
   json_encode($payload,JSON_UNESCAPED_UNICODE|JSON_THROW_ON_ERROR),$status]);
  $id=(int)$db->lastInsertId();
  mobile_emit('laporan_masuk','LPJ berhasil diajukan','LPJ nomor '.$id.' menunggu persetujuan.','personal',$uid);
  mobile_emit('laporan_masuk','LPJ menunggu persetujuan','LPJ nomor '.$id.' untuk wilayah Anda.','personal',(string)$target['id']);
  mobile_json(['ok'=>true,'id'=>$id,'status'=>$status]);
 }
 if($action==='civic_detail'){
  if($method!=='GET')mobile_error('Metode tidak didukung.',405);
  $r=cikoko_civic_row($db,(int)($_GET['id']??0),$user,$scope);
  $q=$db->prepare('SELECT duty,action,notes,created_at FROM mobile_civic_lpj_approvals WHERE document_id=? ORDER BY id');
  $q->execute([(int)$r['id']]);
  mobile_json(['ok'=>true,'item'=>cikoko_civic_serialized($r,$q->fetchAll(PDO::FETCH_ASSOC))]);
 }
 if($action==='civic_pin_set'){
  if($method!=='POST')mobile_error('Metode tidak didukung.',405);
  if(!in_array($role,['rt','rw','lmk','bendahara_rt','bendahara_rw'],true))mobile_error('Tidak berwenang menyetujui LPJ.',403);
  $b=mobile_body();$pin=(string)($b['pin']??'');$password=(string)($b['current_password']??'');
  if(!preg_match('/^[0-9]{6}$/',$pin))mobile_error('PIN wajib 6 angka.',422);
  $account=cikoko_area_user($uid);
  if(!$account||$password===''||!password_verify($password,(string)($account['password_hash']??''))){
   mobile_error('Konfirmasi password akun tidak benar.',403);
  }
  $hash=password_hash($pin,PASSWORD_DEFAULT);
  $db->prepare('INSERT INTO mobile_civic_pins(user_id,pin_hash,failed_count,lock_until) VALUES(?,?,0,NULL) ON DUPLICATE KEY UPDATE pin_hash=VALUES(pin_hash),failed_count=0,lock_until=NULL')
    ->execute([$uid,$hash]);
  mobile_json(['ok'=>true,'message'=>'PIN berhasil disimpan.']);
 }
 if($action==='civic_review'){
  if($method!=='POST')mobile_error('Metode tidak didukung.',405);
  if(!in_array($role,['rt','rw','lmk','bendahara_rt','bendahara_rw'],true))mobile_error('Tidak berwenang meninjau LPJ.',403);
  $b=mobile_body();$id=(int)($b['id']??0);
  $decision=(string)($b['decision']??'');$notes=mobile_text($b['notes']??'',900);
  if(!in_array($decision,['approve','return'],true))mobile_error('Keputusan tidak dikenal.',422);
  if($decision==='return'&&mobile_strlen($notes)<5)mobile_error('Alasan perbaikan minimal 5 karakter.',422);
  $pin=(string)($b['pin']??'');
  if($decision==='approve'&&!preg_match('/^[0-9]{6}$/',$pin))mobile_error('PIN persetujuan harus 6 angka.',422);
  $db->beginTransaction();
  try {
   $r=cikoko_civic_row($db,$id,$user,$scope,true);
   $expected=$r['status']==='menunggu_ketua'?
     ($r['kind']==='lpj_rt'?'rt':'rw'):
     ($r['status']==='menunggu_bendahara'?
       ($r['kind']==='lpj_rt'?'bendahara_rt':'bendahara_rw'):
       ($r['status']==='menunggu_lmk'?'lmk':''));
   if($expected===''||$role!==$expected)mobile_error('LPJ sedang tidak menunggu persetujuan akun ini.',403);
   if($role==='lmk'&&(string)$r['creator_id']===$uid)mobile_error('Pembuat LPJ tidak boleh menyetujui laporan sendiri.',403);
   if($decision==='approve'){
    $q=$db->prepare('SELECT pin_hash,failed_count,lock_until FROM mobile_civic_pins WHERE user_id=? FOR UPDATE');
    $q->execute([$uid]);$saved=$q->fetch(PDO::FETCH_ASSOC);
    if(!$saved)mobile_error('Atur PIN persetujuan terlebih dahulu.',409);
    if(!empty($saved['lock_until'])&&strtotime($saved['lock_until'])>time())mobile_error('PIN terkunci sementara akibat percobaan berulang.',429);
    if(!password_verify($pin,(string)$saved['pin_hash'])){
     $failures=(int)$saved['failed_count']+1;
     $db->prepare('UPDATE mobile_civic_pins SET failed_count=?,lock_until=IF(?>=5,DATE_ADD(NOW(),INTERVAL 15 MINUTE),NULL) WHERE user_id=?')
       ->execute([$failures,$failures,$uid]);
     $db->commit();
     mobile_error('PIN tidak cocok. Setelah lima kali gagal, akses dikunci 15 menit.',403);
    }
    $db->prepare('UPDATE mobile_civic_pins SET failed_count=0,lock_until=NULL WHERE user_id=?')->execute([$uid]);
   }
   $next=$decision==='return'?'perlu_perbaikan':
     ($r['status']==='menunggu_ketua'?'menunggu_bendahara':'selesai');
   $db->prepare('UPDATE mobile_civic_lpj SET status=? WHERE id=?')->execute([$next,$id]);
   $db->prepare('INSERT INTO mobile_civic_lpj_approvals(document_id,user_id,duty,action,notes) VALUES(?,?,?,?,?)')
     ->execute([$id,$uid,$role,$decision,$notes]);
   $db->commit();
  }catch(Throwable $e){if($db->inTransaction())$db->rollBack();throw $e;}
  mobile_emit('laporan_masuk','Status LPJ diperbarui','LPJ nomor '.$id.' sekarang '.$next,'personal',(string)$r['creator_id']);
  if($next==='menunggu_bendahara'){
   $target=cikoko_civic_next_officer((string)$r['kind'],(string)$r['rt'],(string)$r['rw'],$next,$uid);
   if($target)mobile_emit('laporan_masuk','LPJ menunggu Bendahara','LPJ nomor '.$id.' memerlukan keputusan.','personal',(string)$target['id']);
  }
  mobile_json(['ok'=>true,'id'=>$id,'status'=>$next]);
 }
 if($action==='civic_pdf'){
  if($method!=='GET')mobile_error('Metode tidak didukung.',405);
  $r=cikoko_civic_row($db,(int)($_GET['id']??0),$user,$scope);
  $q=$db->prepare('SELECT duty,action,notes,created_at FROM mobile_civic_lpj_approvals WHERE document_id=? ORDER BY id');
  $q->execute([(int)$r['id']]);
  require_once __DIR__.'/civic_pdf.php';
  cikoko_civic_output_pdf($r,$q->fetchAll(PDO::FETCH_ASSOC));
 }
 mobile_error('Endpoint LPJ tidak tersedia.',404);
}
