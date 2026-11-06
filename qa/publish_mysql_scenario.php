<?php
declare(strict_types=1);
/**
 * Disposable CI scenario. Uses an ephemeral MySQL service with synthetic
 * accounts; never connects to public hosting or accesses real user data.
 *
 * php qa/publish_mysql_scenario.php ACTION ACTOR JSON
 */
ini_set('display_errors','stderr');
error_reporting(E_ALL);
$action=(string)($argv[1]??'');
$actor=(string)($argv[2]??'');
$payload=json_decode((string)($argv[3]??'{}'),true)??[];
$accounts=[
    ['id'=>'residentA','name'=>'Warga A','role'=>'warga','rt'=>'01','rw'=>'02','active'=>true],
    ['id'=>'residentB','name'=>'Warga B','role'=>'warga','rt'=>'03','rw'=>'02','active'=>true],
    ['id'=>'rtA','name'=>'Ketua RT 01','role'=>'rt','rt'=>'01','rw'=>'02','active'=>true],
    ['id'=>'rtOther','name'=>'Ketua RT 03','role'=>'rt','rt'=>'03','rw'=>'02','active'=>true],
    ['id'=>'rwA','name'=>'Ketua RW 02','role'=>'rw','rt'=>'','rw'=>'02','active'=>true],
    ['id'=>'rwOther','name'=>'Ketua RW 03','role'=>'rw','rt'=>'','rw'=>'03','active'=>true],
    ['id'=>'bendaharaA','name'=>'Bendahara RT A','role'=>'bendahara_rt','rt'=>'01','rw'=>'02','active'=>true],
    ['id'=>'bendaharaB','name'=>'Bendahara RT B','role'=>'bendahara_rt','rt'=>'01','rw'=>'02','active'=>true],
    ['id'=>'lmkA','name'=>'LMK RW 02','role'=>'lmk','rt'=>'','rw'=>'02','active'=>true],
];
foreach($accounts as &$entry)$entry['password_hash']=password_hash('correct-test-password',PASSWORD_DEFAULT);
unset($entry);
function db_read(string $type):array {return $type==='portal_users'?$GLOBALS['accounts']:[];}
function db_write(string $type,array $value):bool {return false;}
function mobile_body():array {return $GLOBALS['payload'];}
function mobile_text($raw,int $max=1000):string {return substr(trim((string)$raw),0,$max);}
function mobile_strlen(string $raw):int {return strlen($raw);}
function mobile_json(array $data,int $status=200):void {
    echo json_encode($data,JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES|JSON_THROW_ON_ERROR);
    exit($status>=400?10:0);
}
function mobile_error(string $message,int $status=400):void {
    mobile_json(['ok'=>false,'status'=>$status,'error'=>$message],$status);
}
function mobile_emit(string $category,string $title,string $message,string $audience='public',?string $recipient=null):void {}
function mobile_need(array $account,string $permission):void {
    if($account['user_role']!=='warga')mobile_error('No permission in test',403);
}
$db=new PDO(
  'mysql:host=127.0.0.1;port=3306;dbname=cikoko_qa;charset=utf8mb4',
  'root',(string)(getenv('CIKOKO_QA_MYSQL_PASSWORD')?:'qa-only-password'),
  [PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION,
   PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC,
   PDO::ATTR_EMULATE_PREPARES=>false]);
require __DIR__.'/../cpanel/mobile-api/rt_rw_service.php';
require __DIR__.'/../cpanel/mobile-api/civic_lpj.php';
require __DIR__.'/../cpanel/mobile-api/waris_staging.php';
$user=null;
foreach($accounts as $entry)if($entry['id']===$actor)$user=$entry;
$auth=['user_id'=>$actor,'user_role'=>$user['role']??'admin',
  'username'=>$user['name']??'Administrator'];
if($action==='init'){
    cikoko_rt_schema($db);cikoko_civic_schema($db);
    if(!function_exists('imagecreatetruecolor'))mobile_error('GD not available for integration test',503);
    $dir=__DIR__.'/../cpanel/mobile-api/private';
    if(!is_dir($dir))mkdir($dir,0750,true);
    $img=imagecreatetruecolor(90,30);
    imagefill($img,0,0,imagecolorallocate($img,255,255,255));
    imagestring($img,3,5,6,'QA ONLY',imagecolorallocate($img,0,0,0));
    foreach(['rtA','rwA'] as $name){
        foreach(['signature','stamp'] as $part)imagejpeg($img,$dir."/qa_{$name}_{$part}.jpg",90);
        $q=$db->prepare('INSERT INTO mobile_rt_rw_signers(user_id,signature_name,stamp_name)
          VALUES(?,?,?) ON DUPLICATE KEY UPDATE signature_name=VALUES(signature_name),stamp_name=VALUES(stamp_name)');
        $q->execute([$name,"qa_{$name}_signature.jpg","qa_{$name}_stamp.jpg"]);
    }
    imagedestroy($img);
    mobile_json(['ok'=>true,'initialized'=>true]);
}
if($action==='rt_rw_submit'||str_starts_with($action,'rt_rw_')){
    if(str_ends_with($action,'_pdf')||str_ends_with($action,'_list')){
        $_GET['id']=$payload['id']??null;
    }
    cikoko_rt_dispatch($action,($action==='rt_rw_submit'||$action==='rt_rw_decide')?'POST':'GET',
      $db,$auth,$actor);
}
if(str_starts_with($action,'civic_')){
    $_GET['id']=$payload['id']??null;
    $method=in_array($action,['civic_submit','civic_review','civic_pin_set'],true)?'POST':'GET';
    cikoko_civic_dispatch($action,$method,$db,$auth,$actor);
}
if($action==='waris_format')cikoko_waris_stage_route($action,'GET',$auth,$actor);
mobile_error('Unknown test action',404);
