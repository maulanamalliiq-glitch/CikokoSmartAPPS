<?php
/** PHP CLI cron every minute. Service-account JSON MUST be outside public_html.
 * cPanel command: /usr/local/bin/php /home/USER/public_html/mobile-api/cron_dispatch.php
 * Environment: CIKOKO_FIREBASE_SA=/home/USER/private/firebase-service-account.json
 */
if(PHP_SAPI!=='cli'){http_response_code(403);exit('Forbidden');}
require __DIR__.'/bootstrap.php';
require_once __DIR__.'/admin_push_center.php';
require_once __DIR__.'/website_legacy_broadcast.php';
cikoko_push_health_mark(mobile_db(),'starting');
// Deliver legacy website publications to in-app inboxes even before FCM setup.
cikoko_distribute_legacy_website_events(mobile_db());
function oauth_token(string $path):?string {
 $sa=json_decode(file_get_contents($path),true);
 if(!is_array($sa)||empty($sa['client_email'])||empty($sa['private_key']))return null;
 $now=time();$urlsafe=fn(string $v):string=>rtrim(strtr(base64_encode($v),'+/','-_'),'=');
 $header=$urlsafe(json_encode(['alg'=>'RS256','typ'=>'JWT']));
 $body=$urlsafe(json_encode(['iss'=>$sa['client_email'],'scope'=>'https://www.googleapis.com/auth/firebase.messaging','aud'=>'https://oauth2.googleapis.com/token','iat'=>$now,'exp'=>$now+3500]));
 $data=$header.'.'.$body;$signature='';
 if(!openssl_sign($data,$signature,$sa['private_key'],OPENSSL_ALGO_SHA256))return null;
 $jwt=$data.'.'.$urlsafe($signature);
 $ch=curl_init('https://oauth2.googleapis.com/token');curl_setopt_array($ch,[CURLOPT_POST=>true,CURLOPT_POSTFIELDS=>http_build_query(['grant_type'=>'urn:ietf:params:oauth:grant-type:jwt-bearer','assertion'=>$jwt]),CURLOPT_RETURNTRANSFER=>true,CURLOPT_TIMEOUT=>20]);$response=curl_exec($ch);$status=curl_getinfo($ch,CURLINFO_HTTP_CODE);curl_close($ch);
 $json=json_decode((string)$response,true);return $status===200?($json['access_token']??null):null;
}
function send_fcm(string $project,string $oauth,string $to,array $event):bool {
 $payload=['message'=>['token'=>$to,'notification'=>['title'=>$event['title'],'body'=>$event['message']],'data'=>['category'=>$event['category'],'event_id'=>(string)$event['id'],'account_id'=>(string)$event['recipient']],'android'=>['priority'=>'high','notification'=>['channel_id'=>'cikoko_updates_v2']]]];
 $ch=curl_init('https://fcm.googleapis.com/v1/projects/'.rawurlencode($project).'/messages:send');curl_setopt_array($ch,[CURLOPT_POST=>true,CURLOPT_POSTFIELDS=>json_encode($payload,JSON_UNESCAPED_UNICODE),CURLOPT_HTTPHEADER=>['Authorization: Bearer '.$oauth,'Content-Type: application/json'],CURLOPT_RETURNTRANSFER=>true,CURLOPT_TIMEOUT=>15]);$response=curl_exec($ch);$status=curl_getinfo($ch,CURLINFO_HTTP_CODE);curl_close($ch);if($status!==200)error_log('Cikoko FCM delivery HTTP '.$status.' '.substr((string)$response,0,400));return $status===200;
}
// cPanel Cron Jobs do not always inherit custom environment variables.
// Search only outside public_html; never place credentials in this repository.
$sa=getenv('CIKOKO_FIREBASE_SA')?:'';
if($sa===''){
  $default=dirname(__DIR__,2).'/private/firebase-service-account.json';
  if(is_readable($default))$sa=$default;
}
if($sa===''||!is_readable($sa)){
  cikoko_push_health_mark(mobile_db(),'fcm_key_missing');
  fwrite(STDERR,"FCM inactive: set CIKOKO_FIREBASE_SA or store service account in private/firebase-service-account.json outside public_html\n");
  exit(2);
}
$cfg=json_decode(file_get_contents($sa),true);$project=$cfg['project_id']??'';$oauth=oauth_token($sa);
if(!$oauth||!$project){
  cikoko_push_health_mark(mobile_db(),'fcm_auth_failed');
  fwrite(STDERR,"FCM authorization failed\n");
  exit(3);
}
$db=mobile_db();$events=$db->query('SELECT * FROM mobile_events WHERE dispatched_at IS NULL ORDER BY id LIMIT 20')->fetchAll();$ok=0;$fail=0;$accepted=0;$withoutDevices=0;
foreach($events as $e){
 // Push must have one explicit recipient. Global activity belongs in Beranda,
 // not in private notifications or OS push banners.
 if(($e['audience']??'')!=='personal'||trim((string)($e['recipient']??''))===''){
  $db->prepare('UPDATE mobile_events SET dispatched_at=NOW() WHERE id=?')->execute([(int)$e['id']]);
  $ok++;
  continue;
 }
 $sql='SELECT user_id,fcm_token FROM mobile_devices WHERE user_id=?';
 $params=[(string)$e['recipient']];
 $q=$db->prepare($sql);$q->execute($params);$devices=$q->fetchAll(PDO::FETCH_ASSOC);$sent=true;$eligible=0;
 $seen=[];$read=$db->prepare('SELECT 1 FROM mobile_event_reads WHERE user_id=? AND event_id=? LIMIT 1');
 foreach($devices as $device){
   $userId=(string)$device['user_id'];$token=(string)$device['fcm_token'];
   if($token===''||isset($seen[$token]))continue;
   $seen[$token]=true;
   $eligible++;
   $read->execute([$userId,(int)$e['id']]);
   if($read->fetchColumn())continue; // Already read: do not play a late push notification.
   if(send_fcm($project,$oauth,$token,$e))$accepted++;else $sent=false;
 }
 if($eligible===0)$withoutDevices++;
 if($sent){$db->prepare('UPDATE mobile_events SET dispatched_at=NOW() WHERE id=?')->execute([$e['id']]);$ok++;}else{$fail++;}
}
$state=$fail>0?'partial_failure':($withoutDevices>0&&$accepted===0?'no_devices':'ok');
cikoko_push_health_mark($db,$state,$ok+$fail,$accepted,$fail,$withoutDevices);
echo "Events processed: $ok; FCM accepted: $accepted; without device: $withoutDevices; need retry: $fail\n";
