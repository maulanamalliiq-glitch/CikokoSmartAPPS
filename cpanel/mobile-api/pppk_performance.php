<?php
declare(strict_types=1);
/** Isolated PPPK monthly performance API. All actions require mobile bearer auth. */
function pppk_schema(PDO $db):void {
 $db->exec("CREATE TABLE IF NOT EXISTS pppk_monthly_reports (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 user_id VARCHAR(80) NOT NULL, report_month CHAR(7) NOT NULL,
 employee_name VARCHAR(160) NOT NULL, employee_nip VARCHAR(50) NOT NULL DEFAULT '',
 payload_json LONGTEXT NOT NULL,
 status VARCHAR(20) NOT NULL DEFAULT 'draft',
 submitted_at DATETIME NULL, reviewed_at DATETIME NULL,
 reviewer_id VARCHAR(80) NULL, review_note TEXT NULL,
 approved_token CHAR(48) NULL,
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 UNIQUE KEY uq_pppk_user_month(user_id,report_month), INDEX idx_status(status,report_month),
 UNIQUE KEY uq_approved_token(approved_token)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
 $db->exec("CREATE TABLE IF NOT EXISTS pppk_monthly_photos (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, report_id BIGINT UNSIGNED NOT NULL,
 section_no TINYINT UNSIGNED NOT NULL, period_no TINYINT UNSIGNED NOT NULL,
 file_name VARCHAR(80) NOT NULL,
 UNIQUE KEY uq_photo_slot(report_id,section_no,period_no)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
}
function pppk_row(PDO $db,int $id):array {
 $s=$db->prepare('SELECT * FROM pppk_monthly_reports WHERE id=?');$s->execute([$id]);
 return $s->fetch(PDO::FETCH_ASSOC)?:[];
}
function pppk_access(array $r,array $actor,bool $admin):void {
 if(!$r||(!$admin&&(string)$r['user_id']!==(string)$actor['user_id']))mobile_error('Laporan tidak ditemukan',404);
}
function pppk_dispatch(string $action,string $method):void {
 $actor=mobile_auth();$role=(string)$actor['user_role'];$admin=in_array($role,['admin','admin_kelurahan'],true);
 if(!$admin&&$role!=='pppk')mobile_error('Hanya akun PPPK dan Admin',403);
 $db=mobile_db();pppk_schema($db);$uid=(string)$actor['user_id'];
 if($action==='pppk_list'&&$method==='GET'){
  $sql='SELECT id,user_id,employee_name,employee_nip,report_month,status,submitted_at,reviewed_at,review_note FROM pppk_monthly_reports';
  $sql.=$admin?' ORDER BY report_month DESC,id DESC LIMIT 250':' WHERE user_id=? ORDER BY report_month DESC LIMIT 60';
  $s=$db->prepare($sql);$s->execute($admin?[]:[$uid]);mobile_json(['ok'=>true,'items'=>$s->fetchAll(PDO::FETCH_ASSOC)]);
 }
 if($action==='pppk_detail'&&$method==='GET'){
  $r=pppk_row($db,(int)($_GET['id']??0));pppk_access($r,$actor,$admin);
  $s=$db->prepare('SELECT section_no,period_no FROM pppk_monthly_photos WHERE report_id=?');$s->execute([$r['id']]);
  mobile_json(['ok'=>true,'report'=>['id'=>(int)$r['id'],'user_id'=>$r['user_id'],'employee_name'=>$r['employee_name'],'employee_nip'=>$r['employee_nip'],'month'=>$r['report_month'],'status'=>$r['status'],'note'=>$r['review_note'],'approved_token'=>$r['status']==='approved'?$r['approved_token']:null,'payload'=>json_decode($r['payload_json'],true)?:[],'photos'=>$s->fetchAll(PDO::FETCH_ASSOC)]]);
 }
 if($action==='pppk_photo'&&$method==='GET'){
  $r=pppk_row($db,(int)($_GET['id']??0));pppk_access($r,$actor,$admin);
  $section=(int)($_GET['section']??0);$period=(int)($_GET['period']??0);
  $s=$db->prepare('SELECT file_name FROM pppk_monthly_photos WHERE report_id=? AND section_no=? AND period_no=?');
  $s->execute([$r['id'],$section,$period]);$name=(string)($s->fetchColumn()?:'');
  if(!preg_match('/^[a-f0-9]{32}\\.jpg$/D',$name))mobile_error('Foto tidak ditemukan',404);
  $path=__DIR__.'/private/pppk/'.$name;
  if(!is_file($path))mobile_error('Foto tidak ditemukan',404);
  header('Content-Type: image/jpeg');header('Cache-Control: private, no-store');readfile($path);exit;
 }
 if($action==='pppk_save'&&$method==='POST'){
  if($admin)mobile_error('Hanya PPPK yang mengisi laporan',403);
  $v=mobile_body();$month=(string)($v['month']??'');
  if(!preg_match('/^20[2-9][0-9]-(0[1-9]|1[0-2])$/D',$month))mobile_error('Bulan laporan tidak valid');
  $parts=$v['sections']??null;
  if(!is_array($parts)||count($parts)!==4)mobile_error('Harus ada empat kelompok kegiatan');
  $clean=[];
  foreach($parts as $item){
   if(!is_array($item)||!isset($item['period1'],$item['period2']))mobile_error('Setiap kegiatan harus mempunyai dua periode');
   $clean[]=['period1'=>mb_substr(trim((string)$item['period1']),0,700),'period2'=>mb_substr(trim((string)$item['period2']),0,700)];
  }
  $name=mb_substr(trim((string)($v['name']??'')),0,160);$nip=mb_substr(trim((string)($v['nip']??'')),0,50);
  if($name==='')mobile_error('Nama pegawai wajib diisi');
  $s=$db->prepare("INSERT INTO pppk_monthly_reports(user_id,report_month,employee_name,employee_nip,payload_json)
  VALUES(?,?,?,?,?) ON DUPLICATE KEY UPDATE
  employee_name=IF(status IN ('draft','rejected'),VALUES(employee_name),employee_name),
  employee_nip=IF(status IN ('draft','rejected'),VALUES(employee_nip),employee_nip),
  payload_json=IF(status IN ('draft','rejected'),VALUES(payload_json),payload_json)");
  $s->execute([$uid,$month,$name,$nip,json_encode($clean,JSON_UNESCAPED_UNICODE)]);
  $q=$db->prepare('SELECT id,status FROM pppk_monthly_reports WHERE user_id=? AND report_month=?');$q->execute([$uid,$month]);$row=$q->fetch(PDO::FETCH_ASSOC);
  if(!in_array($row['status'],['draft','rejected'],true))mobile_error('Laporan sudah dikirim atau disetujui; tidak dapat diedit',409);
  mobile_json(['ok'=>true,'id'=>(int)$row['id']]);
 }
 if($action==='pppk_upload'&&$method==='POST'){
  if($admin)mobile_error('Hanya PPPK dapat mengunggah foto',403);
  $v=mobile_body();$id=(int)($v['id']??0);$r=pppk_row($db,$id);pppk_access($r,$actor,false);
  if(!in_array($r['status'],['draft','rejected'],true))mobile_error('Laporan terkunci',409);
  $section=(int)($v['section']??0);$period=(int)($v['period']??0);
  if($section<1||$section>4||$period<1||$period>2)mobile_error('Posisi foto tidak valid');
  $raw=(string)($v['image_base64']??'');
  if(strlen($raw)>5500000)mobile_error('Foto terlalu besar, maksimal 4 MB');
  $bytes=base64_decode($raw,true);if($bytes===false||strlen($bytes)>4000000)mobile_error('Foto tidak valid');
  $im=@imagecreatefromstring($bytes);if(!$im)mobile_error('Gunakan foto JPG atau PNG');
  $w=imagesx($im);$h=imagesy($im);
  if($w<1||$h<1||$w>6000||$h>6000){imagedestroy($im);mobile_error('Resolusi foto tidak valid');}
  $dir=__DIR__.'/private/pppk';if(!is_dir($dir)&&!mkdir($dir,0750,true))mobile_error('Folder foto belum tersedia',503);
  $name=bin2hex(random_bytes(16)).'.jpg';$path=$dir.'/'.$name;
  if(!imagejpeg($im,$path,82)){imagedestroy($im);mobile_error('Foto gagal disimpan',503);}imagedestroy($im);
  $q=$db->prepare('SELECT file_name FROM pppk_monthly_photos WHERE report_id=? AND section_no=? AND period_no=?');
  $q->execute([$id,$section,$period]);$old=$q->fetchColumn();
  $q=$db->prepare('INSERT INTO pppk_monthly_photos(report_id,section_no,period_no,file_name) VALUES(?,?,?,?) ON DUPLICATE KEY UPDATE file_name=VALUES(file_name)');
  $q->execute([$id,$section,$period,$name]);
  if($old&&preg_match('/^[a-f0-9]{32}\\.jpg$/D',(string)$old))@unlink($dir.'/'.$old);
  mobile_json(['ok'=>true]);
 }
 if($action==='pppk_submit'&&$method==='POST'){
  if($admin)mobile_error('Hanya PPPK yang mengirim laporan',403);
  $id=(int)(mobile_body()['id']??0);$r=pppk_row($db,$id);pppk_access($r,$actor,false);
  if(!in_array($r['status'],['draft','rejected'],true))mobile_error('Laporan sudah dikirim',409);
  $q=$db->prepare("UPDATE pppk_monthly_reports SET status='pending_admin',submitted_at=NOW(),reviewed_at=NULL,reviewer_id=NULL,review_note=NULL,approved_token=NULL WHERE id=?");
  $q->execute([$id]);mobile_json(['ok'=>true]);
 }
 if($action==='pppk_review'&&$method==='POST'){
  if(!$admin)mobile_error('Hanya Admin yang menyetujui',403);
  $v=mobile_body();$id=(int)($v['id']??0);$decision=(string)($v['decision']??'');
  if(!in_array($decision,['approved','rejected'],true))mobile_error('Keputusan tidak valid');
  $r=pppk_row($db,$id);if(!$r||$r['status']!=='pending_admin')mobile_error('Laporan tidak dalam antrean',409);
  $note=mb_substr(trim((string)($v['note']??'')),0,1000);
  if($decision==='rejected'&&$note==='')mobile_error('Alasan penolakan wajib diisi');
  $token=$decision==='approved'?bin2hex(random_bytes(24)):null;
  $s=$db->prepare("UPDATE pppk_monthly_reports SET status=?,reviewed_at=NOW(),reviewer_id=?,review_note=?,approved_token=? WHERE id=? AND status='pending_admin'");
  $s->execute([$decision,$uid,$note,$token,$id]);mobile_json(['ok'=>true]);
 }
 mobile_error('Aksi kinerja PPPK tidak tersedia',404);
}
