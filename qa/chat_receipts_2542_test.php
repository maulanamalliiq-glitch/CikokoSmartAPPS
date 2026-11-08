<?php
declare(strict_types=1);
function mobile_text($v,int $max=1000):string{return substr(trim((string)$v),0,$max);}
function mobile_strlen(string $v):int{return strlen($v);}
function mobile_error(string $message,int $code=400):void{throw new RuntimeException($message,$code);}
require __DIR__.'/../cpanel/mobile-api/release_core.php';
function assert_chat(bool $ok,string $reason):void{if(!$ok)throw new RuntimeException($reason);}
$db=new PDO(getenv('TEST_MYSQL_DSN'),getenv('TEST_MYSQL_USER'),getenv('TEST_MYSQL_PASSWORD'),[
 PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION,PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC,
 PDO::ATTR_EMULATE_PREPARES=>false]);
cikoko_release_schema($db);
$db->exec('CREATE TABLE mobile_chat(id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,user_id VARCHAR(80),sender VARCHAR(16),message TEXT,created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
$insert=$db->prepare('INSERT INTO mobile_chat(user_id,sender,message) VALUES(?,?,?)');
foreach([['resident-A','warga','Hai Admin'],['resident-A','admin','Halo Warga'],['resident-B','warga','Private B']] as $p)$insert->execute($p);
$_GET=[];
$a=cikoko_chat_page($db,'resident-A','warga');
assert_chat(count($a['messages'])===2,'Citizen thread includes another resident');
assert_chat($a['messages'][0]['delivery_status']==='sent','Own message must start as sent');
assert_chat($a['messages'][1]['delivery_status']==='read','Admin reply is read when resident opens thread');
$r=cikoko_chat_receipt_data($db,'resident-A');
assert_chat((int)$r['warga_read_id']===2,'Resident read watermark not persisted');
assert_chat((int)$r['admin_read_id']===0,'Reading reply cannot mark citizens own message read by admin');
cikoko_chat_ack($db,'resident-A','admin','delivered',1);
$r=cikoko_chat_receipt_data($db,'resident-A');
assert_chat((int)$r['admin_delivered_id']===1 && (int)$r['admin_read_id']===0,'Inbox delivery must not mark read');
$_GET=['after_id'=>2];
$a=cikoko_chat_page($db,'resident-A','warga');
assert_chat(count($a['messages'])===0,'Cursor should not repeat messages');
assert_chat(($a['receipt_updates']['1']??'')==='delivered','No-new-message polling must return delivery status update');
$_GET=[];
$a=cikoko_chat_page($db,'resident-A','admin');
assert_chat(($a['receipt_updates']['1']??'')==='read','Only opening admin thread may mark citizens message read');
cikoko_chat_ack($db,'resident-A','admin','delivered',1);
$r=cikoko_chat_receipt_data($db,'resident-A');
assert_chat((int)$r['admin_read_id']===1,'Delivery cannot regress already read status');
assert_chat(!cikoko_chat_receipt_data($db,'resident-B'),'Other account receipts must remain untouched');
$_GET=[];
$b=cikoko_chat_page($db,'resident-B','warga');
assert_chat(count($b['messages'])===1 && $b['messages'][0]['delivery_status']==='sent','Cross-account read status leaked');
assert_chat(!isset($b['receipt_updates']['1']),'Other resident receipt IDs leaked');
echo "PASS: sent/delivered/read, monotonic acknowledgments, no unread-to-read auto escalation, private cursors\n";
