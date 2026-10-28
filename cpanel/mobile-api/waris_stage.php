<?php
declare(strict_types=1);
// Staged Ahli Waris documents: <=8 attachments per HTTP request.
// Only a Bearer-authenticated account can create/finalize its own draft.
function waris_stage_schema(PDO $db):void {
  static $ready=false;
  if($ready)return;
  $db->exec('CREATE TABLE IF NOT EXISTS mobile_waris_staging (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    draft_key CHAR(32) NOT NULL,
    user_id VARCHAR(80) NOT NULL,
    requirement_code VARCHAR(40) NOT NULL,
    original_name VARCHAR(255) NOT NULL,
    storage_name VARCHAR(80) NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    size_bytes INT UNSIGNED NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uniq_upload(user_id,draft_key,requirement_code),
    KEY idx_stale(created_at),
    KEY idx_owner(user_id,draft_key)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
  $ready=true;
}
function waris_stage_key(string $key):string {
  if(!preg_match('/^[a-f0-9]{32}$/D',$key))mobile_error('Sesi unggahan Ahli Waris tidak valid. Coba kirim ulang.',422);
  return $key;
}
function waris_stage_rows(PDO $db,string $uid,string $key):array {
  waris_stage_schema($db);
  $q=$db->prepare('SELECT requirement_code,original_name,storage_name,mime_type,size_bytes
    FROM mobile_waris_staging WHERE user_id=? AND draft_key=?');
  $q->execute([$uid,$key]);
  $out=[];
  foreach($q->fetchAll() as $row)$out[(string)$row['requirement_code']]=$row;
  return $out;
}
function waris_stage_upload(PDO $db,string $uid,string $draft):void {
  $draft=waris_stage_key($draft);
  waris_stage_schema($db);
  // Cleanup bounded only to this account's stale uploads.
  $expired=$db->prepare('SELECT storage_name FROM mobile_waris_staging
    WHERE user_id=? AND created_at<DATE_SUB(NOW(), INTERVAL 1 DAY) LIMIT 250');
  $expired->execute([$uid]);
  $stale=$expired->fetchAll(PDO::FETCH_COLUMN);
  $db->prepare('DELETE FROM mobile_waris_staging WHERE user_id=? AND created_at<DATE_SUB(NOW(), INTERVAL 1 DAY)')
    ->execute([$uid]);
  $folder=dirname(__DIR__).'/ahli-waris/private/uploads';
  foreach($stale as $stored){
    if(preg_match('/^[a-f0-9]{40}\.(jpg|png|webp)$/D',(string)$stored))@unlink($folder.'/'.$stored);
  }
  if(count($_FILES)<1||count($_FILES)>8)mobile_error('Kirim 1 sampai 8 foto setiap tahap.',422);
  $allowed=waris_codes(10);
  $existing=waris_stage_rows($db,$uid,$draft);
  if(count($existing)>48)mobile_error('Maksimal 40 dokumen utama dan 2 dokumen tambahan.',422);
  if(!is_dir($folder)&&!mkdir($folder,0750,true))mobile_error('Folder dokumen Ahli Waris belum tersedia.',503);
  $uploaded=[];
  foreach($_FILES as $code=>$f){
    if(!isset($allowed[$code])||in_array($code,['r4'],true)||substr($code,-4)==='_old'||
       !is_array($f)||is_array($f['name']??null)||
       ($f['error']??UPLOAD_ERR_NO_FILE)!==UPLOAD_ERR_OK||
       !is_uploaded_file($f['tmp_name']??'')||($f['size']??0)<100||
       ($f['size']??0)>4*1024*1024){
      mobile_error('Foto '.($allowed[$code]??$code).' tidak valid, maksimal 4 MB.',422);
    }
    $mime=(new finfo(FILEINFO_MIME_TYPE))->file($f['tmp_name']);
    $ext=['image/jpeg'=>'jpg','image/png'=>'png','image/webp'=>'webp'][$mime]??null;
    if(!$ext)mobile_error('Foto '.($allowed[$code]??$code).' harus JPG/PNG/WebP.',422);
    $uploaded[$code]=['tmp'=>$f['tmp_name'],'original'=>substr(basename((string)$f['name']),0,255),
       'ext'=>$ext,'mime'=>$mime,'size'=>(int)$f['size']];
  }
  // Protect against quota exhaustion and overlong drafts.
  $merged=array_unique(array_merge(array_keys($existing),array_keys($uploaded)));
  if(count($merged)>40)mobile_error('Maksimal 40 foto untuk satu permohonan.',422);
  $newPaths=[];$oldPaths=[];
  try{
    $db->beginTransaction();
    $save=$db->prepare('INSERT INTO mobile_waris_staging
      (user_id,draft_key,requirement_code,original_name,storage_name,mime_type,size_bytes)
      VALUES(?,?,?,?,?,?,?)
      ON DUPLICATE KEY UPDATE original_name=VALUES(original_name),
        storage_name=VALUES(storage_name),mime_type=VALUES(mime_type),
        size_bytes=VALUES(size_bytes),created_at=NOW()');
    foreach($uploaded as $code=>$f){
      $name=bin2hex(random_bytes(20)).'.'.$f['ext'];
      if(!move_uploaded_file($f['tmp'],$folder.'/'.$name))throw new RuntimeException('Gagal menyimpan foto sementara');
      $newPaths[]=$folder.'/'.$name;
      $save->execute([$uid,$draft,$code,$f['original'],$name,$f['mime'],$f['size']]);
      if(isset($existing[$code]))$oldPaths[]=$folder.'/'.$existing[$code]['storage_name'];
    }
    $db->commit();
  }catch(Throwable $e){
    if($db->inTransaction())$db->rollBack();
    foreach($newPaths as $path)@unlink($path);
    error_log('Waris stage error: '.$e->getMessage());
    mobile_error('Penyimpanan sementara gagal. Coba ulang tahap foto.',503);
  }
  foreach($oldPaths as $p)@unlink($p);
  mobile_json(['ok'=>true,'saved'=>count($uploaded),'total'=>count($merged),
    'batch_limit'=>8,'draft_key'=>$draft]);
}
