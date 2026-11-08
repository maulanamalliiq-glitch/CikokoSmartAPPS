<?php
declare(strict_types=1);
// Only run against an isolated disposable test database.
$dsn=getenv('TEST_MYSQL_DSN')?:'';
if($dsn==='' || !str_contains($dsn,'dbname=cikoko_test'))throw new RuntimeException('Refuse to run outside isolated cikoko_test database.');
function mobile_error(string $message,int $code=400):void{throw new RuntimeException($message,$code);}
function mobile_can(array $actor,string $permission):bool{return in_array($permission,$actor['caps']??[],true);}
function mobile_strlen(string $s):int{return strlen($s);}
require __DIR__.'/../cpanel/mobile-api/release_core.php';
require __DIR__.'/../cpanel/mobile-api/chat_storage_2544.php';
function ensure(bool $condition,string $description):void{if(!$condition)throw new RuntimeException('FAILED: '.$description);echo "PASS ".$description."\n";}
$db=new PDO($dsn,(string)getenv('TEST_MYSQL_USER'),(string)getenv('TEST_MYSQL_PASSWORD'),[
 PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION,
 PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC,
 PDO::ATTR_EMULATE_PREPARES=>false]);
cikoko_release_schema($db);
$db->exec('DROP TABLE IF EXISTS mobile_chat');
$db->exec('CREATE TABLE mobile_chat(id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, user_id VARCHAR(80) NOT NULL, name VARCHAR(160) NOT NULL, sender VARCHAR(16) NOT NULL, message TEXT NOT NULL,created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, INDEX idx_thread(user_id,id)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
$a1=cikoko_chat_store($db,'test-warga-A','Warga A','warga','Pesan yang sama');
$a2=cikoko_chat_store($db,'test-warga-A','Warga A','warga','Pesan yang sama');
$b1=cikoko_chat_store($db,'test-warga-B','Warga B','warga','Ini rahasia B');
$reply=cikoko_chat_store($db,'test-warga-A','Admin Kelurahan','admin','Balasan admin A');
ensure($a1['id']>0&&$a2['id']>$a1['id']&&$b1['id']>$a2['id']&&$reply['id']>$b1['id'],'Repeated messages are persisted with distinct IDs');
ensure($a1['stored']===true&&$reply['stored']===true&&$reply['thread_user_id']==='test-warga-A','Success returned only after DB read-after-write and correct owner');
$_GET=[];
$read=cikoko_chat_page($db,'test-warga-A','admin');
ensure(count($read['messages'])===3&&$read['thread_user_id']==='test-warga-A','Admin thread contains messages from A only');
ensure(!str_contains(json_encode($read),'Ini rahasia B'),'No B content in A chat page');
$citizen=['user_id'=>'test-warga-A','caps'=>[]];
$admin=['user_id'=>'admin','caps'=>['chat:reply']];
$own=cikoko_chat_diagnostic($db,$citizen,'');
ensure($own['total']===3&&$own['warga_count']===2&&$own['admin_count']===1,'Resident diagnostic reflects persisted messages');
ensure(!str_contains(json_encode($own),'Pesan yang sama'),'Diagnostic never returns message contents');
try{cikoko_chat_diagnostic($db,$citizen,'test-warga-B');throw new RuntimeException('Resident A was allowed to inspect B');}
catch(RuntimeException $e){ensure($e->getCode()===403,'Resident A cannot inspect resident B diagnostic');}
$adminB=cikoko_chat_diagnostic($db,$admin,'test-warga-B');
ensure($adminB['total']===1&&$adminB['thread_user_id']==='test-warga-B','Officer diagnostic can select correct resident');
$_GET=['after_id'=>$reply['id']];
$latest=cikoko_chat_page($db,'test-warga-A','warga');
ensure(count($latest['messages'])===0&&($latest['receipt_updates'][(string)$a1['id']]??'')==='read','Delivery receipts refresh even without new messages');
try{cikoko_chat_store($db,'test-warga-A','Warga A','warga','  ');throw new RuntimeException('Blank message was accepted');}
catch(RuntimeException $e){ensure($e->getCode()===422,'Empty message rejected safely');}
echo "ALL CHAT STORAGE AND PRIVACY TESTS PASSED\n";
