<?php
declare(strict_types=1);
function cikoko_account_dispatch(string $action,string $method):void {
 $db=mobile_db();
 if($action==='account_help'){
  if($method!=='POST')mobile_error('Metode tidak diperbolehkan.',405);
  cikoko_rate_limit($db,'account_help',(string)($_SERVER['REMOTE_ADDR']??''),5,3600);
  $b=mobile_body();$username=mobile_text($b['username']??'',100);$contact=mobile_text($b['contact']??'',160);
  if($username===''||strlen($contact)<8)mobile_error('Isi nama pengguna dan kontak yang dapat dihubungi.',422);
  foreach(db_read('portal_users') as $user){
   if(strcasecmp((string)($user['username']??''),$username)!==0)continue;
   $kind=($b['kind']??'')==='deletion'?'deletion':'recovery';
   if(($user['role']??'')!=='warga')break;
   $pending=$db->prepare('SELECT id FROM mobile_account_requests WHERE user_id=? AND kind=? AND status="pending" LIMIT 1');$pending->execute([(string)$user['id'],$kind]);if($pending->fetchColumn())break;
   $q=$db->prepare('INSERT INTO mobile_account_requests(user_id,kind,contact,notes) VALUES(?,?,?,?)');
   $q->execute([(string)$user['id'],$kind,$contact,'Identitas dan kontak terdaftar wajib diverifikasi petugas sebelum tindakan.']);break;
  }
  // Never reveal whether a username exists or any registered contact.
  mobile_json(['ok'=>true,'message'=>'Permintaan telah diterima. Jika data sesuai, petugas akan memverifikasi melalui kontak terdaftar. Jangan berikan kata sandi atau PIN kepada siapa pun.']);
 }
 $actor=mobile_auth();
 if($action==='account_request'){
  if($method==='GET'){
   $q=$db->prepare('SELECT id,kind,status,created_at FROM mobile_account_requests WHERE user_id=? ORDER BY id DESC LIMIT 20');$q->execute([$actor['user_id']]);mobile_json(['ok'=>true,'items'=>$q->fetchAll()]);
  }
  if($method!=='POST')mobile_error('Metode tidak diperbolehkan.',405);
  $b=mobile_body();$password=(string)($b['password']??'');$owner=null;
  foreach(db_read('portal_users') as $user)if((string)($user['id']??'')===(string)$actor['user_id']){$owner=$user;break;}
  if(!$owner||($owner['role']??'')!=='warga')mobile_error('Penghapusan akun petugas dilakukan melalui pengelola kelurahan.',403);
  cikoko_rate_limit($db,'account_confirmation',(string)$actor['user_id'],5,900);
  if(!password_verify($password,(string)($owner['password_hash']??'')))mobile_error('Konfirmasi kata sandi tidak sesuai.',422);
  $q=$db->prepare('SELECT id FROM mobile_account_requests WHERE user_id=? AND kind="deletion" AND status="pending"');$q->execute([$actor['user_id']]);$id=$q->fetchColumn();
  if(!$id){$q=$db->prepare('INSERT INTO mobile_account_requests(user_id,kind,contact,notes) VALUES(?,"deletion",?,?)');$q->execute([$actor['user_id'],(string)($owner['email']??$owner['phone']??''),'Pengguna meminta penghapusan akun dan data nonarsip. Dokumen pelayanan resmi harus ditinjau menurut ketentuan retensi pengelola.']);$id=$db->lastInsertId();}
  mobile_json(['ok'=>true,'id'=>(int)$id,'message'=>'Permintaan penghapusan akun diterima. Petugas akan memverifikasi permintaan dan menjelaskan penanganan arsip pelayanan.']);
 }
 if(($actor['user_role']??'')!=='admin')mobile_error('Hanya Admin Utama yang dapat mengelola bantuan akun.',403);
 if($action==='account_requests'&&$method==='GET'){
  $before=max(0,(int)($_GET['before_id']??0));$q=$db->prepare('SELECT id,user_id,kind,contact,notes,status,created_at FROM mobile_account_requests WHERE status="pending" AND (?=0 OR id<?) ORDER BY id DESC LIMIT 51');$q->execute([$before,$before]);$rows=$q->fetchAll();$more=count($rows)>50;$accounts=[];foreach(db_read('portal_users') as $user)$accounts[(string)($user['id']??'')]=$user;foreach($rows as &$row){$owner=$accounts[(string)$row['user_id']]??[];$row['username']=(string)($owner['username']??'');$row['registered_contact']=(string)($owner['phone']??'').' / '.(string)($owner['email']??'');}unset($row);mobile_json(['ok'=>true,'items'=>array_slice($rows,0,50),'has_more'=>$more]);
 }
 if($action==='account_request_resolve'&&$method==='POST'){
  $b=mobile_body();$id=(int)($b['id']??0);$q=$db->prepare('SELECT * FROM mobile_account_requests WHERE id=? AND status="pending"');$q->execute([$id]);$request=$q->fetch();if(!$request)mobile_error('Permintaan tidak tersedia.',404);
  if(($b['verified']??false)!==true)mobile_error('Verifikasi identitas melalui kontak terdaftar wajib diselesaikan terlebih dahulu.',422);
  cikoko_rate_limit($db,'account_resolve',(string)$actor['user_id'],5,900);
  $admin=db_read('admin');if(!password_verify((string)($b['admin_password']??''),(string)($admin['password_hash']??'')))mobile_error('Konfirmasi kata sandi petugas tidak sesuai.',422);
  $newPassword=(string)($b['new_password']??'');
  if($request['kind']==='recovery'&&!cikoko_password_valid($newPassword))mobile_error('Kata sandi baru minimal 10 karakter dengan huruf dan angka.',422);
  // Serialize account updates with the same lock used by account management.
  $fp=fopen(data_path('portal_users'),'c+');if(!$fp||!flock($fp,LOCK_EX))mobile_error('Penyimpanan akun sedang digunakan.',503);
  $original=null;$changed=false;
  try{
   $original=stream_get_contents($fp);$users=json_decode($original?:'[]',true,512,JSON_THROW_ON_ERROR);$remaining=[];$found=false;
   foreach($users as $user){
    if((string)($user['id']??'')!==(string)$request['user_id']){$remaining[]=$user;continue;}
    if(($user['role']??'')!=='warga')mobile_error('Bantuan akun ini hanya berlaku untuk akun warga.',403);
    $found=true;$deletedPhoto=(string)($user['photo_name']??'');if($request['kind']==='recovery'){$user['password_hash']=password_hash($newPassword,PASSWORD_DEFAULT);$remaining[]=$user;}
   }
   if(!$found)mobile_error('Akun tidak ditemukan. Periksa permintaan ini secara manual.',404);
   $db->beginTransaction();
   foreach(['mobile_tokens','mobile_devices'] as $table){$q=$db->prepare('DELETE FROM '.$table.' WHERE user_id=?');$q->execute([$request['user_id']]);}
   if($request['kind']==='deletion'){
    foreach(['mobile_chat','mobile_event_reads','mobile_event_deletes'] as $table){$q=$db->prepare('DELETE FROM '.$table.' WHERE user_id=?');$q->execute([$request['user_id']]);}
    $exists=$db->query("SHOW TABLES LIKE 'mobile_news_comments'")->fetchColumn();if($exists){$q=$db->prepare('DELETE FROM mobile_news_comments WHERE user_id=?');$q->execute([$request['user_id']]);}
    $q=$db->prepare('DELETE FROM mobile_events WHERE audience="personal" AND recipient=?');$q->execute([$request['user_id']]);
   }
   $q=$db->prepare('UPDATE mobile_account_requests SET status="completed",contact="",notes="",actor_id=?,closed_at=NOW() WHERE '.($request['kind']==='deletion'?'user_id=?':'id=?').' AND status="pending"');$q->execute([$actor['user_id'],$request['kind']==='deletion'?$request['user_id']:$id]);
   $payload=json_encode($remaining,JSON_UNESCAPED_UNICODE|JSON_PRETTY_PRINT|JSON_THROW_ON_ERROR);rewind($fp);$changed=true;
   if(!ftruncate($fp,0)||fwrite($fp,$payload)!==strlen($payload)||!fflush($fp))throw new RuntimeException('Account write failed');
   try{$db->commit();}catch(Throwable $e){rewind($fp);ftruncate($fp,0);fwrite($fp,$original);fflush($fp);throw $e;}
  }catch(Throwable $e){if($db->inTransaction())$db->rollBack();if($changed&&is_string($original)){rewind($fp);ftruncate($fp,0);fwrite($fp,$original);fflush($fp);}throw $e;}finally{flock($fp,LOCK_UN);fclose($fp);}
  if($request['kind']==='deletion'&&!empty($deletedPhoto)&&preg_match('/^[a-f0-9]{40}\.(jpg|png|webp)$/D',$deletedPhoto))@unlink(__DIR__.'/private/'.$deletedPhoto);
  mobile_json(['ok'=>true,'message'=>$request['kind']==='recovery'?'Kata sandi telah diperbarui dan sesi lama dicabut. Sampaikan melalui kontak yang telah diverifikasi.':'Akun dan data komunikasi telah dihapus. Arsip pelayanan resmi tetap memerlukan penanganan sesuai ketentuan retensi pengelola.']);
 }
 mobile_error('Metode tidak diperbolehkan.',405);
}
