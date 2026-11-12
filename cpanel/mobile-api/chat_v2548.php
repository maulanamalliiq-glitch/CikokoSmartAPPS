<?php
declare(strict_types=1);
// Standalone chat API. Works alongside the deployed index.php without replacing it.
ini_set('display_errors','0');
header('Content-Type: application/json; charset=utf-8');
require __DIR__.'/bootstrap.php';
require __DIR__.'/permissions.php';
require_once __DIR__.'/chat_storage_2544.php';
$action=(string)($_GET['action']??'');
$method=(string)($_SERVER['REQUEST_METHOD']??'GET');
$user=mobile_auth();
$db=mobile_db();
$myId=(string)$user['user_id'];
$staff=mobile_can($user,'chat:reply');
$owner=$myId;
if($staff){
 // Target and photo-read endpoints are resolved by event/photo ID, not a supplied thread ID.
 if(in_array($action,['chat_v2548_target','chat_v2548_photo'],true)){
  $owner=$myId;
 }else{
  $owner=mobile_text(($method==='POST'?($_POST['user_id']??''):($_GET['user_id']??'')),80);
  if($action==='chat_v2548_send')$owner=mobile_text(mobile_body()['user_id']??'',80);
  if($owner==='')mobile_error('Pilih percakapan warga terlebih dahulu.',422);
 }
}
if(!$staff&&$owner!==$myId)mobile_error('Tidak diizinkan membaca percakapan lain.',403);
if(!preg_match('/^[A-Za-z0-9_-]{2,80}$/D',$owner))mobile_error('Akun percakapan tidak valid',422);
if($staff&&in_array($action,['chat_v2548_thread','chat_v2548_send','chat_v2548_upload'],true)){
 $check=$db->prepare('SELECT id FROM mobile_chat WHERE user_id=? LIMIT 1');
 $check->execute([$owner]);if(!$check->fetchColumn())mobile_error('Percakapan belum tersedia.',404);
}
$db->exec('CREATE TABLE IF NOT EXISTS mobile_chat_photos(
  message_id BIGINT UNSIGNED NOT NULL PRIMARY KEY,
  owner_id VARCHAR(80) NOT NULL,
  stored_name VARCHAR(100) NOT NULL,
  mime VARCHAR(40) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_owner(owner_id)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
$db->exec('CREATE TABLE IF NOT EXISTS mobile_event_chat_targets(
  event_id BIGINT UNSIGNED NOT NULL PRIMARY KEY,
  thread_user_id VARCHAR(80) NOT NULL,
  INDEX idx_thread(thread_user_id)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');

function cikoko_chat_v2548_notify(PDO $db,string $owner,bool $fromStaff):void {
 try{
  $targets=$fromStaff?[['audience'=>'personal','recipient'=>$owner]]:
    mobile_notification_recipients('chat','admin',null);
  $title=$fromStaff?'Pesan dari Petugas Kelurahan':'Pesan warga baru';
  $body=$fromStaff?'Balasan chat masuk. Ketuk untuk membuka percakapan.':
    'Pesan masuk untuk petugas. Ketuk untuk membuka percakapan.';
  $event=$db->prepare('INSERT INTO mobile_events
    (category,title,message,audience,recipient) VALUES("chat",?,?,"personal",?)');
  $link=$db->prepare('INSERT INTO mobile_event_chat_targets(event_id,thread_user_id)
    VALUES(?,?)');
  foreach($targets as $target){
   if(($target['audience']??'')!=='personal'||empty($target['recipient']))continue;
   $event->execute([$title,$body,(string)$target['recipient']]);
   $link->execute([(int)$db->lastInsertId(),$owner]);
  }
 }catch(Throwable $e){error_log('[Cikoko chat notification] '.$e->getMessage());}
}
if($action==='chat_v2548_thread'&&$method==='GET'){
 $data=cikoko_chat_page($db,$owner,$staff?'admin':'warga');
 $rows=$data['messages']??[];
 $ids=array_values(array_filter(array_map(static fn($r)=>(int)$r['id'],$rows)));
 $photos=[];
 if($ids){
  $q=$db->prepare('SELECT message_id,mime FROM mobile_chat_photos WHERE owner_id=?
    AND message_id IN ('.implode(',',array_fill(0,count($ids),'?')).')');
  $q->execute(array_merge([$owner],$ids));
  foreach($q->fetchAll(PDO::FETCH_ASSOC) as $photo)
   $photos[(string)$photo['message_id']]=(string)$photo['mime'];
 }
 foreach($rows as &$row){
  $id=(string)$row['id'];
  $row['has_photo']=isset($photos[$id]);
  $row['photo_id']=$row['has_photo']?(int)$id:null;
 }
 unset($row);
 $data['messages']=$rows;
 mobile_json($data);
}
if($action==='chat_v2548_target'&&$method==='GET'){
 $eventId=(int)($_GET['event_id']??0);
 if($eventId<1)mobile_error('Notifikasi tidak valid',422);
 $q=$db->prepare('SELECT t.thread_user_id FROM mobile_event_chat_targets t
  JOIN mobile_events e ON e.id=t.event_id
  WHERE t.event_id=? AND e.audience="personal" AND e.recipient=? AND e.category="chat"');
 $q->execute([$eventId,$myId]);
 $thread=(string)($q->fetchColumn()?:'');
 if(!$staff&&$thread!==''&&$thread!==$myId)mobile_error('Tidak diizinkan.',403);
 mobile_json(['ok'=>true,'thread_user_id'=>$thread,'is_staff'=>$staff]);
}
if($action==='chat_v2548_send'&&$method==='POST'){
 $body=mobile_body();
 if($staff)$owner=mobile_text($body['user_id']??'',80);
 $message=mobile_text($body['message']??'',2500);
 if(mobile_strlen($message)<1)mobile_error('Pesan tidak boleh kosong.',422);
 // Rate limiting prevents notification spam.
 cikoko_rate_limit($db,'chat_v2548_message',$myId,90,3600);
 $result=cikoko_chat_store($db,$owner,$staff?'Petugas Kelurahan':(string)$user['username'],
   $staff?'admin':'warga',$message);
 // Preserve the existing after-hours automatic acknowledgement for residents.
 if(!$staff&&is_file(__DIR__.'/chat_offline_bot_2545.php')){
  try{
   require_once __DIR__.'/chat_offline_bot_2545.php';
   $auto=cikoko_chat_offline_ack($db,$owner);
   if($auto!==null)$result['auto_reply']=$auto;
  }catch(Throwable $e){error_log('[Cikoko offline chat acknowledgement] '.$e->getMessage());}
 }
 cikoko_chat_v2548_notify($db,$owner,$staff);
 mobile_json($result);
}
if($action==='chat_v2548_upload'&&$method==='POST'){
 $caption=mobile_text($_POST['caption']??'',300);
 if(empty($_FILES['photo']))mobile_error('Pilih foto dahulu.',422);
 cikoko_rate_limit($db,'chat_v2548_photo',$myId,30,3600);
 // mobile_file validates MIME, prevents path traversal, uses a random filename.
 $filename=mobile_file('photo',true);
 $mime=(new finfo(FILEINFO_MIME_TYPE))->file(__DIR__.'/private/'.$filename);
 if(!in_array($mime,['image/jpeg','image/png','image/webp'],true)){
  @unlink(__DIR__.'/private/'.$filename);mobile_error('Format foto tidak didukung.',422);
 }
 try{
  $db->beginTransaction();
  $result=cikoko_chat_store($db,$owner,$staff?'Petugas Kelurahan':(string)$user['username'],
    $staff?'admin':'warga',$caption!==''?$caption:'📷 Foto');
  $id=(int)$result['id'];
  $q=$db->prepare('INSERT INTO mobile_chat_photos(message_id,owner_id,stored_name,mime)
      VALUES(?,?,?,?)');
  $q->execute([$id,$owner,$filename,$mime]);
  $db->commit();
  cikoko_chat_v2548_notify($db,$owner,$staff);
  mobile_json($result+['photo_id'=>$id,'has_photo'=>true]);
 }catch(Throwable $e){
  if($db->inTransaction())$db->rollBack();
  @unlink(__DIR__.'/private/'.$filename);
  error_log('[Cikoko chat upload] '.$e->getMessage());
  mobile_error('Foto belum dapat dikirim. Coba kembali.',503);
 }
}
if($action==='chat_v2548_photo'&&$method==='GET'){
 $id=(int)($_GET['id']??0);
 if($id<1)mobile_error('Foto tidak tersedia',404);
 $q=$db->prepare('SELECT p.owner_id,p.stored_name,p.mime FROM mobile_chat_photos p
     WHERE p.message_id=? LIMIT 1');
 $q->execute([$id]);$photo=$q->fetch(PDO::FETCH_ASSOC);
 if(!$photo)mobile_error('Foto tidak ditemukan',404);
 if(!$staff&&(string)$photo['owner_id']!==$myId)mobile_error('Tidak diizinkan',403);
 if(!preg_match('/^[a-f0-9]{40}\.(jpg|png|webp)$/D',(string)$photo['stored_name']))
   mobile_error('Format nama berkas tidak valid',404);
 $file=__DIR__.'/private/'.$photo['stored_name'];
 if(!is_file($file))mobile_error('Berkas tidak tersedia',404);
 header('Content-Type: '.$photo['mime']);
 header('Content-Length: '.filesize($file));
 header('Cache-Control: private, no-store, max-age=0');
 readfile($file);exit;
}
mobile_error('Aksi chat tidak tersedia.',404);
