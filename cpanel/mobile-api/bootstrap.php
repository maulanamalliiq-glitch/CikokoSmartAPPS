<?php
declare(strict_types=1);
require_once dirname(__DIR__).'/roles-lib.php';
header('Cache-Control: no-store');
header('X-Content-Type-Options: nosniff');
function mobile_json(array $a,int $code=200):void {http_response_code($code);echo json_encode($a,JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES|JSON_INVALID_UTF8_SUBSTITUTE);exit;}
function mobile_error(string $message,int $code=400):void {mobile_json(['ok'=>false,'error'=>$message],$code);}
function mobile_db():PDO {
 static $db=null;
 if($db)return $db;
 $path=dirname(__DIR__).'/ahli-waris/config.php';
 if(!is_file($path))mobile_error('Konfigurasi database belum tersedia',503);
 $cfg=require $path;
 try {$db=new PDO('mysql:host='.$cfg['host'].';port='.($cfg['port']??3306).';dbname='.$cfg['database'].';charset=utf8mb4',$cfg['username'],$cfg['password'],[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION,PDO::ATTR_EMULATE_PREPARES=>false,PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC]);}
 catch(Throwable $e){error_log('Cikoko mobile db failure: '.$e->getMessage());mobile_error('Database tidak tersedia',503);}
 mobile_schema($db);return $db;
}
function mobile_schema(PDO $db):void {
 static $done=false;if($done)return;
 $statements=[
 'CREATE TABLE IF NOT EXISTS mobile_tokens (id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, token_hash CHAR(64) NOT NULL UNIQUE, user_id VARCHAR(80) NOT NULL, username VARCHAR(100) NOT NULL, user_role VARCHAR(40) NOT NULL, expires_at DATETIME NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, INDEX idx_user(user_id)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4',
 'CREATE TABLE IF NOT EXISTS mobile_devices (id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, user_id VARCHAR(80) NOT NULL, username VARCHAR(100) NOT NULL, fcm_token VARCHAR(255) NOT NULL UNIQUE, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, INDEX idx_user(user_id)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4',
 'CREATE TABLE IF NOT EXISTS mobile_events (id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, category VARCHAR(40) NOT NULL, title VARCHAR(240) NOT NULL, message TEXT NOT NULL, audience VARCHAR(20) NOT NULL DEFAULT "public", recipient VARCHAR(80) NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, dispatched_at DATETIME NULL, INDEX idx_pending(dispatched_at,id), INDEX idx_recipient(recipient)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4',
 'CREATE TABLE IF NOT EXISTS mobile_reports (id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, user_id VARCHAR(80) NOT NULL, user_name VARCHAR(160) NOT NULL, user_role VARCHAR(50) NOT NULL, kind VARCHAR(60) NOT NULL, address VARCHAR(500) NOT NULL, phone VARCHAR(40) NOT NULL, notes TEXT NOT NULL, photo_name VARCHAR(100) NULL, status VARCHAR(20) NOT NULL DEFAULT "masuk", created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, INDEX idx_user(user_id), INDEX idx_status(status)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4',
 'CREATE TABLE IF NOT EXISTS mobile_event_reads (user_id VARCHAR(80) NOT NULL,event_id BIGINT UNSIGNED NOT NULL,read_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,PRIMARY KEY(user_id,event_id),INDEX idx_event(event_id)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4',
 'CREATE TABLE IF NOT EXISTS mobile_chat (id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, user_id VARCHAR(80) NOT NULL, name VARCHAR(160) NOT NULL, sender VARCHAR(16) NOT NULL, message TEXT NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, INDEX idx_thread(user_id,id)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4',
 ];
 foreach($statements as $sql){try{$db->exec($sql);}catch(Throwable $e){error_log('mobile schema: '.$e->getMessage());mobile_error('Tabel API belum tersedia. Impor mobile-api/schema.sql ke database.',503);}}
 $done=true;
}
function mobile_body():array { $raw=file_get_contents('php://input');$v=json_decode($raw?:'{}',true);return is_array($v)?$v:[];}
function mobile_text($value,int $max=1000):string {$s=trim((string)$value);return function_exists('mb_substr')?mb_substr($s,0,$max):substr($s,0,$max);}
function mobile_strlen(string $s):int {return function_exists('mb_strlen')?mb_strlen($s):strlen($s);}
function mobile_auth(bool $required=true):?array {
 $header=$_SERVER['HTTP_AUTHORIZATION']??$_SERVER['REDIRECT_HTTP_AUTHORIZATION']??'';
 if(!preg_match('/^Bearer\s+([A-Za-z0-9_-]{40,128})$/',$header,$m)){if($required)mobile_error('Silakan login ulang',401);return null;}
 $hash=hash('sha256',$m[1]);$stmt=mobile_db()->prepare('SELECT user_id,username,user_role FROM mobile_tokens WHERE token_hash=? AND expires_at>NOW()');$stmt->execute([$hash]);$row=$stmt->fetch();if(!$row){if($required)mobile_error('Sesi tidak valid. Silakan login ulang.',401);return null;}
 if($row['user_role']!=='admin'){
  $active=false;foreach(db_read('portal_users') as $u){if(hash_equals((string)$u['id'],(string)$row['user_id']) && ($u['active']??false) && $row['user_role']===$u['role']){$active=true;break;}}
  if(!$active){if($required)mobile_error('Akun tidak aktif',403);return null;}
 }
 return $row;
}
function mobile_admin(array $u):void {if(!in_array($u['user_role'],['admin','admin_kelurahan'],true))mobile_error('Tidak memiliki hak akses',403);}
function mobile_file(string $field,bool $required=false):?string {
 if(!isset($_FILES[$field]) || ($_FILES[$field]['error']??4)===UPLOAD_ERR_NO_FILE){if($required)mobile_error('Foto wajib: '.$field,422);return null;}
 $f=$_FILES[$field];if(!is_array($f)||is_array($f['name'])||($f['error']??4)!==UPLOAD_ERR_OK || ($f['size']??0)>4*1024*1024)mobile_error('Foto harus JPG/PNG/WebP maksimal 4 MB',422);
 if(!is_uploaded_file($f['tmp_name']))mobile_error('File tidak valid',422);
 $mime=(new finfo(FILEINFO_MIME_TYPE))->file($f['tmp_name']);$ext=['image/jpeg'=>'jpg','image/png'=>'png','image/webp'=>'webp'][$mime]??null;if(!$ext)mobile_error('Foto harus JPG, PNG atau WebP',422);
 $dir=__DIR__.'/private';if(!is_dir($dir)&&!mkdir($dir,0750,true))mobile_error('Folder lampiran tidak tersedia',503);
 $name=bin2hex(random_bytes(20)).'.'.$ext;
 if(!move_uploaded_file($f['tmp_name'],$dir.'/'.$name))mobile_error('Foto gagal disimpan',503);
 return $name;
}
function mobile_emit(string $category,string $title,string $message,string $audience='public',?string $recipient=null):void {
 if(!in_array($audience,['public','staff','admin','personal'],true))return;
 try {$st=mobile_db()->prepare('INSERT INTO mobile_events(category,title,message,audience,recipient) VALUES(?,?,?,?,?)');$st->execute([$category,mobile_text($title,240),mobile_text($message,2000),$audience,$recipient]);}catch(Throwable $e){error_log('mobile event error: '.$e->getMessage());}
}
