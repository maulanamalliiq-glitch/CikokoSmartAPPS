<?php
declare(strict_types=1);
$dsn=(string)getenv('TEST_MYSQL_DSN');
if($dsn===''||!str_contains($dsn,'dbname=cikoko_test'))throw new RuntimeException('Only isolated cikoko_test is allowed.');
function mobile_error(string $message,int $code=400):void{throw new RuntimeException($message,$code);}
function mobile_strlen(string $v):int{return strlen($v);}
function mobile_can(array $user,string $permission):bool{
 return $permission==='chat:reply' && empty($user['deny']) &&
  in_array($user['user_role']??'',['admin','admin_kelurahan','asn'],true);
}
function ensure(bool $value,string $why):void{
 if(!$value)throw new RuntimeException('FAIL: '.$why);
 echo "PASS: ".$why."\n";
}
require __DIR__.'/../cpanel/mobile-api/release_core.php';
require __DIR__.'/../cpanel/mobile-api/chat_storage_2544.php';
require __DIR__.'/../cpanel/mobile-api/chat_offline_bot_2545.php';
$db=new PDO($dsn,(string)getenv('TEST_MYSQL_USER'),(string)getenv('TEST_MYSQL_PASSWORD'),[
 PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION,
 PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC,
 PDO::ATTR_EMULATE_PREPARES=>false]);
cikoko_release_schema($db);
$db->exec('DROP TABLE IF EXISTS mobile_chat');
$db->exec('CREATE TABLE mobile_chat(id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,user_id VARCHAR(80) NOT NULL,name VARCHAR(160) NOT NULL,sender VARCHAR(16) NOT NULL,message TEXT NOT NULL,created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,INDEX idx_thread(user_id,id)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
$db->exec('DELETE FROM mobile_chat_presence');
$db->exec('DELETE FROM mobile_chat_bot_state');
$admin=['user_id'=>'admin-main','user_role'=>'admin'];
$kelurahan=['user_id'=>'kelurahan-01','user_role'=>'admin_kelurahan'];
$asn=['user_id'=>'asn-01','user_role'=>'asn'];
$warga=['user_id'=>'resident-A','user_role'=>'warga'];
ensure(cikoko_chat_eligible_staff($admin)&&cikoko_chat_eligible_staff($kelurahan)&&cikoko_chat_eligible_staff($asn),
 'Admin Utama, Admin Kelurahan and ASN are authorized reply staff');
ensure(!cikoko_chat_eligible_staff($warga),'Citizen cannot impersonate online support staff');
ensure(!cikoko_chat_eligible_staff(['user_id'=>'asn-02','user_role'=>'asn','deny'=>true]),
 'Revoked ASN permission cannot impersonate available support staff');
ensure(!cikoko_chat_any_staff_online($db),'No staff is online before heartbeat');
$citizen=cikoko_chat_store($db,'resident-A','Warga A','warga','Butuh informasi layanan');
$bot=cikoko_chat_offline_ack($db,'resident-A');
ensure($bot!==null&&$bot['sender']==='bot'&&(int)$bot['id']>(int)$citizen['id'],
 'Offline citizen message immediately receives persisted bot holding reply');
ensure(str_contains((string)$bot['thread_user_id'],'resident-A') &&
 str_contains($bot['message']??'', 'Mohon menunggu tanggapan'),
 'Bot reply is in the correct resident thread and asks them to wait');
ensure(cikoko_chat_status(['id'=>$bot['id'],'sender'=>'bot'],[])==='system',
 'Bot status is separate from human delivery/read receipts');
$second=cikoko_chat_store($db,'resident-A','Warga A','warga','Mohon informasi lagi');
ensure(cikoko_chat_offline_ack($db,'resident-A')===null,
 'Repeated citizen messages while waiting do not generate bot spam');
$db->prepare('SELECT COUNT(*) FROM mobile_chat WHERE user_id=? AND sender="bot"')->execute(['resident-A']);
$nbot=(int)$db->query('SELECT COUNT(*) FROM mobile_chat WHERE user_id="resident-A" AND sender="bot"')->fetchColumn();
ensure($nbot===1,'Only one bot response before a human reply');
$human=cikoko_chat_store($db,'resident-A','Petugas ASN','admin','Kami akan membantu');
$third=cikoko_chat_store($db,'resident-A','Warga A','warga','Terima kasih, ada tambahan');
$rearm=cikoko_chat_offline_ack($db,'resident-A');
ensure($rearm!==null && $rearm['id']>$third['id'],
 'Human reply re-arms a new offline holding message when a citizen contacts again');
$staffHashA=str_repeat('a',64);$staffHashB=str_repeat('b',64);$staffHashC=str_repeat('c',64);
ensure(cikoko_chat_presence($db,$admin,true,$staffHashA),'Main admin session can become online');
ensure(cikoko_chat_presence($db,$kelurahan,true,$staffHashB),'Kelurahan admin session can become online');
ensure(cikoko_chat_presence($db,$asn,true,$staffHashC),'ASN session can become online');
ensure(cikoko_chat_any_staff_online($db),'At least one online authorized staff suppresses bot');
cikoko_chat_store($db,'resident-B','Warga B','warga','Halo dari warga B');
ensure(cikoko_chat_offline_ack($db,'resident-B')===null,
 'No automated reply while any authorized staff is online');
cikoko_chat_presence($db,$admin,false,$staffHashA);
cikoko_chat_presence($db,$kelurahan,false,$staffHashB);
ensure(cikoko_chat_any_staff_online($db),'ASN still online after both admin roles disconnect');
cikoko_chat_presence($db,$asn,false,$staffHashC);
ensure(!cikoko_chat_any_staff_online($db),'All staff sessions offline after closing');
$botB=cikoko_chat_offline_ack($db,'resident-B');
ensure($botB!==null && $botB['thread_user_id']==='resident-B',
 'Second resident can receive holding message after staff goes offline');
ensure(!cikoko_chat_presence($db,$warga,true,str_repeat('d',64)),
 'Citizen heartbeat cannot mark a staff session online');
ensure(!cikoko_chat_presence($db,['user_id'=>'asn-02','user_role'=>'asn','deny'=>true],true,str_repeat('e',64)),
 'Revoked staff heartbeat cannot mark a session online');
// A token-based session is independent from another device's token for the same staff account.
ensure(cikoko_chat_presence($db,$admin,true,str_repeat('f',64)), 'First admin device online');
ensure(cikoko_chat_presence($db,$admin,true,str_repeat('1',64)), 'Second admin device online');
cikoko_chat_presence($db,$admin,false,str_repeat('f',64));
ensure(cikoko_chat_any_staff_online($db),'Logging out first admin device does not disconnect the second');
$db->exec("UPDATE mobile_chat_presence SET last_seen_at=DATE_SUB(NOW(), INTERVAL 91 SECOND)");
ensure(!cikoko_chat_any_staff_online($db),'Stale heartbeat expires without a push or cron job');
$_GET=[];
$rows=cikoko_chat_page($db,'resident-A','warga');
ensure($rows['thread_user_id']==='resident-A' && count($rows['messages'])===6,
 'Citizen thread retains both human replies and two bot replies');
ensure(!str_contains(json_encode($rows),'Halo dari warga B'),
 'No cross-account chat text or bot response leakage');
echo "ALL OFFLINE BOT, STAFF PRESENCE AND PRIVACY CHECKS PASSED\n";
