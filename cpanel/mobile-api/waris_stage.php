<?php
declare(strict_types=1);
/**
 * Secure split_v1 Ahli Waris staging. Images are bound to the bearer account
 * and a random 128-bit draft key; staging never exposes public file URLs.
 */
function cikoko_waris_stage_schema(PDO $db):void{
 static $ready=false;if($ready)return;
 $db->exec('CREATE TABLE IF NOT EXISTS mobile_waris_stage_files(
   user_id VARCHAR(80) NOT NULL,draft_key CHAR(32) NOT NULL,
   requirement_code VARCHAR(40) NOT NULL,original_name VARCHAR(200) NOT NULL,
   storage_name VARCHAR(100) NOT NULL,mime_type VARCHAR(40) NOT NULL,
   size_bytes BIGINT UNSIGNED NOT NULL,created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY(user_id,draft_key,requirement_code),INDEX idx_expiry(created_at)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
 $ready=true;
}
function cikoko_waris_stage_root():string{
 return dirname(__DIR__).'/ahli-waris/private/uploads';
}
function cikoko_waris_stage_dir():string{
 return __DIR__.'/private/waris-stage';
}
function cikoko_waris_code_valid(string $code):bool{
 return preg_match('/^(?:r[1-3]|r4_(?:ktp|kk|akta)|r[5-8]|child_(?:[1-9]|10)_(?:ktp|kk|akta))$/',$code)===1;
}
function cikoko_waris_draft_key($raw):string{
 $key=(string)$raw;
 if(!preg_match('/^[a-f0-9]{32}$/',$key))mobile_error('Kunci draft pengajuan tidak valid.',422);
 return $key;
}
function cikoko_waris_stage_dispatch(string $action,string $method,PDO $db,array $u):void{
 mobile_need($u,'waris:create');
 if($action==='waris_format'){
  if($method!=='GET')mobile_error('Metode tidak didukung.',405);
  mobile_json(['ok'=>true,'upload_format'=>'split_v1',
   'staged_uploads'=>true,
   'max_file_uploads'=>(int)ini_get('max_file_uploads'),
   'max_bytes_per_photo'=>4*1024*1024]);
 }
 if($action!=='waris_stage'||$method!=='POST')mobile_error('Endpoint tidak dikenali.',404);
 cikoko_waris_stage_schema($db);
 $uid=(string)$u['user_id'];$draft=cikoko_waris_draft_key($_POST['draft_key']??'');
 $codes=array_keys($_FILES);
 if(!$codes||count($codes)>8)mobile_error('Unggah maksimum delapan dokumen per tahap.',422);
 $stage=cikoko_waris_stage_dir();
 if(!is_dir($stage)&&!@mkdir($stage,0750,true))mobile_error('Penyimpanan sementara dokumen tidak tersedia.',503);
 // Bound unaudited storage growth per account and draft.
 $quota=$db->prepare('SELECT COUNT(*) AS n,COALESCE(SUM(size_bytes),0) AS bytes FROM mobile_waris_stage_files WHERE user_id=?');
 $quota->execute([$uid]);$usage=$quota->fetch(PDO::FETCH_ASSOC);
 if((int)$usage['n']>90||(int)$usage['bytes']>160*1024*1024){
  mobile_error('Batas foto draft tercapai. Hubungi admin untuk membersihkan draft lama.',429);
 }
 $draftCount=$db->prepare('SELECT COUNT(*) FROM mobile_waris_stage_files WHERE user_id=? AND draft_key=?');
 $draftCount->execute([$uid,$draft]);
 if((int)$draftCount->fetchColumn()+count($codes)>48){
  mobile_error('Jumlah dokumen pada satu draft terlalu banyak.',422);
 }
 $fileRows=[];
 foreach($codes as $code){
  if(!cikoko_waris_code_valid($code))mobile_error('Jenis berkas tidak diizinkan.',422);
  $f=$_FILES[$code];
  if(!is_array($f)||is_array($f['name'])||($f['error']??UPLOAD_ERR_NO_FILE)!==UPLOAD_ERR_OK
    ||($f['size']??0)<100||($f['size']??0)>4*1024*1024
    ||!is_uploaded_file((string)($f['tmp_name']??''))){
   mobile_error('Berkas '.$code.' harus berupa foto valid maksimal 4 MB.',422);
  }
  $mime=(new finfo(FILEINFO_MIME_TYPE))->file($f['tmp_name']);
  $ext=['image/jpeg'=>'jpg','image/png'=>'png','image/webp'=>'webp'][$mime]??null;
  if(!$ext||@getimagesize($f['tmp_name'])===false)mobile_error('Berkas '.$code.' bukan foto JPG/PNG/WebP.',422);
  $fileRows[$code]=[$f,$mime,$ext];
 }
 $saved=[];
 try{
  foreach($fileRows as $code=>[$f,$mime,$ext]){
   $name=bin2hex(random_bytes(20)).'.'.$ext;
   if(!move_uploaded_file($f['tmp_name'],$stage.'/'.$name))throw new RuntimeException('Gagal menyimpan berkas sementara.');
   $saved[]=$stage.'/'.$name;
   $previous=$db->prepare('SELECT storage_name FROM mobile_waris_stage_files WHERE user_id=? AND draft_key=? AND requirement_code=?');
   $previous->execute([$uid,$draft,$code]);$old=$previous->fetchColumn();
   $q=$db->prepare('INSERT INTO mobile_waris_stage_files(user_id,draft_key,requirement_code,original_name,storage_name,mime_type,size_bytes) VALUES(?,?,?,?,?,?,?)
      ON DUPLICATE KEY UPDATE original_name=VALUES(original_name),storage_name=VALUES(storage_name),mime_type=VALUES(mime_type),size_bytes=VALUES(size_bytes),created_at=NOW()');
   $q->execute([$uid,$draft,$code,mobile_text($f['name'],200),$name,$mime,(int)$f['size']]);
   if($old && preg_match('/^[a-f0-9]{40}\.(jpg|png|webp)$/',$old))@unlink($stage.'/'.$old);
  }
 }catch(Throwable $e){
  foreach($saved as $path)@unlink($path);
  error_log('Waris staging upload: '.$e->getMessage());
  mobile_error('Foto belum berhasil disimpan sementara. Silakan coba kembali.',503);
 }
 mobile_json(['ok'=>true,'draft_key'=>$draft,'received_codes'=>$codes]);
}
function cikoko_waris_finalize(PDO $db,array $user):void{
 mobile_need($user,'waris:create');
 $uid=(string)$user['user_id'];
 if(($_POST['document_format']??'')!=='split_v1'){
  mobile_error('Format surat tidak sesuai. Perbarui aplikasi ke versi terbaru.',409);
 }
 $draft=cikoko_waris_draft_key($_POST['draft_key']??'');
 cikoko_waris_stage_schema($db);
 require_once dirname(__DIR__).'/ahli-waris/bootstrap.php';
 try{aw_prepare_schema($db);}catch(Throwable $e){
  error_log('Waris schema: '.$e->getMessage());
  mobile_error('Struktur penyimpanan Ahli Waris belum siap.',503);
 }
 $nik=trim((string)($_POST['nik']??''));
 if(!preg_match('/^[0-9]{16}$/',$nik))mobile_error('NIK wajib 16 angka.',422);
 foreach(['name','phone','address','relation','deceased_name','heirs'] as $key){
  if(trim((string)($_POST[$key]??''))==='')mobile_error('Lengkapi kolom '.$key,422);
 }
 $childrenRaw=trim((string)($_POST['child_count']??'0'));
 if(!preg_match('/^(?:[0-9]|10)$/',$childrenRaw))mobile_error('Jumlah anak maksimal 10.',422);
 $childCount=(int)$childrenRaw;
 $required=['r1','r2','r3','r4_ktp','r4_kk','r4_akta','r5','r6'];
 for($i=1;$i<=$childCount;$i++){
  if(trim((string)($_POST['child_name_'.$i]??''))==='')mobile_error('Nama anak ke-'.$i.' wajib diisi.',422);
  foreach(['ktp','kk','akta'] as $type)$required[]='child_'.$i.'_'.$type;
 }
 $dir=cikoko_waris_stage_root();
 $stage=cikoko_waris_stage_dir();
 if(!is_dir($dir))mobile_error('Penyimpanan Ahli Waris tidak tersedia.',503);
 $reference='AW-'.date('Ymd').'-'.strtoupper(bin2hex(random_bytes(4)));
 $moved=[];$appId=0;
 try{
  $db->beginTransaction();
  $q=$db->prepare('SELECT requirement_code,original_name,storage_name,mime_type,size_bytes FROM mobile_waris_stage_files WHERE user_id=? AND draft_key=? FOR UPDATE');
  $q->execute([$uid,$draft]);$rows=$q->fetchAll(PDO::FETCH_ASSOC);
  $by=[];foreach($rows as $row)$by[$row['requirement_code']]=$row;
  foreach($required as $code)if(!isset($by[$code]))throw new DomainException('Berkas wajib belum lengkap: '.$code,422);
  $nameList=[];
  for($i=1;$i<=$childCount;$i++){
   $nameList[]=['number'=>$i,'name'=>mobile_text($_POST['child_name_'.$i]??'',180)];
  }
  $sql='INSERT INTO aw_applications(reference_no,account_id,applicant_name,applicant_nik,applicant_phone,applicant_address,relationship,deceased_name,marital_status,deceased_birthplace,deceased_birthdate,deceased_deathdate,deceased_marriage_date,heirs,children_json) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)';
  $db->prepare($sql)->execute([$reference,$uid,mobile_text($_POST['name'],160),$nik,
   mobile_text($_POST['phone'],40),mobile_text($_POST['address'],3000),
   mobile_text($_POST['relation'],100),mobile_text($_POST['deceased_name'],200),
   mobile_text($_POST['marital_status']??'Tidak diketahui',40),
   mobile_text($_POST['birthplace']??'',160),($_POST['birthdate']??'')?:null,
   ($_POST['deathdate']??'')?:null,($_POST['marriage_date']??'')?:null,
   mobile_text($_POST['heirs'],12000),json_encode($nameList,JSON_UNESCAPED_UNICODE|JSON_THROW_ON_ERROR)]);
  $appId=(int)$db->lastInsertId();
  $insert=$db->prepare('INSERT INTO aw_attachments(application_id,requirement_code,original_name,storage_name,mime_type,size_bytes) VALUES(?,?,?,?,?,?)');
  foreach($rows as $row){
   $code=(string)$row['requirement_code'];
   if(!in_array($code,$required,true)&&!in_array($code,['r7','r8'],true))continue;
   $name=(string)$row['storage_name'];
   if(!preg_match('/^[a-f0-9]{40}\.(jpg|png|webp)$/',$name))throw new RuntimeException('Nama lampiran tidak valid.');
   $src=$stage.'/'.$name;$dest=$dir.'/'.$name;
   if(!is_file($src)||!rename($src,$dest))throw new RuntimeException('Penyimpanan final lampiran gagal.');
   $moved[]=[$src,$dest];
   $insert->execute([$appId,$code,$row['original_name'],$name,$row['mime_type'],(int)$row['size_bytes']]);
  }
  $db->prepare('INSERT INTO aw_history(application_id,previous_status,new_status,actor_id,notes) VALUES (?,NULL,"masuk",?,"Permohonan split_v1 dari Android")')
    ->execute([$appId,$uid]);
  $db->prepare('DELETE FROM mobile_waris_stage_files WHERE user_id=? AND draft_key=?')->execute([$uid,$draft]);
  $db->commit();
 }catch(Throwable $e){
  if($db->inTransaction())$db->rollBack();
  foreach($moved as [$src,$dest])if(is_file($dest))@rename($dest,$src);
  if($e instanceof DomainException&&$e->getCode()===422)mobile_error($e->getMessage(),422);
  error_log('Waris split_v1 finalize: '.$e->getMessage());
  mobile_error('Dokumen Ahli Waris belum berhasil disimpan. Formulir dan foto tetap dapat dicoba ulang.',503);
 }
 // Old or superseded staged photos are no longer needed after finalization.
 foreach($rows as $row){
  $path=$stage.'/'.(string)$row['storage_name'];
  if(is_file($path))@unlink($path);
 }
 mobile_emit('surat','Surat Ahli Waris baru','Pengajuan '.$reference.' masuk','admin');
 waris_review_schema($db);
 waris_emit_link($db,'waris',$appId,'progres_surat','Permohonan diterima',$reference,'personal',$uid);
 mobile_json(['ok'=>true,'reference'=>$reference,'id'=>$appId]);
}
