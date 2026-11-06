<?php
declare(strict_types=1);
/**
 * Synthetic local-file test: verifies the exact split_v1 attachment schema,
 * account-scoped staging, and safe persistence without using user documents.
 */
function mobile_error(string $message,int $status=400):void {
    throw new RuntimeException($message,$status);
}
function mobile_text($value,int $max=1000):string {
    return substr(trim((string)$value),0,$max);
}
require __DIR__.'/../cpanel/mobile-api/waris_staging.php';
if(!extension_loaded('pdo_sqlite'))throw new RuntimeException('Missing pdo_sqlite in QA runner');
$uid='qa-warga-synthetic-A';
$otherUid='qa-warga-synthetic-B';
$draft=str_repeat('a',32);
$dir=cikoko_waris_stage_dir($uid,$draft,true);
$codes=['r1','r2','r3','r4_ktp','r4_kk','r4_akta','r5','r6'];
$png=base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAOz1XxQAAAAASUVORK5CYII=');
$manifest=[];
foreach($codes as $code){
    $name=$code.'.png';
    file_put_contents($dir.'/'.$name,$png);
    $manifest[$code]=['storage'=>$name,'name'=>$name,'mime'=>'image/png','size'=>strlen($png)];
}
file_put_contents($dir.'/manifest.json',json_encode($manifest,JSON_THROW_ON_ERROR));
$records=cikoko_waris_stage_collect($uid,$draft,0);
if(count($records)!==8)throw new RuntimeException('Eight mandatory documents not recovered');
echo "PASS: eight split-v1 documents recovered under original account\n";
$blocked=false;
try{cikoko_waris_stage_collect($otherUid,$draft,0);}catch(RuntimeException $e){
    $blocked=$e->getCode()===409;
}
if(!$blocked)throw new RuntimeException('Another account can reuse a staged draft');
echo "PASS: another account cannot recover staged documents\n";
$uploads=sys_get_temp_dir().'/cikoko-synthetic-uploads-'.bin2hex(random_bytes(7));
if(!mkdir($uploads,0700,true))throw new RuntimeException('Could not create QA temp folder');
$pdo=new PDO('sqlite::memory:',null,null,[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION]);
$pdo->exec('CREATE TABLE aw_attachments(
  application_id INTEGER,requirement_code TEXT,original_name TEXT,
  storage_name TEXT,mime_type TEXT,size_bytes INTEGER)');
$insert=$pdo->prepare('INSERT INTO aw_attachments
  (application_id,requirement_code,original_name,storage_name,mime_type,size_bytes)
  VALUES(?,?,?,?,?,?)');
$paths=[];
cikoko_waris_stage_persist($records,$uploads,41,$insert,$paths);
$count=(int)$pdo->query('SELECT COUNT(*) FROM aw_attachments')->fetchColumn();
if($count!==8||count($paths)!==8)throw new RuntimeException('Attachment rows or copies missing');
foreach($paths as $path){
    if(!is_file($path)||filesize($path)!==strlen($png))
        throw new RuntimeException('Copied image content mismatch');
}
echo "PASS: eight private photo copies and eight database attachment records\n";
cikoko_waris_stage_clean($uid,$draft);
if(is_dir($dir))throw new RuntimeException('Synthetic draft was not cleared');
foreach($paths as $path)@unlink($path);
@rmdir($uploads);
echo "PASS: staged source removed after successful completion\n";
