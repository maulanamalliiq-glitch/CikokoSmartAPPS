<?php
/** PHP CLI cron every minute. Service-account JSON MUST be outside public_html.
 * cPanel command: /usr/local/bin/php /home/USER/public_html/mobile-api/cron_dispatch.php
 * Environment: CIKOKO_FIREBASE_SA=/home/USER/private/firebase-service-account.json
 */
if(PHP_SAPI!=='cli'){http_response_code(403);exit('Forbidden');}
require __DIR__.'/bootstrap.php';
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
 $payload=['message'=>['token'=>$to,'notification'=>['title'=>$event['title'],'body'=>$event['message']],'data'=>['category'=>$event['category'],'event_id'=>(string)$event['id']],'android'=>['priority'=>'high','notification'=>['channel_id'=>'cikoko_updates_v2']]]];
 $ch=curl_init('https://fcm.googleapis.com/v1/projects/'.rawurlencode($project).'/messages:send');curl_setopt_array($ch,[CURLOPT_POST=>true,CURLOPT_POSTFIELDS=>json_encode($payload,JSON_UNESCAPED_UNICODE),CURLOPT_HTTPHEADER=>['Authorization: Bearer '.$oauth,'Content-Type: application/json'],CURLOPT_RETURNTRANSFER=>true,CURLOPT_TIMEOUT=>15]);$response=curl_exec($ch);$status=curl_getinfo($ch,CURLINFO_HTTP_CODE);curl_close($ch);if($status!==200)error_log('Cikoko FCM delivery HTTP '.$status.' '.substr((string)$response,0,400));return $status===200;
}
$sa=getenv('CIKOKO_FIREBASE_SA')?:'';
if($sa===''||!is_file($sa)){fwrite(STDERR,"FCM inactive: supply private service account via CIKOKO_FIREBASE_SA\n");exit(2);}
$cfg=json_decode(file_get_contents($sa),true);$project=$cfg['project_id']??'';$oauth=oauth_token($sa);
if(!$oauth||!$project){fwrite(STDERR,"FCM authorization failed\n");exit(3);}
$db=mobile_db();$events=$db->query('SELECT * FROM mobile_events WHERE dispatched_at IS NULL ORDER BY id LIMIT 20')->fetchAll();$ok=0;$fail=0;
foreach($events as $e){
 $sql='SELECT fcm_token FROM mobile_devices';$params=[];
 if($e['audience']==='personal'){$sql.=' WHERE user_id=?';$params=[$e['recipient']];}
 if($e['audience']==='admin'){$sql.=' WHERE user_id="admin" OR user_id IN (SELECT user_id FROM mobile_tokens WHERE user_role="admin_kelurahan" AND expires_at>NOW())';}
 if($e['audience']==='staff'){$sql.=' WHERE user_id="admin" OR user_id IN (SELECT user_id FROM mobile_tokens WHERE user_role<>"warga" AND expires_at>NOW())';}
 $sql=str_replace('SELECT fcm_token','SELECT user_id,fcm_token',$sql);
 $q=$db->prepare($sql);$q->execute($params);$devices=$q->fetchAll(PDO::FETCH_ASSOC);$sent=true;
 $seen=[];$read=$db->prepare('SELECT 1 FROM mobile_event_reads WHERE user_id=? AND event_id=? LIMIT 1');
 foreach($devices as $device){
   $userId=(string)$device['user_id'];$token=(string)$device['fcm_token'];
   if($token===''||isset($seen[$token]))continue;
   $seen[$token]=true;
   $read->execute([$userId,(int)$e['id']]);
   if($read->fetchColumn())continue; // Already read: do not play a late push notification.
   if(!send_fcm($project,$oauth,$token,$e))$sent=false;
 }
 if($sent){$db->prepare('UPDATE mobile_events SET dispatched_at=NOW() WHERE id=?')->execute([$e['id']]);$ok++;}else{$fail++;}
}
echo "Events dispatched: $ok; need retry: $fail\n";
