<?php
declare(strict_types=1);
ini_set('display_errors','0');
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
header('X-Content-Type-Options: nosniff');
require __DIR__.'/bootstrap.php';
require __DIR__.'/permissions.php';
$action=(string)($_GET['action']??'');
$method=(string)($_SERVER['REQUEST_METHOD']??'GET');
$defaults=[
 ['slug'=>'eco-edu-wisata-ciliwung','title'=>'ECO EDU WISATA CILIWUNG','summary'=>'Edukasi lingkungan dan wisata berbasis masyarakat di bantaran Sungai Ciliwung.','body'=>'Program pengembangan edukasi lingkungan dan pemberdayaan masyarakat di kawasan Ciliwung.','image'=>''],
 ['slug'=>'cikoko-bio-farm-education','title'=>'CIKOKO BIO FARM EDUCATION','summary'=>'Edukasi pertanian perkotaan untuk lingkungan yang sehat dan mandiri.','body'=>'Program edukasi budidaya tanaman dan pengelolaan lingkungan di wilayah Kelurahan Cikoko.','image'=>''],
 ['slug'=>'kampung-inggris','title'=>'KAMPUNG INGGRIS','summary'=>'Pengembangan kemampuan bahasa Inggris anak dan remaja di wilayah Cikoko.','body'=>'Program pembelajaran bahasa Inggris berbasis komunitas untuk masyarakat Cikoko.','image'=>'']
];
function v211_innovations():array {global $defaults;$saved=db_read('cikoko_innovations');$by=[];foreach($saved as $row)if(is_array($row)&&isset($row['slug']))$by[(string)$row['slug']]=$row;return array_map(static fn($r)=>array_merge($r,$by[$r['slug']]??[]),$defaults);}
function v211_mustpost(string $method):void {if($method!=='POST')mobile_error('Metode tidak diperbolehkan',405);}
function v211_login():array {return mobile_auth(true);}
function v211_userrow(string $uid):?array {foreach(db_read('portal_users') as $entry)if((string)($entry['id']??'')===$uid)return $entry;return null;}
function v211_saveuser(string $uid,array $changes):array {
 $users=db_read('portal_users');$found=null;
 foreach($users as &$entry)if((string)($entry['id']??'')===$uid){foreach($changes as $k=>$v)$entry[$k]=$v;$found=$entry;break;}unset($entry);
 if(!$found)mobile_error('Akun tidak ditemukan',404);
 if(!db_write('portal_users',$users))mobile_error('Perubahan profil belum berhasil disimpan',503);
 return $found;
}
function v211_archive_tables(PDO $db):void {
 $db->exec('CREATE TABLE IF NOT EXISTS aw_archives (id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, archive_year SMALLINT UNSIGNED NOT NULL, reference_no VARCHAR(100) NOT NULL, applicant_name VARCHAR(200) NOT NULL, deceased_name VARCHAR(200) NOT NULL, notes TEXT, attachment VARCHAR(120) NULL, created_by VARCHAR(100) NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, INDEX idx_year(archive_year)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
 $db->exec('CREATE TABLE IF NOT EXISTS aw_archive_details (archive_id BIGINT UNSIGNED PRIMARY KEY, details_json LONGTEXT NULL, files_json LONGTEXT NULL, updated_by VARCHAR(80) NOT NULL, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
}
function v211_ppsu_table(PDO $db):void {
 $db->exec('CREATE TABLE IF NOT EXISTS mobile_ppsu_reports (id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,user_id VARCHAR(80) NOT NULL,name VARCHAR(180) NOT NULL,team VARCHAR(30) NOT NULL,work_date DATE NOT NULL,activity TEXT NOT NULL,photos_json LONGTEXT NOT NULL,created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,INDEX idx_user(user_id),INDEX idx_date(work_date)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
}
function v211_news_table(PDO $db):void {
 $db->exec('CREATE TABLE IF NOT EXISTS mobile_news_comments(id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,news_id VARCHAR(80) NOT NULL,user_id VARCHAR(80) NOT NULL,display_name VARCHAR(160) NOT NULL,parent_id BIGINT UNSIGNED NULL,body TEXT NOT NULL,hidden TINYINT(1) NOT NULL DEFAULT 0,created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,INDEX idx_news(news_id,id),INDEX idx_user(user_id)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
}
function v211_find_news(string $id):?array {foreach(db_read('content') as $row)if(($row['id']??'')===$id && ($row['type']??'')==='berita')return $row;return null;}
try {
 if($action==='v211_innovations')mobile_json(['ok'=>true,'items'=>v211_innovations()]);
 if($action==='v211_news_detail'){
  $id=mobile_text($_GET['id']??'',80);$n=v211_find_news($id);if(!$n)mobile_error('Berita tidak ditemukan',404);
  $images=array_values(array_filter($n['images']??[], 'is_string'));if(!$images&&!empty($n['image']))$images=[(string)$n['image']];
  mobile_json(['ok'=>true,'item'=>['id'=>$id,'title'=>$n['title']??'','body'=>$n['body']??'','images'=>array_slice($images,0,5),'created_at'=>$n['created_at']??'']]);
 }
 if($action==='v211_comments'){
  $id=mobile_text($_GET['id']??'',80);if(!v211_find_news($id))mobile_error('Berita tidak ditemukan',404);
  $db=mobile_db();v211_news_table($db);$st=$db->prepare('SELECT id,display_name,parent_id,body,created_at FROM mobile_news_comments WHERE news_id=? AND hidden=0 ORDER BY id DESC LIMIT 100');$st->execute([$id]);mobile_json(['ok'=>true,'items'=>array_reverse($st->fetchAll())]);
 }
 $u=v211_login();$uid=(string)$u['user_id'];$db=mobile_db();
 if($action==='v211_innovations_update'){
  v211_mustpost($method);if($u['user_role']!=='admin')mobile_error('Hanya Admin Utama yang dapat mengubah inovasi',403);
  $b=mobile_body();$slug=mobile_text($b['slug']??'',80);$allowed=array_column($defaults,'slug');if(!in_array($slug,$allowed,true))mobile_error('Inovasi tidak dikenal',422);
  $rows=v211_innovations();foreach($rows as &$row)if($row['slug']===$slug){foreach(['title'=>160,'summary'=>500,'body'=>8000,'image'=>255] as $key=>$max){if(isset($b[$key]))$row[$key]=mobile_text($b[$key],$max);}break;}unset($row);
  if(!db_write('cikoko_innovations',$rows))mobile_error('Informasi inovasi belum dapat disimpan',503);
  mobile_emit('pengumuman','Informasi inovasi diperbarui','Informasi program unggulan Kelurahan Cikoko telah diperbarui.');mobile_json(['ok'=>true]);
 }
 if($action==='v211_profile'){
  $row=v211_userrow($uid);
  if(!$row)mobile_json(['ok'=>true,'user'=>['name'=>'Administrator','username'=>$u['username'],'email'=>'','phone'=>'','address'=>'','nik'=>'','has_photo'=>false]]);
  mobile_json(['ok'=>true,'user'=>['name'=>$row['name']??'','username'=>$row['username']??'','email'=>$row['email']??'','phone'=>$row['phone']??'','address'=>$row['address']??'','nik'=>$row['nik']??'','has_photo'=>!empty($row['photo_name'])]]);
 }
 if($action==='v211_profile_update'){
  v211_mustpost($method);$row=v211_userrow($uid);if(!$row)mobile_error('Profil administrator utama dikelola terpisah',403);
  $b=mobile_body();$changes=[];foreach(['name'=>150,'phone'=>30,'email'=>180,'address'=>900,'nik'=>16] as $key=>$len)$changes[$key]=mobile_text($b[$key]??($row[$key]??''),$len);
  if(mobile_strlen($changes['name'])<3||!preg_match('/^[0-9+() -]{8,30}$/',$changes['phone'])||!filter_var($changes['email'],FILTER_VALIDATE_EMAIL)||$changes['address']==='')mobile_error('Mohon lengkapi nama, telepon, alamat dan email yang valid.',422);
  if($changes['nik']!==''&&!preg_match('/^[0-9]{16}$/',$changes['nik']))mobile_error('NIK harus berjumlah 16 angka.',422);
  v211_saveuser($uid,$changes);mobile_json(['ok'=>true,'message'=>'Profil berhasil diperbarui']);
 }
 if($action==='v211_profile_upload'){
  v211_mustpost($method);$row=v211_userrow($uid);if(!$row)mobile_error('Foto profil administrator utama dikelola terpisah',403);
  $file=mobile_file('photo',true);v211_saveuser($uid,['photo_name'=>$file]);
  if(!empty($row['photo_name'])){ $old=basename((string)$row['photo_name']);if($old===$row['photo_name'])@unlink(__DIR__.'/private/'.$old); }
  mobile_json(['ok'=>true,'message'=>'Foto profil berhasil diperbarui']);
 }
 if($action==='v211_profile_photo'){
  $row=v211_userrow($uid);$name=(string)($row['photo_name']??'');
  if(!$name||basename($name)!==$name||!is_file(__DIR__.'/private/'.$name))mobile_error('Foto profil belum tersedia',404);
  $full=__DIR__.'/private/'.$name;$mime=(new finfo(FILEINFO_MIME_TYPE))->file($full);
  if(!in_array($mime,['image/jpeg','image/png','image/webp'],true))mobile_error('Foto tidak tersedia',404);
  header('Content-Type: '.$mime);header('Content-Length: '.filesize($full));readfile($full);exit;
 }
 if($action==='v211_news_upload'){
  v211_mustpost($method);mobile_need($u,'content:create');$id=mobile_text($_POST['id']??'',80);$rows=db_read('content');$index=null;
  foreach($rows as $i=>$r)if(($r['id']??'')===$id&&($r['type']??'')==='berita'){$index=$i;break;}
  if($index===null)mobile_error('Berita belum ditemukan. Simpan naskah terlebih dahulu.',404);
  $images=array_values(array_filter($rows[$index]['images']??[],'is_string'));if(!$images&&!empty($rows[$index]['image']))$images=[(string)$rows[$index]['image']];
  if(count($images)>=5)mobile_error('Maksimal lima foto untuk satu berita.',422);
  if(!isset($_FILES['photo'])||!is_uploaded_file($_FILES['photo']['tmp_name']))mobile_error('Silakan pilih foto.',422);
  $f=$_FILES['photo'];$mime=(new finfo(FILEINFO_MIME_TYPE))->file($f['tmp_name']);$ext=['image/jpeg'=>'jpg','image/png'=>'png','image/webp'=>'webp'][$mime]??null;
  if(!$ext||($f['size']??0)>4*1024*1024||($f['error']??4)!==UPLOAD_ERR_OK)mobile_error('Foto harus JPG, PNG atau WebP maksimal 4 MB.',422);
  $dir=dirname(__DIR__).'/assets/images';if(!is_dir($dir)&&!mkdir($dir,0755,true))mobile_error('Penyimpanan foto belum tersedia',503);
  $path='assets/images/berita-'.bin2hex(random_bytes(16)).'.'.$ext;
  if(!move_uploaded_file($f['tmp_name'],dirname(__DIR__).'/'.$path))mobile_error('Foto belum berhasil disimpan',503);
  $images[]=$path;$rows[$index]['images']=$images;$rows[$index]['image']=$images[0];
  if(!db_write('content',$rows)){@unlink(dirname(__DIR__).'/'.$path);mobile_error('Foto belum dapat disimpan pada berita',503);}
  mobile_json(['ok'=>true,'images'=>$images]);
 }
 if($action==='v211_comment_add'){
  v211_mustpost($method);$b=mobile_body();$id=mobile_text($b['news_id']??'',80);if(!v211_find_news($id))mobile_error('Berita tidak ditemukan',404);
  $body=mobile_text($b['body']??'',1200);if(mobile_strlen($body)<2||mobile_strlen($body)>1200)mobile_error('Komentar harus berisi 2–1200 karakter.',422);
  if(preg_match('/\b(anjing|bangsat|kontol|memek|tolol|goblok|bajingan)\b/ui',$body))mobile_error('Mohon gunakan bahasa yang santun dan sesuai ketentuan layanan.',422);
  v211_news_table($db);$last=$db->prepare('SELECT created_at FROM mobile_news_comments WHERE user_id=? ORDER BY id DESC LIMIT 1');$last->execute([$uid]);$lastValue=$last->fetchColumn();if($lastValue && strtotime((string)$lastValue)>time()-8)mobile_error('Mohon beri jeda sebelum mengirim komentar berikutnya.',429);
  $parent=(int)($b['parent_id']??0);if($parent>0){$s=$db->prepare('SELECT id FROM mobile_news_comments WHERE id=? AND news_id=? AND hidden=0');$s->execute([$parent,$id]);if(!$s->fetch())mobile_error('Komentar yang dibalas tidak tersedia.',404);}
  $name=(string)(v211_userrow($uid)['name']??$u['username']);$db->prepare('INSERT INTO mobile_news_comments(news_id,user_id,display_name,parent_id,body) VALUES(?,?,?,?,?)')->execute([$id,$uid,$name,$parent?:null,$body]);mobile_json(['ok'=>true]);
 }
 if($action==='v211_comment_moderate'){
  v211_mustpost($method);if(!in_array($u['user_role'],['admin','admin_kelurahan'],true))mobile_error('Tidak memiliki izin moderasi.',403);
  $b=mobile_body();v211_news_table($db);$stmt=$db->prepare('UPDATE mobile_news_comments SET hidden=1 WHERE id=?');$stmt->execute([(int)($b['id']??0)]);mobile_json(['ok'=>true]);
 }
 if($action==='v211_ppsu_submit'){
  v211_mustpost($method);if($u['user_role']!=='ppsu'&&!mobile_can($u,'role:manage'))mobile_error('Pengajuan laporan PPSU hanya untuk petugas berwenang.',403);
  $team=mobile_text($_POST['team']??'',30);$date=mobile_text($_POST['work_date']??'',10);$activity=mobile_text($_POST['activity']??'',3500);$name=mobile_text((v211_userrow($uid)['name']??$u['username']),180);
  if(!in_array($team,['Jalur','Hilux','Penataan','Taman'],true)||!preg_match('/^\d{4}-\d{2}-\d{2}$/',$date)||!checkdate((int)substr($date,5,2),(int)substr($date,8,2),(int)substr($date,0,4))||mobile_strlen($activity)<5||$name==='')mobile_error('Mohon lengkapi tanggal, nama, tim, dan kegiatan.',422);
  v211_ppsu_table($db);$photos=[];
  try {foreach(['photo1','photo2','photo3'] as $key)$photos[] = mobile_file($key,true);
   $stmt=$db->prepare('INSERT INTO mobile_ppsu_reports(user_id,name,team,work_date,activity,photos_json) VALUES(?,?,?,?,?,?)');$stmt->execute([$uid,$name,$team,$date,$activity,json_encode($photos)]);
  }catch(Throwable $e){foreach($photos as $p)@unlink(__DIR__.'/private/'.$p);throw $e;}
  $id=(int)$db->lastInsertId();mobile_emit('laporan_masuk','Laporan PPSU diterima','Laporan kegiatan PPSU telah diterima petugas verifikasi.','admin');mobile_json(['ok'=>true,'id'=>$id,'message'=>'Laporan PPSU berhasil dikirim']);
 }
 if($action==='v211_ppsu_list'){
  v211_ppsu_table($db);$mine=!mobile_can($u,'reports:view');$st=$db->prepare('SELECT id,name,team,work_date,activity,created_at FROM mobile_ppsu_reports'.($mine?' WHERE user_id=?':'').' ORDER BY id DESC LIMIT 100');$st->execute($mine?[$uid]:[]);
  mobile_json(['ok'=>true,'items'=>$st->fetchAll()]);
 }
 if($action==='v211_ppsu_detail'){
  v211_ppsu_table($db);$id=(int)($_GET['id']??0);$st=$db->prepare('SELECT * FROM mobile_ppsu_reports WHERE id=?');$st->execute([$id]);$row=$st->fetch();if(!$row)mobile_error('Laporan tidak ditemukan',404);
  if((string)$row['user_id']!==$uid&&!mobile_can($u,'reports:view'))mobile_error('Tidak memiliki izin melihat laporan tersebut',403);
  $row['photos']=json_decode($row['photos_json'],true)?:[];unset($row['photos_json']);mobile_json(['ok'=>true,'item'=>$row]);
 }
 if($action==='v211_ppsu_photo'){
  v211_ppsu_table($db);$id=(int)($_GET['id']??0);$i=(int)($_GET['index']??0);$st=$db->prepare('SELECT user_id,photos_json FROM mobile_ppsu_reports WHERE id=?');$st->execute([$id]);$row=$st->fetch();if(!$row||((string)$row['user_id']!==$uid&&!mobile_can($u,'reports:view')))mobile_error('Foto laporan tidak tersedia',404);
  $photos=json_decode($row['photos_json'],true)?:[];$name=(string)($photos[$i]??'');if(!$name||basename($name)!==$name||!is_file(__DIR__.'/private/'.$name))mobile_error('Foto belum tersedia',404);
  $file=__DIR__.'/private/'.$name;$mime=(new finfo(FILEINFO_MIME_TYPE))->file($file);if(!in_array($mime,['image/jpeg','image/png','image/webp'],true))mobile_error('Foto tidak tersedia',404);
  header('Content-Type: '.$mime);header('Content-Length: '.filesize($file));readfile($file);exit;
 }
 if($action==='v211_archive_save'){
  v211_mustpost($method);mobile_need($u,'archive:create');v211_archive_tables($db);
  $post=$_POST; if(!$post){$post=mobile_body();}
  $year=(int)($post['archive_year']??0);$ref=mobile_text($post['reference_no']??'',100);$app=mobile_text($post['name']??'',180);$dead=mobile_text($post['deceased_name']??'',180);$id=(int)($post['id']??0);
  if($year<1900||$year>(int)date('Y')||$ref===''||$app===''||$dead==='')mobile_error('Nomor surat, tahun, pemohon dan pewaris wajib diisi.',422);
  $details=[];foreach(['nik','phone','address','relation','birthplace','birthdate','marriage_date','deathdate','marital_status','heirs'] as $key)$details[$key]=mobile_text($post[$key]??'', $key==='heirs'?12000:2500);
  if(isset($post['children_json'])){$children=json_decode((string)$post['children_json'],true);$details['children']=is_array($children)?array_slice($children,0,10):[];}
  $newFiles=[];$files=[];if($id>0){$st=$db->prepare('SELECT files_json FROM aw_archive_details WHERE archive_id=?');$st->execute([$id]);$old=$st->fetchColumn();$files=$old?json_decode($old,true)?:[]:[];}
  try {
   foreach(array_merge(array_map(fn($i)=>'r'.$i,range(1,8)),array_map(fn($i)=>'child_'.$i,range(1,10))) as $key){if(isset($_FILES[$key])&&($_FILES[$key]['error']??4)===UPLOAD_ERR_OK){$file=mobile_file($key,true);$newFiles[]=$file;$files[$key]=$file;}}
   $db->beginTransaction();
   if($id){$check=$db->prepare('SELECT id FROM aw_archives WHERE id=? FOR UPDATE');$check->execute([$id]);if(!$check->fetch())throw new RuntimeException('Arsip tidak ditemukan');$db->prepare('UPDATE aw_archives SET archive_year=?,reference_no=?,applicant_name=?,deceased_name=?,notes=? WHERE id=?')->execute([$year,$ref,$app,$dead,mobile_text($post['notes']??'',5000),$id]);}
   else{$st=$db->prepare('INSERT INTO aw_archives(archive_year,reference_no,applicant_name,deceased_name,notes,created_by) VALUES(?,?,?,?,?,?)');$st->execute([$year,$ref,$app,$dead,mobile_text($post['notes']??'',5000),$uid]);$id=(int)$db->lastInsertId();}
   $db->prepare('INSERT INTO aw_archive_details(archive_id,details_json,files_json,updated_by) VALUES(?,?,?,?) ON DUPLICATE KEY UPDATE details_json=VALUES(details_json),files_json=VALUES(files_json),updated_by=VALUES(updated_by)')->execute([$id,json_encode($details,JSON_UNESCAPED_UNICODE),json_encode($files),$uid]);
   $db->commit();
  } catch(Throwable $e){if($db->inTransaction())$db->rollBack();foreach($newFiles as $file)@unlink(__DIR__.'/private/'.$file);throw $e;}
  mobile_json(['ok'=>true,'id'=>$id,'message'=>'Arsip Ahli Waris telah disimpan']);
 }
 if($action==='v211_archive_detail'){
  mobile_need($u,'archive:view');v211_archive_tables($db);$id=(int)($_GET['id']??0);$st=$db->prepare('SELECT a.*,d.details_json,d.files_json FROM aw_archives a LEFT JOIN aw_archive_details d ON a.id=d.archive_id WHERE a.id=?');$st->execute([$id]);$r=$st->fetch();if(!$r)mobile_error('Arsip tidak ditemukan',404);$r['details']=json_decode($r['details_json']??'{}',true)?:[];$r['files']=array_keys(json_decode($r['files_json']??'{}',true)?:[]);unset($r['details_json'],$r['files_json']);mobile_json(['ok'=>true,'item'=>$r]);
 }
 if($action==='v211_archive_file'){
  mobile_need($u,'archive:view');v211_archive_tables($db);$id=(int)($_GET['id']??0);$key=mobile_text($_GET['key']??'',20);$st=$db->prepare('SELECT files_json FROM aw_archive_details WHERE archive_id=?');$st->execute([$id]);$f=json_decode($st->fetchColumn()?:'{}',true)?:[];$name=(string)($f[$key]??'');if(!$name||basename($name)!==$name||!is_file(__DIR__.'/private/'.$name))mobile_error('Lampiran tidak tersedia',404);$path=__DIR__.'/private/'.$name;$mime=(new finfo(FILEINFO_MIME_TYPE))->file($path);header('Content-Type: '.$mime);header('Content-Length: '.filesize($path));readfile($path);exit;
 }
 mobile_error('Layanan yang diminta belum tersedia.',404);
} catch(Throwable $e) {error_log('Cikoko v211: '.$e->getMessage());mobile_error('Layanan sedang mengalami kendala. Silakan mencoba kembali atau hubungi petugas.',503);}
