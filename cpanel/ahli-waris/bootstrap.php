<?php
declare(strict_types=1);
if (session_status() !== PHP_SESSION_ACTIVE) session_start();
header('X-Content-Type-Options: nosniff');
header('Referrer-Policy: strict-origin-when-cross-origin');
function aw_e($v): string {return htmlspecialchars((string)$v,ENT_QUOTES|ENT_SUBSTITUTE,'UTF-8');}
function aw_cfg(): array {
 $path=__DIR__.'/config.php';
 if(!is_file($path)) throw new RuntimeException('Konfigurasi database belum tersedia.');
 $v=require $path; if(!is_array($v))throw new RuntimeException('Konfigurasi database salah.');return $v;
}
function aw_db(): PDO {static $pdo=null;if(!$pdo){$c=aw_cfg();$pdo=new PDO('mysql:host='.$c['host'].';port='.($c['port']??3306).';dbname='.$c['database'].';charset=utf8mb4',$c['username'],$c['password'],[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION,PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC,PDO::ATTR_EMULATE_PREPARES=>false]); aw_prepare_schema($pdo);}return $pdo;}
function aw_prepare_schema(PDO $db): void {
  $exists = $db->query("SHOW TABLES LIKE 'aw_applications'")->fetchColumn();
  if ($exists) {aw_ensure_extra_schema($db);return;}
  $sql = file_get_contents(__DIR__.'/../database/ahli_waris.sql');
  // Three CREATE TABLE statements, without client multi-statements.
  foreach (explode(';', preg_replace('/^--[^\n]*\n/m', '', $sql)) as $statement) {
    $statement=trim($statement);if($statement!=='')$db->exec($statement);
  }
  aw_ensure_extra_schema($db);
}

function aw_ensure_extra_schema(PDO $db): void {
 $cols=$db->query('SHOW COLUMNS FROM aw_applications')->fetchAll(PDO::FETCH_COLUMN);
 if(!in_array('deceased_marriage_date',$cols,true))$db->exec('ALTER TABLE aw_applications ADD COLUMN deceased_marriage_date DATE NULL AFTER deceased_birthdate');
 if(!in_array('children_json',$cols,true))$db->exec('ALTER TABLE aw_applications ADD COLUMN children_json LONGTEXT NULL AFTER heirs');
}
function aw_identity(): array {
 // Menyesuaikan portal login Cikoko lama: $_SESSION['portal_uid'], portal_role.
 if(!empty($_SESSION['portal_uid']) && !empty($_SESSION['portal_role'])) return ['id'=>(string)$_SESSION['portal_uid'],'role'=>(string)$_SESSION['portal_role'],'name'=>(string)($_SESSION['portal_name']??'')];
 if(!empty($_SESSION['admin']) && $_SESSION['admin']===true) return ['id'=>'administrator','role'=>'admin','name'=>'Admin Kelurahan'];
 if(isset($_SESSION['cikoko_user']) && is_array($_SESSION['cikoko_user']) && !empty($_SESSION['cikoko_user']['username'])) { $u=$_SESSION['cikoko_user'];return ['id'=>(string)$u['username'],'role'=>(string)($u['role']??''),'name'=>(string)($u['name']??'')]; }
 // Admin lama menggunakan session khusus; adaptasi via integrasi pada README.
 return ['id'=>'','role'=>'','name'=>''];
}
function aw_need_user(bool $admin=false): array {
 $u=aw_identity();$r=strtolower($u['role']);
 if(!$u['id'] || !$r){http_response_code(401);exit('Silakan login terlebih dahulu pada portal Cikoko.');}
 if($admin && !in_array($r,['admin','administrator'],true)){http_response_code(403);exit('Akses hanya untuk petugas berwenang.');}
 if(!$admin && $r!=='warga'){http_response_code(403);exit('Form khusus akun warga.');}return $u;
}
function aw_csrf():string {if(empty($_SESSION['aw_csrf']))$_SESSION['aw_csrf']=bin2hex(random_bytes(24));return $_SESSION['aw_csrf'];}
function aw_check():void {if(!hash_equals(aw_csrf(),(string)($_POST['csrf']??'')))throw new RuntimeException('Sesi formulir kedaluwarsa. Muat ulang halaman.');}
function aw_requirements(): array {return [
 ['r1','Surat Pengantar RT/RW','wajib',''],
 ['r2','Surat Permohonan','wajib',''],
 ['r3','Surat Pernyataan Keabsahan','wajib',''],
 ['r4','KTP, KK dan Akta Lahir Ahli Waris','wajib',''],
 ['r5','Surat Kematian Pewaris','wajib',''],
 ['r6','Surat Nikah Pewaris','wajib',''],
 ['r7','Akta Cerai (jika bercerai)','kondisional',''],
 ['r8','Surat Kematian Ahli Waris (jika ada yang meninggal)','kondisional',''],
];}
function aw_post($key,$max=200):string{return trim(mb_substr((string)($_POST[$key]??''),0,$max));}
function aw_files_list():array { $items=[]; foreach($_FILES as $field=>$f){ if(!is_array($f))continue;if(is_array($f['name'])){foreach($f['name'] as $i=>$name){if(($f['error'][$i]??UPLOAD_ERR_NO_FILE)===UPLOAD_ERR_NO_FILE)continue;$items[]=['field'=>$field,'name'=>$name,'tmp'=>$f['tmp_name'][$i],'error'=>$f['error'][$i],'size'=>$f['size'][$i]];}} else {if(($f['error']??UPLOAD_ERR_NO_FILE)===UPLOAD_ERR_NO_FILE)continue;$items[]=['field'=>$field,'name'=>$f['name'],'tmp'=>$f['tmp_name'],'error'=>$f['error'],'size'=>$f['size']];}}return $items; }
function aw_uploads_validate(array $items):void {if(count($items)>40)throw new RuntimeException('Maksimum 35 file.');$total=0;foreach($items as $f){if($f['error']!==UPLOAD_ERR_OK || $f['size']>10*1024*1024)throw new RuntimeException('Gagal unggah atau ukuran di atas 10MB: '.$f['name']);$total+=$f['size'];if($total>110*1024*1024)throw new RuntimeException('Ukuran total di atas 110MB.');$mime=(new finfo(FILEINFO_MIME_TYPE))->file($f['tmp']);if(!in_array($mime,['image/jpeg','image/png','image/webp'],true))throw new RuntimeException('Jenis file tidak didukung: '.$f['name']);if(!is_uploaded_file($f['tmp']))throw new RuntimeException('Unggahan tidak valid.');}}
