<?php
declare(strict_types=1);
// API responses must always be JSON, including dependency/runtime failures.
ini_set('display_errors','0');
error_reporting(E_ALL);
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
header('X-Content-Type-Options: nosniff');
set_exception_handler(static function(Throwable $exception):void {
    error_log('[Cikoko mobile-api v205] '.$exception->getMessage().' at '.$exception->getFile().':'.$exception->getLine());
    if(!headers_sent()){http_response_code(503);header('Content-Type: application/json; charset=utf-8');}
    echo json_encode(['ok'=>false,'error'=>'Server API belum siap. Periksa error_log PHP atau konfigurasi database.'],JSON_UNESCAPED_UNICODE);
});
$action=(string)($_GET['action']??'');
$method=(string)($_SERVER['REQUEST_METHOD']??'GET');
if($action==='health'){
    $files=[
        'website_lib'=>is_file(dirname(__DIR__).'/lib.php'),
        'roles_lib'=>is_file(dirname(__DIR__).'/roles-lib.php'),
        'api_bootstrap'=>is_file(__DIR__.'/bootstrap.php'),
        'api_permissions'=>is_file(__DIR__.'/permissions.php'),
        'db_config'=>is_file(dirname(__DIR__).'/ahli-waris/config.php'),
    ];
    $ready=!in_array(false,$files,true);
    http_response_code($ready?200:503);
    echo json_encode(['ok'=>$ready,'service'=>'Cikoko API','version'=>'205.1','ready'=>$ready,
        'checks'=>$files,'message'=>$ready?'Berkas API terpasang. Koneksi database belum diuji.':'Ada dependensi API yang belum terpasang.'],JSON_UNESCAPED_UNICODE);
    exit;
}
require __DIR__.'/bootstrap.php';
require __DIR__.'/permissions.php';

