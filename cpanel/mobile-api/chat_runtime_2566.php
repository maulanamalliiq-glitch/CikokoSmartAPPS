<?php
declare(strict_types=1);

/**
 * Chat runtime diagnostics. Never return SQL, credentials or message text.
 * Only chat:reply-authorized personnel may call this action.
 */
function cikoko_chat_runtime_2566_table(PDO $db,string $table):bool {
 if(!preg_match('/^[a-z_]+$/D',$table))return false;
 try {
  $db->query('SELECT 1 FROM `'.$table.'` LIMIT 0');
  return true;
 }catch(Throwable $e){
  error_log('[Cikoko chat health] '.$table.': '.$e->getMessage());
  return false;
 }
}

function cikoko_chat_runtime_2566_ensure(PDO $db,string $name,string $ddl):bool {
 if(cikoko_chat_runtime_2566_table($db,$name))return true;
 try{
  $db->exec($ddl);
  return cikoko_chat_runtime_2566_table($db,$name);
 }catch(Throwable $e){
  error_log('[Cikoko chat schema] '.$name.': '.$e->getMessage());
  return false;
 }
}
function cikoko_chat_runtime_2566_photo(PDO $db):bool {
 return cikoko_chat_runtime_2566_ensure($db,'mobile_chat_photos',
  'CREATE TABLE IF NOT EXISTS mobile_chat_photos(
   message_id BIGINT UNSIGNED NOT NULL PRIMARY KEY,
   owner_id VARCHAR(80) NOT NULL,
   stored_name VARCHAR(100) NOT NULL,
   mime VARCHAR(40) NOT NULL,
   created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
   INDEX idx_owner(owner_id)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
}
function cikoko_chat_runtime_2566_event_targets(PDO $db):bool {
 return cikoko_chat_runtime_2566_ensure($db,'mobile_event_chat_targets',
  'CREATE TABLE IF NOT EXISTS mobile_event_chat_targets(
   event_id BIGINT UNSIGNED NOT NULL PRIMARY KEY,
   thread_user_id VARCHAR(80) NOT NULL,
   INDEX idx_thread(thread_user_id)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
}
function cikoko_chat_runtime_2566_health(PDO $db,array $actor):array {
 if(!mobile_can($actor,'chat:reply'))mobile_error('Hak akses ditolak.',403);
 $tables=['mobile_chat','mobile_chat_receipts','mobile_chat_photos',
          'mobile_events','mobile_event_chat_targets','mobile_devices'];
 $checks=[];
 foreach($tables as $t)$checks[$t]=cikoko_chat_runtime_2566_table($db,$t);
 $autoId=false;
 if($checks['mobile_chat']){
  try{
   // CREATE IF NOT EXISTS cannot repair a preexisting table with an invalid ID.
   $row=$db->query("SHOW COLUMNS FROM mobile_chat LIKE 'id'")->fetch(PDO::FETCH_ASSOC);
   $autoId=!!$row && strtoupper((string)($row['Key']??''))==='PRI'
     && stripos((string)($row['Extra']??''),'auto_increment')!==false;
  }catch(Throwable $e){error_log('[Cikoko chat health] id: '.$e->getMessage());}
 }
 $devices=0;
 if($checks['mobile_devices']){
  try{
   $q=$db->prepare('SELECT COUNT(*) FROM mobile_devices WHERE user_id=? AND fcm_token<>""');
   $q->execute([(string)$actor['user_id']]);
   $devices=(int)$q->fetchColumn();
  }catch(Throwable $e){error_log('[Cikoko chat health] devices: '.$e->getMessage());}
 }
 $cron='unknown';
 try{
  if(cikoko_chat_runtime_2566_table($db,'mobile_push_dispatch_health')){
   $row=$db->query('SELECT last_run_at,status FROM mobile_push_dispatch_health WHERE id=1')->fetch(PDO::FETCH_ASSOC);
   if($row){
    $last=strtotime((string)($row['last_run_at']??''))?:0;
    $cron=$last>0&&(time()-$last)<=300 ? (string)($row['status']??'unknown'):'not_recent';
   }else $cron='not_run';
  }else $cron='not_configured';
 }catch(Throwable $e){error_log('[Cikoko chat health] push: '.$e->getMessage());}
 return [
  'ok'=>true,'chat_api_version'=>'2566',
  'tables'=>$checks,'chat_id_auto_increment'=>$autoId,
  'own_fcm_device_tokens'=>$devices,'push_cron_status'=>$cron,
  'server_time'=>gmdate('Y-m-d\TH:i:s\Z')
 ];
}
