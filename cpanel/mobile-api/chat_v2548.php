<?php
declare(strict_types=1);
// Standalone chat API. Works alongside the deployed index.php without replacing it.
ini_set('display_errors','0');
header('Content-Type: application/json; charset=utf-8');
require __DIR__.'/bootstrap.php';
require __DIR__.'/permissions.php';
require_once __DIR__.'/chat_storage_2544.php';
require_once __DIR__.'/chat_runtime_2566.php';
$action=(string)($_GET['action']??'');
$method=(string)($_SERVER['REQUEST_METHOD']??'GET');
if($action==='chat_v2548_status'){
 if($method!=='GET')mobile_error('Metode tidak didukung.',405);
 mobile_json(['ok'=>true,'chat_api_version'=>'2566']);
}
$user=mobile_auth();
$db=mobile_db();
$myId=(string)$user['user_id'];
$staff=mobile_can($user,'chat:reply');
$owner=$myId;
if($staff){
 // Target and photo-read endpoints are resolved by event/photo ID, not a supplied thread ID.
 if(in_array($action,['chat_v2548_target','chat_v2548_photo','chat_v2548_threads'],true)){
  $owner=$myId;
 }else{
  $owner=mobile_text(($method==='POST'?($_POST['user_id']??''):($_GET['user_id']??'')),80);
  if($action==='chat_v2548_send')$owner=mobile_text(mobile_body()['user_id']??'',80);
  if($owner==='')mobile_error('Pilih percakapan warga terlebih dahulu.',422);
 }
}
if(!$staff&&$owner!==$myId)mobile_error('Tidak diizinkan membaca percakapan lain.',403);
if(!preg_match('/^[A-Za-z0-9_-]{2,80}$/D',$owner))mobile_error('Akun percakapan tidak valid',422);
// Only staff with chat:reply may address another account.
// Existing mobile_chat threads are valid, but for newly created threads the
// target must be a real, active portal account. This is essential for photo
// uploads: the previous guard rejected staff photos with a stale false 404,
// even if the resident was visible in the canonical inbox.
require_once __DIR__.'/chat_hardcheck_2565.php';
if($staff&&in_array($action,['chat_v2548_send','chat_v2548_upload'],true)){
 if(!cikoko_chat_v2565_known_target($db,$owner)){
  mobile_error('Akun tujuan percakapan tidak ditemukan. Segarkan inbox.',404);
 }
}
// Avoid DDL on routine chat requests; use explicit staff diagnostics.
if($action==='chat_v2548_diagnostic'){
 if($method!=='GET')mobile_error('Metode tidak didukung.',405);
 mobile_json(cikoko_chat_runtime_2566_health($db,$user));
}

// Admin inbox uses the SAME authenticated database as thread messages.
// Do not return an individual message for each row or combine distinct users.
if($action==='chat_v2548_threads'){
 if($method!=='GET')mobile_error('Metode tidak didukung.',405);
 if(!$staff)mobile_error('Tidak diizinkan membaca pesan warga.',403);
 require_once __DIR__.'/chat_inbox_2563.php';
 mobile_json(cikoko_chat_inbox_2563($db));
}

function cikoko_chat_v2548_notify(PDO $db,string $owner,bool $fromStaff):void {
 try{
  // Never let notification schema failure invalidate a persisted message.
  $hasTargets=cikoko_chat_runtime_2566_event_targets($db);
  $targets=$fromStaff?[['audience'=>'personal','recipient'=>$owner]]:
    mobile_notification_recipients('chat','admin',null);
  $title=$fromStaff?'Pesan dari Petugas Kelurahan':'Pesan warga baru';
  $body=$fromStaff?'Balasan chat masuk. Ketuk untuk membuka percakapan.':
    'Pesan masuk untuk petugas. Ketuk untuk membuka percakapan.';
  $event=$db->prepare('INSERT INTO mobile_events
    (category,title,message,audience,recipient) VALUES("chat",?,?,"personal",?)');
  $link=$hasTargets?$db->prepare('INSERT INTO mobile_event_chat_targets(event_id,thread_user_id)
    VALUES(?,?)'):null;
  foreach($targets as $target){
   if(($target['audience']??'')!=='personal'||empty($target['recipient']))continue;
   $event->execute([$title,$body,(string)$target['recipient']]);
   if($link!==null)$link->execute([(int)$db->lastInsertId(),$owner]);
  }
 }catch(Throwable $e){error_log('[Cikoko chat notification] '.$e->getMessage());}
}
if($action==='chat_v2548_thread'&&$method==='GET'){
 // Optional last_id links the selected inbox row to a concrete DB message.
 // Both selectors must resolve to the same owner; never cross user boundaries.
 if($staff){
  $lastId=max(0,(int)($_GET['last_id']??0));
  if($lastId>0){
   $verify=$db->prepare('SELECT user_id FROM mobile_chat WHERE id=? LIMIT 1');
   $verify->execute([$lastId]);
   $resolved=(string)($verify->fetchColumn()?:'');
   if($resolved!==''&&!hash_equals($resolved,$owner))
    mobile_error('ID percakapan tidak sesuai. Segarkan inbox.',409);
  }
 }
 $data=cikoko_chat_page($db,$owner,$staff?'admin':'warga');
 $rows=$data['messages']??[];
 $ids=array_values(array_filter(array_map(static fn($r)=>(int)$r['id'],$rows)));
 $photos=[];
 if($ids && cikoko_chat_runtime_2566_table($db,'mobile_chat_photos')){
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
 // The stable ID lets Flutter check that inbox and thread refer to the
 // same authorized conversation, independent of the display name.
 $data['thread_user_id']=$owner;
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
 try{
  mobile_require_auto_id($db,['mobile_chat']);
  $result=cikoko_chat_store($db,$owner,$staff?'Petugas Kelurahan':(string)$user['username'],
   $staff?'admin':'warga',$message);
 }catch(Throwable $e){
  $trace=bin2hex(random_bytes(4));
  error_log('[Cikoko CHAT_STORE '.$trace.'] '.$e->getMessage());
  mobile_error('Server chat belum dapat menyimpan pesan. Kode: CHAT_STORE_'.$trace,503);
 }
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
 if(!cikoko_chat_runtime_2566_photo($db))
  mobile_error('Penyimpanan foto chat belum siap (CHAT_PHOTO_SCHEMA).',503);
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
  mobile_error('Server belum berhasil menyimpan foto (CHAT_PHOTO_WRITE).',503);
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
