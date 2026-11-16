<?php
declare(strict_types=1);
// Isolated runtime checks. Never connects to production or prints private data.
require __DIR__.'/../cpanel/mobile-api/chat_runtime_2566.php';
function mobile_can(array $u,string $cap):bool {
 return $cap==='chat:reply' && ($u['role']??'')==='admin';
}
function mobile_error(string $text,int $status):void {
 throw new RuntimeException('HTTP '.$status);
}
function ck(bool $ok,string $label):void{
 if(!$ok)throw new RuntimeException('FAIL '.$label);
 echo 'PASS '.$label."\n";
}
if(!in_array('sqlite',PDO::getAvailableDrivers(),true)){
 echo "SKIP SQLite runtime checks; php -l always required.\n";
 exit(0);
}
$db=new PDO('sqlite::memory:');
$db->setAttribute(PDO::ATTR_ERRMODE,PDO::ERRMODE_EXCEPTION);
$db->exec('CREATE TABLE mobile_chat (id INTEGER PRIMARY KEY AUTOINCREMENT,user_id TEXT)');
$db->exec('CREATE TABLE mobile_chat_receipts (user_id TEXT)');
$db->exec('CREATE TABLE mobile_events (id INTEGER)');
$db->exec('CREATE TABLE mobile_devices (user_id TEXT,fcm_token TEXT)');
ck(cikoko_chat_runtime_2566_table($db,'mobile_chat'),'Existing chat table detected');
ck(!cikoko_chat_runtime_2566_table($db,'missing_chat'),
 'Missing table detected without altering database');
ck(!cikoko_chat_runtime_2566_table($db,'mobile_chat;DROP TABLE mobile_chat'),
 'Unsafe table names rejected');
ck(cikoko_chat_runtime_2566_ensure($db,'mobile_events','UNSAFE SHOULD NOT RUN'),
 'Existing table causes no DDL even with invalid create statement');
$admin=['user_id'=>'admin','role'=>'admin'];
$diag=cikoko_chat_runtime_2566_health($db,$admin);
ck($diag['tables']['mobile_chat']===true,'Admin health reports existing chat table');
ck($diag['tables']['mobile_chat_photos']===false,'Missing photo table reported without faking readiness');
ck($diag['chat_api_version']==='2566','Version matches deployed diagnostic contract');
ck(!array_key_exists('message',$diag)&&!array_key_exists('token',$diag),
 'Health does not disclose message bodies or credentials');
try{
 cikoko_chat_runtime_2566_health($db,['user_id'=>'warga','role'=>'warga']);
 throw new RuntimeException('Unauthorized viewer accepted');
}catch(RuntimeException $e){
 ck($e->getMessage()==='HTTP 403','Resident cannot query admin infrastructure status');
}
echo "CHAT SERVER RUNTIME 2566 TESTS PASSED\n";
