<?php
declare(strict_types=1);

// Chat availability is based on active AUTHENTICATED staff sessions, not a
// public "online" flag or an untrusted client-supplied user ID. A foreground
// app refreshes events every 3–30 seconds; a 90-second TTL tolerates latency.
function cikoko_chat_presence_session_hash():string {
 $header=(string)($_SERVER['HTTP_AUTHORIZATION']??$_SERVER['REDIRECT_HTTP_AUTHORIZATION']??'');
 return preg_match('/^Bearer\s+([A-Za-z0-9_-]{40,128})$/',$header,$m)?hash('sha256',$m[1]):'';
}
function cikoko_chat_eligible_staff(array $user):bool {
 $role=(string)($user['user_role']??'');
 return in_array($role,['admin','admin_kelurahan','asn'],true)
  && function_exists('mobile_can') && mobile_can($user,'chat:reply');
}
function cikoko_chat_presence(PDO $db,array $user,bool $online=true,?string $sessionHash=null):bool {
 $hash=$sessionHash??cikoko_chat_presence_session_hash();
 if(!preg_match('/^[0-9a-f]{64}$/',$hash))return false;
 if(!$online){
  $stmt=$db->prepare('DELETE FROM mobile_chat_presence WHERE session_hash=? AND user_id=?');
  $stmt->execute([$hash,(string)($user['user_id']??'')]);
  return true;
 }
 if(!cikoko_chat_eligible_staff($user))return false;
 $stmt=$db->prepare('INSERT INTO mobile_chat_presence(session_hash,user_id,user_role,last_seen_at) VALUES(?,?,?,NOW())
  ON DUPLICATE KEY UPDATE user_id=VALUES(user_id),user_role=VALUES(user_role),last_seen_at=NOW()');
 $stmt->execute([$hash,(string)$user['user_id'],(string)$user['user_role']]);
 // Low-rate opportunistic cleanup; no cron dependency.
 if(random_int(1,100)===1)$db->exec('DELETE FROM mobile_chat_presence WHERE last_seen_at<DATE_SUB(NOW(),INTERVAL 1 DAY) LIMIT 100');
 return true;
}
function cikoko_chat_any_staff_online(PDO $db):bool {
 $query=$db->query("SELECT 1 FROM mobile_chat_presence WHERE user_role IN ('admin','admin_kelurahan','asn')
  AND last_seen_at>=DATE_SUB(NOW(),INTERVAL 90 SECOND) LIMIT 1");
 return (bool)$query->fetchColumn();
}
/**
 * Insert at most one holding reply while a resident is awaiting a human
 * response. A new human staff reply re-arms the bot for the next offline
 * resident message. Row locking makes the decision safe for concurrent sends.
 *
 * Caller must have stored the resident message first and must not treat an
 * auto-reply failure as a failure of the resident's original message.
 */
function cikoko_chat_offline_ack(PDO $db,string $owner):?array {
 if($owner===''||cikoko_chat_any_staff_online($db))return null;
 $db->beginTransaction();
 try {
  $init=$db->prepare('INSERT IGNORE INTO mobile_chat_bot_state(user_id,last_bot_message_id) VALUES(?,0)');
  $init->execute([$owner]);
  $q=$db->prepare('SELECT last_bot_message_id FROM mobile_chat_bot_state WHERE user_id=? FOR UPDATE');
  $q->execute([$owner]);$lastBot=(int)$q->fetchColumn();
  // Recheck inside the lock: another app may just have come online.
  if(cikoko_chat_any_staff_online($db)){$db->commit();return null;}
  $q=$db->prepare('SELECT COALESCE(MAX(id),0) FROM mobile_chat WHERE user_id=? AND sender="admin"');
  $q->execute([$owner]);$lastHuman=(int)$q->fetchColumn();
  if($lastBot>0 && $lastHuman<=$lastBot){$db->commit();return null;}
  $text='🤖 Asisten Otomatis Cikoko: Pesan Anda telah diterima. Saat ini Admin Utama, Admin Kelurahan, dan ASN sedang tidak online. Mohon menunggu tanggapan dari petugas. Pesan Anda tersimpan dan akan dapat dibaca saat petugas kembali aktif.';
  $reply=cikoko_chat_store($db,$owner,'Asisten Otomatis Cikoko','bot',$text);
  $reply['message']=$text;
  $reply['name']='Asisten Otomatis Cikoko';
  $db->prepare('UPDATE mobile_chat_bot_state SET last_bot_message_id=? WHERE user_id=?')
     ->execute([(int)$reply['id'],$owner]);
  $db->commit();
  return $reply;
 }catch(Throwable $e){
  if($db->inTransaction())$db->rollBack();
  throw $e;
 }
}