if($action==='login'&&$method==='POST'){
 $body=mobile_body();$username=mobile_text($body['username']??'',100);$pass=(string)($body['password']??'');$found=null;
 $a=db_read('admin');if($username!==''&&hash_equals((string)($a['username']??''),$username) && password_verify($pass,(string)($a['password_hash']??''))){$found=['id'=>'admin','name'=>'Administrator','username'=>$username,'role'=>'admin'];}
 if(!$found)foreach(db_read('portal_users') as $u){if(hash_equals((string)($u['username']??''),$username)&&($u['active']??false)&&password_verify($pass,(string)($u['password_hash']??''))){$found=['id'=>$u['id'],'name'=>$u['name'],'username'=>$u['username'],'role'=>$u['role'],'department'=>$u['department']??''];break;}}
 if(!$found)mobile_error('Username, password, atau status akun tidak sesuai',401);
 $token=rtrim(strtr(base64_encode(random_bytes(48)),'+/','-_'),'=');$st=mobile_db()->prepare('INSERT INTO mobile_tokens(token_hash,user_id,username,user_role,expires_at) VALUES(?,?,?,?,DATE_ADD(NOW(),INTERVAL 30 DAY))');$st->execute([hash('sha256',$token),$found['id'],$found['username'],$found['role']]);mobile_json(['ok'=>true,'token'=>$token,'user'=>$found]);
}
if($action==='register'&&$method==='POST'){
 $b=mobile_body();$name=mobile_text($b['name']??'',120);$username=mobile_text($b['username']??'',80);$pass=(string)($b['password']??'');$confirm=(string)($b['confirm']??'');$address=mobile_text($b['address']??'',600);$phone=mobile_text($b['phone']??'',40);$email=mobile_text($b['email']??'',160);
 if($pass===''||$pass!==$confirm)mobile_error('Konfirmasi password tidak sama atau kosong',422);
 if(mobile_strlen($name)<3 || !preg_match('/^[a-zA-Z0-9_.-]{4,40}$/',$username)||!preg_match('/^[0-9+ -]{8,20}$/',$phone)||$address===''||!filter_var($email,FILTER_VALIDATE_EMAIL))mobile_error('Periksa nama, username, alamat, nomor telepon dan email',422);
 $users=db_read('portal_users');$a=db_read('admin');$taken=strcasecmp((string)($a['username']??''),$username)===0;foreach($users as $v)if(strcasecmp((string)($v['username']??''),$username)===0)$taken=true;
 if($taken)mobile_error('Username sudah digunakan',409);
 $users[]=['id'=>bin2hex(random_bytes(12)),'name'=>$name,'username'=>$username,'password_hash'=>password_hash($pass,PASSWORD_DEFAULT),'role'=>'warga','department'=>'Warga','address'=>$address,'phone'=>$phone,'email'=>$email,'active'=>true,'created_at'=>date('c')];
 if(!db_write('portal_users',$users))mobile_error('Data akun gagal disimpan',503);
 mobile_json(['ok'=>true,'message'=>'Akun sudah aktif']);
}
if($action==='content'&&$method==='GET'){
 $allowed=['berita','pengumuman','layanan','galeri'];$rows=[];foreach($allowed as $type)foreach(array_slice(entries($type),0,50) as $v){$rows[]=['id'=>$v['id']??'','type'=>$type,'title'=>$v['title']??'','body'=>mobile_text(strip_tags((string)($v['body']??'')),4000),'image'=>$v['image']??'','created_at'=>$v['created_at']??''];}mobile_json(['ok'=>true,'items'=>$rows]);
}
$u=mobile_auth();$db=mobile_db();$uid=$u['user_id'];$admin=in_array($u['user_role'],['admin','admin_kelurahan'],true);
if($action==='me'){
 if($u['user_role']==='admin'){$name='Administrator';$department='Admin Utama';}else{$name=$u['username'];$department='';foreach(db_read('portal_users') as $x)if((string)$x['id']===$uid){$name=$x['name'];$department=$x['department']??'';break;}}
 mobile_json(['ok'=>true,'user'=>['id'=>$uid,'name'=>$name,'username'=>$u['username'],'role'=>$u['user_role'],'department'=>$department]]);
}
if($action==='logout'&&$method==='POST'){
 $h=$_SERVER['HTTP_AUTHORIZATION']??$_SERVER['REDIRECT_HTTP_AUTHORIZATION']??'';if(preg_match('/^Bearer\s+(.+)$/',$h,$m)){$s=$db->prepare('DELETE FROM mobile_tokens WHERE token_hash=?');$s->execute([hash('sha256',$m[1])]);}mobile_json(['ok'=>true]);
}
if($action==='device'&&$method==='POST'){
 $b=mobile_body();$token=mobile_text($b['fcm_token']??'',255);if(strlen($token)<40)mobile_error('Token perangkat tidak valid',422);
 $st=$db->prepare('INSERT INTO mobile_devices(user_id,username,fcm_token) VALUES(?,?,?) ON DUPLICATE KEY UPDATE user_id=VALUES(user_id),username=VALUES(username)');$st->execute([$uid,$u['username'],$token]);mobile_json(['ok'=>true]);
}
if($action==='permissions'){
 $grants=[];foreach(mobile_permission_keys() as $key) $grants[$key]=mobile_can($u,$key);
 mobile_json(['ok'=>true,'role'=>$u['user_role'],'role_label'=>mobile_role_names()[$u['user_role']]??$u['user_role'],'capabilities'=>$grants]);
}
if($action==='role_permissions'){
 mobile_need($u,'role:manage');mobile_permission_schema($db);
 if($method==='POST'){
  $b=mobile_body();$role=mobile_text($b['role']??'',50);$key=mobile_text($b['capability']??'',70);$allow=$b['allowed']??null;
  if(!isset(mobile_role_names()[$role])||$role==='admin'||!in_array($key,mobile_permission_keys(),true)||$key==='role:manage'||!is_bool($allow))mobile_error('Role, fitur, atau status izin tidak valid',422);
  $s=$db->prepare('INSERT INTO mobile_role_permissions(role,capability,allowed) VALUES(?,?,?) ON DUPLICATE KEY UPDATE allowed=VALUES(allowed)');$s->execute([$role,$key,$allow?1:0]);mobile_json(['ok'=>true]);
 }
 $rows=$db->query('SELECT role,capability,allowed FROM mobile_role_permissions ORDER BY role,capability')->fetchAll();
 mobile_json(['ok'=>true,'roles'=>mobile_role_names(),'keys'=>mobile_permission_keys(),'defaults'=>array_combine(array_keys(mobile_role_names()),array_map('mobile_default_permissions',array_keys(mobile_role_names()))),'overrides'=>$rows]);
}
if($action==='content_create'&&$method==='POST'){
 mobile_need($u,'content:create');$b=mobile_body();$type=mobile_text($b['type']??'',30);$title=mobile_text($b['title']??'',200);$body=mobile_text($b['body']??'',12000);
 if(!in_array($type,['berita','pengumuman'],true)||mobile_strlen($title)<5||mobile_strlen($body)<10)mobile_error('Judul (5 karakter) dan isi (10 karakter) wajib',422);
 $content=db_read('content');$id=bin2hex(random_bytes(12));
 $content[]=['id'=>$id,'type'=>$type,'title'=>$title,'body'=>nl2br(esc($body)),'image'=>'','created_at'=>date('c')];
 if(!db_write('content',$content))mobile_error('Konten gagal disimpan',503);
 mobile_emit($type,$type==='berita'?'Berita Kelurahan terbaru':'Pengumuman Kelurahan terbaru',$title,'public');
 mobile_json(['ok'=>true,'id'=>$id]);
}
if($action==='archive_create'&&$method==='POST'){
 mobile_need($u,'archive:create');$b=mobile_body();$year=(int)($b['archive_year']??0);$ref=mobile_text($b['reference_no']??'',100);$app=mobile_text($b['applicant_name']??'',200);$dead=mobile_text($b['deceased_name']??'',200);$notes=mobile_text($b['notes']??'',5000);
 if($year<1900||$year>(int)date('Y')||$ref===''||$app===''||$dead==='')mobile_error('Tahun, nomor surat, pemohon dan pewaris wajib',422);
 $db->exec('CREATE TABLE IF NOT EXISTS aw_archives (id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, archive_year SMALLINT UNSIGNED NOT NULL, reference_no VARCHAR(100) NOT NULL, applicant_name VARCHAR(200) NOT NULL, deceased_name VARCHAR(200) NOT NULL, notes TEXT, attachment VARCHAR(120) NULL, created_by VARCHAR(100) NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, INDEX idx_year(archive_year)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
 $st=$db->prepare('INSERT INTO aw_archives(archive_year,reference_no,applicant_name,deceased_name,notes,created_by) VALUES(?,?,?,?,?,?)');$st->execute([$year,$ref,$app,$dead,$notes,$uid]);
 mobile_json(['ok'=>true,'id'=>(int)$db->lastInsertId()]);
}
if($action==='archives'){
 mobile_need($u,'archive:view');
 $db->exec('CREATE TABLE IF NOT EXISTS aw_archives (id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, archive_year SMALLINT UNSIGNED NOT NULL, reference_no VARCHAR(100) NOT NULL, applicant_name VARCHAR(200) NOT NULL, deceased_name VARCHAR(200) NOT NULL, notes TEXT, attachment VARCHAR(120) NULL, created_by VARCHAR(100) NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, INDEX idx_year(archive_year)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
 $rows=$db->query('SELECT id,archive_year,reference_no,applicant_name,deceased_name,created_at FROM aw_archives ORDER BY archive_year DESC,id DESC LIMIT 100')->fetchAll();
 mobile_json(['ok'=>true,'items'=>$rows]);
}
if($action==='events'){
 $s=$db->prepare('SELECT id,category,title,message,created_at FROM mobile_events WHERE audience="public" OR (audience="admin" AND :admin=1) OR (audience="staff" AND :staff=1) OR (audience="personal" AND recipient=:recipient) ORDER BY id DESC LIMIT 60');
 $s->execute(['admin'=>$admin?1:0,'staff'=>$u['user_role']!=='warga'?1:0,'recipient'=>$uid]);mobile_json(['ok'=>true,'events'=>$s->fetchAll()]);
}
if($action==='chat_send'&&$method==='POST'){
 $b=mobile_body();$message=mobile_text($b['message']??'',2500);if(mobile_strlen($message)<2)mobile_error('Pesan terlalu pendek',422);
 $st=$db->prepare('SELECT created_at FROM mobile_chat WHERE user_id=? AND sender="warga" ORDER BY id DESC LIMIT 1');$st->execute([$uid]);$last=$st->fetchColumn();if($last && strtotime($last)>time()-3)mobile_error('Tunggu sebentar sebelum mengirim lagi',429);
 $st=$db->prepare('INSERT INTO mobile_chat(user_id,name,sender,message) VALUES(?,?,?,?)');$st->execute([$uid,$u['username'],'warga',$message]);mobile_emit('chat','Pesan warga baru','Ada pesan baru untuk admin','admin');mobile_json(['ok'=>true]);
}
if($action==='chat'){
 $s=$db->prepare('SELECT id,sender,message,created_at FROM mobile_chat WHERE user_id=? ORDER BY id DESC LIMIT 120');$s->execute([$uid]);mobile_json(['ok'=>true,'messages'=>array_reverse($s->fetchAll())]);
}
if($action==='chat_threads'){
 mobile_need($u,'chat:reply');$rows=$db->query('SELECT m.user_id,m.name,m.message,m.created_at FROM mobile_chat m INNER JOIN (SELECT user_id,MAX(id) AS last_id FROM mobile_chat GROUP BY user_id) z ON m.id=z.last_id ORDER BY m.id DESC LIMIT 150')->fetchAll();mobile_json(['ok'=>true,'threads'=>$rows]);
}
if($action==='chat_reply'&&$method==='POST'){
 mobile_need($u,'chat:reply');$b=mobile_body();$target=mobile_text($b['user_id']??'',80);$msg=mobile_text($b['message']??'',2500);if($target===''||$msg==='')mobile_error('Isi penerima dan pesan',422);
 $chk=$db->prepare('SELECT name FROM mobile_chat WHERE user_id=? LIMIT 1');$chk->execute([$target]);if(!$chk->fetch())mobile_error('Penerima tidak ditemukan',404);
 $st=$db->prepare('INSERT INTO mobile_chat(user_id,name,sender,message) VALUES(?,?,"admin",?)');$st->execute([$target,'Admin Kelurahan',$msg]);mobile_emit('chat','Pesan dibalas oleh Admin','Buka Hubungi Kami untuk melihat balasan','personal',$target);mobile_json(['ok'=>true]);
}
if($action==='report'&&$method==='POST'){
 $kind=mobile_text($_POST['kind']??'',60);if(!in_array($kind,['jumantik','kegiatan','fkdm','lmk','posyandu','pkk','kerja_bakti','ppsu'],true))mobile_error('Jenis laporan tidak diizinkan',422);
 $roleKinds=['warga'=>['jumantik'],'jumantik_rt'=>['jumantik'],'jumantik_rw'=>['jumantik'],'fkdm'=>['fkdm','kegiatan'],'lmk'=>['lmk','kegiatan'],'posyandu'=>['posyandu','kegiatan'],'pkk'=>['pkk','kegiatan'],'dasawisma'=>['pkk','kegiatan'],'ppsu'=>['ppsu','kegiatan','kerja_bakti'],'lurah'=>['kegiatan'],'ptsp'=>['kegiatan'],'dukcapil'=>['kegiatan'],'admin_kelurahan'=>['kegiatan'],'asn'=>['kegiatan'],'pppk'=>['kegiatan'],'pjlp'=>['kegiatan'],'rt'=>['kegiatan','kerja_bakti'],'rw'=>['kegiatan','kerja_bakti'],'admin'=>['kegiatan']];
 if(!in_array($kind,$roleKinds[$u['user_role']]??[],true))mobile_error('Jenis laporan tidak sesuai peran akun',403);
 mobile_need($u,'report:'.$kind);
 $address=mobile_text($_POST['address']??'',500);$phone=mobile_text($_POST['phone']??'',40);$notes=mobile_text($_POST['notes']??'',4000);if(!$address||!$notes)mobile_error('Alamat dan keterangan wajib',422);
 $photo=mobile_file('photo',true);$db->prepare('INSERT INTO mobile_reports(user_id,user_name,user_role,kind,address,phone,notes,photo_name) VALUES(?,?,?,?,?,?,?,?)')->execute([$uid,$u['username'],$u['user_role'],$kind,$address,$phone,$notes,$photo]);$id=(int)$db->lastInsertId();mobile_emit('laporan_masuk','Laporan '.$kind.' baru','Laporan masuk #'.$id,'admin');mobile_emit('laporan_masuk','Laporan berhasil dikirim','Nomor laporan: '.$id,'personal',$uid);mobile_json(['ok'=>true,'id'=>$id]);
}
if($action==='waris'&&$method==='POST'){
 mobile_need($u,'waris:create');
 require_once dirname(__DIR__).'/ahli-waris/bootstrap.php';
 try {aw_prepare_schema($db);}catch(Throwable $e){error_log('Cikoko waris migration failure: '.$e->getMessage());mobile_error('Struktur database Ahli Waris belum diperbarui. Admin perlu menjalankan migrasi.',503);} 
 $nik=mobile_text($_POST['nik']??'',16);if(!preg_match('/^[0-9]{16}$/',$nik))mobile_error('NIK wajib 16 angka',422);
 foreach(['name','phone','address','relation','deceased_name','heirs'] as $k)if(trim((string)($_POST[$k]??''))==='')mobile_error('Lengkapi '.$k,422);
 foreach(['r1','r2','r3','r4','r5','r6'] as $k)if(!isset($_FILES[$k])||$_FILES[$k]['error']!==UPLOAD_ERR_OK)mobile_error('Persyaratan foto belum lengkap: '.$k,422);
 $children=min(10,max(0,(int)($_POST['child_count']??0)));for($i=1;$i<=$children;$i++)if(!isset($_FILES['child_'.$i]))mobile_error('Foto anak ke-'.$i.' belum ada',422);
 $reference='AW-'.date('Ymd').'-'.strtoupper(bin2hex(random_bytes(4)));
 $db->beginTransaction();$paths=[];
 try {
  $names=[];for($i=1;$i<=$children;$i++)$names[]=['number'=>$i,'name'=>mobile_text($_POST['child_name_'.$i]??'',180)];
  $sql='INSERT INTO aw_applications(reference_no,account_id,applicant_name,applicant_nik,applicant_phone,applicant_address,relationship,deceased_name,marital_status,deceased_birthplace,deceased_birthdate,deceased_deathdate,deceased_marriage_date,heirs,children_json) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)';
  $db->prepare($sql)->execute([$reference,$uid,mobile_text($_POST['name'],160),$nik,mobile_text($_POST['phone'],40),mobile_text($_POST['address'],3000),mobile_text($_POST['relation'],100),mobile_text($_POST['deceased_name'],200),mobile_text($_POST['marital_status']??'Tidak diketahui',40),mobile_text($_POST['birthplace']??'',160),($_POST['birthdate']??'')?:null,($_POST['deathdate']??'')?:null,($_POST['marriage_date']??'')?:null,mobile_text($_POST['heirs'],12000),json_encode($names,JSON_UNESCAPED_UNICODE)]);
  $id=(int)$db->lastInsertId();$ins=$db->prepare('INSERT INTO aw_attachments(application_id,requirement_code,original_name,storage_name,mime_type,size_bytes) VALUES(?,?,?,?,?,?)');
  $dir=dirname(__DIR__).'/ahli-waris/private/uploads';if(!is_dir($dir))mkdir($dir,0750,true);
  foreach(array_merge(['r1','r2','r3','r4','r5','r6','r7','r8'],($children>0?array_map(fn($n)=>'child_'.$n,range(1,$children)):[])) as $key){$f=$_FILES[$key]??null;if(!$f||($f['error']??4)===UPLOAD_ERR_NO_FILE)continue;
   if(($f['error']??4)!==UPLOAD_ERR_OK||($f['size']??0)>4*1024*1024||!is_uploaded_file($f['tmp_name']))throw new RuntimeException('Foto '.$key.' gagal atau melebihi 4 MB');
   $mime=(new finfo(FILEINFO_MIME_TYPE))->file($f['tmp_name']);$ext=['image/jpeg'=>'jpg','image/png'=>'png','image/webp'=>'webp'][$mime]??null;if(!$ext)throw new RuntimeException('Foto '.$key.' harus JPG/PNG/WebP');
   $name=bin2hex(random_bytes(20)).'.'.$ext;if(!move_uploaded_file($f['tmp_name'],$dir.'/'.$name))throw new RuntimeException('Simpan dokumen gagal');$paths[]=$dir.'/'.$name;$ins->execute([$id,$key,basename($f['name']),$name,$mime,(int)$f['size']]);
  }
  $db->prepare('INSERT INTO aw_history(application_id,previous_status,new_status,actor_id,notes) VALUES (?,NULL,"masuk",?,"Permohonan dari Android")')->execute([$id,$uid]);$db->commit();
 }catch(Throwable $e){if($db->inTransaction())$db->rollBack();foreach($paths as $f)@unlink($f);error_log('Waris mobile upload error: '.$e->getMessage());mobile_error('Permohonan belum berhasil disimpan. Data tetap berada di formulir. Periksa dokumen atau hubungi admin jika masalah berulang.',503);}
 mobile_emit('surat','Surat Ahli Waris baru','Pengajuan '.$reference.' masuk','admin');mobile_emit('progres_surat','Permohonan diterima',$reference,'personal',$uid);mobile_json(['ok'=>true,'reference'=>$reference]);
}
if($action==='history'){
 $st=$db->prepare('SELECT id,kind AS title,status,created_at FROM mobile_reports WHERE user_id=? ORDER BY id DESC LIMIT 70');$st->execute([$uid]);$rows=$st->fetchAll();
 try{$st=$db->prepare('SELECT id,reference_no AS reference,"Ahli Waris" AS title,status,created_at FROM aw_applications WHERE account_id=? ORDER BY id DESC LIMIT 70');$st->execute([$uid]);$rows=array_merge($rows,$st->fetchAll());}catch(Throwable $e){error_log('waris history: '.$e->getMessage());}
 usort($rows,fn($a,$b)=>strcmp($b['created_at'],$a['created_at']));mobile_json(['ok'=>true,'items'=>array_slice($rows,0,100)]);
}
if($action==='admin_reports'){
 mobile_need($u,'reports:view');$rows=$db->query('SELECT id,kind AS title,user_name AS name,"report" AS kind,status,created_at FROM mobile_reports ORDER BY id DESC LIMIT 100')->fetchAll();
 try{$rows=array_merge($rows,$db->query('SELECT id,reference_no AS reference,applicant_name AS name,"waris" AS kind,status,created_at FROM aw_applications ORDER BY id DESC LIMIT 100')->fetchAll());}catch(Throwable $e){}
 mobile_json(['ok'=>true,'items'=>$rows]);
}
if($action==='status'&&$method==='POST'){
 mobile_need($u,'reports:verify');$b=mobile_body();$status=mobile_text($b['status']??'',20);$kind=mobile_text($b['kind']??'',20);$id=(int)($b['id']??0);if(!$id||!in_array($status,['masuk','proses','revisi','selesai','ditolak'],true))mobile_error('Status salah',422);
 if($kind==='waris'){
  $st=$db->prepare('SELECT account_id,status FROM aw_applications WHERE id=?');$st->execute([$id]);$row=$st->fetch();if(!$row)mobile_error('Permohonan tidak ditemukan',404);
  $db->prepare('UPDATE aw_applications SET status=? WHERE id=?')->execute([$status,$id]);$db->prepare('INSERT INTO aw_history(application_id,previous_status,new_status,actor_id,notes) VALUES (?,?,?,?,?)')->execute([$id,$row['status'],$status,$uid,'Pembaruan via aplikasi']);$owner=$row['account_id'];
 }else{
  $st=$db->prepare('SELECT user_id FROM mobile_reports WHERE id=?');$st->execute([$id]);$owner=$st->fetchColumn();if(!$owner)mobile_error('Laporan tidak ditemukan',404);
  $db->prepare('UPDATE mobile_reports SET status=? WHERE id=?')->execute([$status,$id]);
 }
 mobile_emit('progres_surat','Status permohonan: '.ucfirst($status),'Periksa rincian permohonan pada aplikasi','personal',$owner);mobile_json(['ok'=>true]);
}
mobile_error('Endpoint tidak tersedia',404);
