<?php
declare(strict_types=1);
class ApiStop extends RuntimeException {public array $body;public function __construct(array $body,int $code){parent::__construct('', $code);$this->body=$body;}}
function mobile_error(string $text,int $status=400):void{throw new ApiStop(['ok'=>false,'error'=>$text],$status);}
function mobile_json(array $body,int $status=200):void{throw new ApiStop($body,$status);}
function mobile_text($value,int $max=1000):string{return substr(trim((string)$value),0,$max);}
function mobile_strlen(string $value):int{return strlen($value);}
$testUsers=[['id'=>'citizen-a','role'=>'warga','rt'=>'01','rw'=>'02']];
function db_read(string $key):array{global $testUsers;return $testUsers;}
$db=new PDO(getenv('TEST_MYSQL_DSN'),getenv('TEST_MYSQL_USER'),getenv('TEST_MYSQL_PASSWORD'),[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION,PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC,PDO::ATTR_EMULATE_PREPARES=>false]);
function mobile_db():PDO{global $db;return $db;}
require __DIR__.'/../cpanel/mobile-api/release_core.php';
function check(bool $condition,string $message):void{if(!$condition)throw new RuntimeException($message);}
cikoko_release_schema($db);cikoko_release_schema($db);
check(!cikoko_password_valid('short1'),'short password accepted');check(!cikoko_password_valid('abcdefghijk'),'missing numbers accepted');check(cikoko_password_valid('  validPass123  '),'password bytes unexpectedly trimmed');
for($i=0;$i<3;$i++)cikoko_rate_limit($db,'test','one',3,600);
try{cikoko_rate_limit($db,'test','one',3,600);throw new RuntimeException('rate limit bypassed');}catch(ApiStop $e){check($e->getCode()===429,'wrong throttle response');}
cikoko_rate_limit($db,'test','two',3,600);
$db->exec('CREATE TABLE mobile_chat(id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,user_id VARCHAR(80),sender VARCHAR(16),message TEXT,created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
$q=$db->prepare('INSERT INTO mobile_chat(user_id,sender,message) VALUES(?,"warga",?)');for($i=1;$i<=130;$i++)$q->execute(['citizen-a','Message '.$i]);$q->execute(['other','PRIVATE']);
$_GET=[];$page=cikoko_chat_page($db,'citizen-a');check(count($page['messages'])===60&&$page['has_more'],'latest pagination failed');check((int)$page['messages'][0]['id']===71,'latest page boundary wrong');
$_GET=['before_id'=>71];$page=cikoko_chat_page($db,'citizen-a');check((int)$page['messages'][0]['id']===11,'older pagination failed');
$_GET=['after_id'=>1];$page=cikoko_chat_page($db,'citizen-a');check((int)$page['messages'][0]['id']===2&&(int)$page['messages'][59]['id']===61,'incremental cursor skips messages');check($page['has_more'],'incremental continuation missing');
$action='report';$method='POST';$uid='citizen-a';$u=[];$response=['ok'=>true,'id'=>9];cikoko_capture_area($response);$testUsers[0]['rt']='99';cikoko_capture_area($response);$map=cikoko_area_snapshots($db);check($map['report:9']['rt']==='01','historical territory changed with profile');
$action='other';$response=['ok'=>true,'id'=>10];cikoko_capture_area($response);check(count(cikoko_area_snapshots($db))===1,'unrelated action creates territory');
echo "PASS: schema, password policy, throttling isolation, chat authorization/pagination, immutable territory snapshots\n";
