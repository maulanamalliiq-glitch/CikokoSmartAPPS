<?php
declare(strict_types=1);

/**
 * Write and read back a chat message using the same authenticated PDO
 * connection. Do not return a success response if the message has not been
 * persisted for the expected conversation.
 */
function cikoko_chat_store(PDO $db,string $owner,string $name,string $sender,string $message):array {
 if($owner===''||strlen($owner)>80||!in_array($sender,['warga','admin'],true)||trim($message)===''){
  mobile_error('Penerima atau isi pesan tidak valid.',422);
 }
 $stmt=$db->prepare('INSERT INTO mobile_chat(user_id,name,sender,message) VALUES(?,?,?,?)');
 $stmt->execute([$owner,$name,$sender,$message]);
 $messageId=(int)$db->lastInsertId();
 if($messageId<1)throw new RuntimeException('Chat insert returned no ID.');
 $check=$db->prepare('SELECT id,user_id,sender,message,created_at FROM mobile_chat WHERE id=? AND user_id=? LIMIT 1');
 $check->execute([$messageId,$owner]);
 $row=$check->fetch(PDO::FETCH_ASSOC);
 if(!$row||(string)($row['user_id']??'')!==$owner||
  (string)($row['sender']??'')!==$sender||
  (string)($row['message']??'')!==$message){
  throw new RuntimeException('Chat read-after-write failed.');
 }
 return ['ok'=>true,'id'=>$messageId,'sender'=>$sender,
  'created_at'=>(string)$row['created_at'],'delivery_status'=>'sent',
  'thread_user_id'=>$owner,'stored'=>true];
}

/** Safe, message-free diagnostics scoped to the currently authenticated user
 * or an officer with explicit chat:reply permission. No message bodies returned.
 */
function cikoko_chat_diagnostic(PDO $db,array $actor,string $requestedOwner):array {
 $own=(string)($actor['user_id']??'');
 $canReadOther=function_exists('mobile_can') && mobile_can($actor,'chat:reply');
 $owner=$requestedOwner!==''?$requestedOwner:$own;
 if($owner===''||strlen($owner)>80)mobile_error('Percakapan tidak valid.',422);
 if($owner!==$own&&!$canReadOther)mobile_error('Tidak diizinkan.',403);
 $q=$db->prepare('SELECT COUNT(*) AS total, MAX(id) AS last_id,MAX(created_at) AS latest_at FROM mobile_chat WHERE user_id=?');
 $q->execute([$owner]);$row=$q->fetch(PDO::FETCH_ASSOC)?:[];
 $sent=$db->prepare('SELECT COUNT(*) FROM mobile_chat WHERE user_id=? AND sender=?');
 $sent->execute([$owner,'warga']);$wargaCount=(int)$sent->fetchColumn();
 $sent->execute([$owner,'admin']);$adminCount=(int)$sent->fetchColumn();
 return ['ok'=>true,'thread_user_id'=>$owner,'storage'=>'mobile_chat',
  'total'=>(int)($row['total']??0),'last_id'=>(int)($row['last_id']??0),
  'latest_at'=>(string)($row['latest_at']??''),
  'warga_count'=>$wargaCount,'admin_count'=>$adminCount,
  'server_time'=>gmdate('Y-m-d\TH:i:s\Z')];
}
