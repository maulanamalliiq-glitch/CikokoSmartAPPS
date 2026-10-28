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
        'api_rt_rw'=>is_file(__DIR__.'/rt_rw_letters.php'),
        'api_territory'=>is_file(__DIR__.'/territory.php'),
        'api_surat_identity'=>is_file(__DIR__.'/surat_identity_v2525.php'),
        'db_config'=>is_file(dirname(__DIR__).'/ahli-waris/config.php'),
    ];
    $ready=!in_array(false,$files,true);
    http_response_code($ready?200:503);
    echo json_encode(['ok'=>$ready,'service'=>'Cikoko API','version'=>'2.5.25','build'=>'V2525-HARDCHECK-ID','ready'=>$ready,
        'checks'=>$files,'message'=>$ready?'Berkas API terpasang. Koneksi database belum diuji.':'Ada dependensi API yang belum terpasang.'],JSON_UNESCAPED_UNICODE);
    exit;
}
require __DIR__.'/bootstrap.php';
require __DIR__.'/permissions.php';
require __DIR__.'/territory.php';
require_once __DIR__.'/surat_identity_v2525.php';

if($action==='login'&&$method==='POST'){
 $body=mobile_body();$username=mobile_text($body['username']??'',100);$pass=(string)($body['password']??'');$found=null;
 $a=db_read('admin');if($username!==''&&hash_equals((string)($a['username']??''),$username) && password_verify($pass,(string)($a['password_hash']??''))){$found=['id'=>'admin','name'=>'Administrator','username'=>$username,'role'=>'admin'];}
 if(!$found)foreach(db_read('portal_users') as $u){if(hash_equals((string)($u['username']??''),$username)&&($u['active']??false)&&password_verify($pass,(string)($u['password_hash']??''))){$found=['id'=>$u['id'],'name'=>$u['name'],'username'=>$u['username'],'role'=>$u['role'],'department'=>$u['department']??'','rt'=>$u['rt']??'','rw'=>$u['rw']??''];break;}}
 if(!$found)mobile_error('Username, password, atau status akun tidak sesuai',401);
 $token=rtrim(strtr(base64_encode(random_bytes(48)),'+/','-_'),'=');$st=mobile_db()->prepare('INSERT INTO mobile_tokens(token_hash,user_id,username,user_role,expires_at) VALUES(?,?,?,?,DATE_ADD(NOW(),INTERVAL 30 DAY))');$st->execute([hash('sha256',$token),$found['id'],$found['username'],$found['role']]);mobile_json(['ok'=>true,'token'=>$token,'user'=>$found]);
}
if($action==='register'&&$method==='POST'){
 $b=mobile_body();$name=mobile_text($b['name']??'',120);$username=mobile_text($b['username']??'',80);$pass=(string)($b['password']??'');$confirm=(string)($b['confirm']??'');$address=mobile_text($b['address']??'',600);$phone=mobile_text($b['phone']??'',40);$email=mobile_text($b['email']??'',160);
 if($pass===''||$pass!==$confirm)mobile_error('Konfirmasi password tidak sama atau kosong',422);
 $rt=cikoko_area($b['rt']??'','RT');$rw=cikoko_area($b['rw']??'','RW');
 if(mobile_strlen($name)<3 || !preg_match('/^[a-zA-Z0-9_.-]{4,40}$/',$username)||!preg_match('/^[0-9+ -]{8,20}$/',$phone)||$address===''||!filter_var($email,FILTER_VALIDATE_EMAIL))mobile_error('Periksa nama, username, alamat, nomor telepon dan email',422);
 $users=db_read('portal_users');$a=db_read('admin');$taken=strcasecmp((string)($a['username']??''),$username)===0;foreach($users as $v)if(strcasecmp((string)($v['username']??''),$username)===0)$taken=true;
 if($taken)mobile_error('Username sudah digunakan',409);
 $users[]=['id'=>bin2hex(random_bytes(12)),'name'=>$name,'username'=>$username,'password_hash'=>password_hash($pass,PASSWORD_DEFAULT),'role'=>'warga','department'=>'Warga','address'=>$address,'rt'=>$rt,'rw'=>$rw,'phone'=>$phone,'email'=>$email,'active'=>true,'created_at'=>date('c')];
 if(!db_write('portal_users',$users))mobile_error('Data akun gagal disimpan',503);
 mobile_json(['ok'=>true,'message'=>'Akun sudah aktif']);
}
if($action==='content'&&$method==='GET'){
 $allowed=['berita','pengumuman','layanan','galeri'];$rows=[];foreach($allowed as $type)foreach(array_slice(entries($type),0,50) as $v){$rows[]=['id'=>$v['id']??'','type'=>$type,'title'=>$v['title']??'','body'=>mobile_text(strip_tags((string)($v['body']??'')),4000),'image'=>$v['image']??'','created_at'=>$v['created_at']??''];}mobile_json(['ok'=>true,'items'=>$rows]);
}
if(in_array($action,['public_letters','public_letter_status'],true)&&$method==='GET'){
 require_once __DIR__.'/public_letters.php';
 cikoko_public_letters(mobile_db());
}
$u=mobile_auth();$db=mobile_db();$uid=$u['user_id'];$admin=in_array($u['user_role'],['admin','admin_kelurahan'],true);
// Akun staf hanya dapat dibuat oleh Admin Utama yang telah terautentikasi.
if(in_array($action,['accounts_list','accounts_create'],true)){
 require_once __DIR__.'/admin_accounts.php';
 cikoko_admin_accounts($action,$method,$db,$u);
}
require_once __DIR__.'/waris_review.php';
require_once __DIR__.'/waris_stage.php';
if($action==='waris_stage'&&$method==='POST'){
 mobile_need($u,'waris:create');
 waris_stage_upload($db,(string)$uid,(string)($_POST['draft_key']??''));
}
if(str_starts_with($action,'civic_')){if(!is_file(__DIR__.'/civic_lpj_v2513.php'))mobile_error('Backend LPJ belum dipasang.',503);require_once __DIR__.'/civic_lpj_v2513.php';lpj_api($action,$method,$db,$u);}
if(str_starts_with($action,'rt_rw_')){if(!is_file(__DIR__.'/rt_rw_letters.php'))mobile_error('Patch Surat Pengantar RT/RW belum terpasang di server.',503);require_once __DIR__.'/rt_rw_letters.php';cikoko_rt_rw_dispatch($action,$method,$db,$u);}
if(in_array($action,['document_detail','waris_attachment','waris_request_correction','waris_resubmit'],true))waris_review_dispatch($action,$method,$db,$u,(string)$uid);
if($action==='me'){
  $profile=['id'=>$uid,'name'=>'Administrator','username'=>$u['username'],'role'=>$u['user_role']];
  if($u['user_role']!=='admin'){
    foreach(db_read('portal_users') as $entry){
      if((string)($entry['id']??'')===(string)$uid){
        $profile=['id'=>$uid,'name'=>(string)($entry['name']??''),'username'=>(string)($entry['username']??''),'role'=>$u['user_role'],
          'phone'=>(string)($entry['phone']??''),'email'=>(string)($entry['email']??''),'address'=>(string)($entry['address']??''),'nik'=>(string)($entry['nik']??''),'rt'=>(string)($entry['rt']??''),'rw'=>(string)($entry['rw']??'')];
        break;
      }
    }
  }
  mobile_json(['ok'=>true,'user'=>$profile]);
}
if($action==='profile_update'&&$method==='POST'){
  if($u['user_role']==='admin')mobile_error('Perubahan profil administrator dilakukan melalui panel resmi.',403);
  $b=mobile_body();$name=mobile_text($b['name']??'',120);$phone=mobile_text($b['phone']??'',30);
  $email=mobile_text($b['email']??'',160);$address=mobile_text($b['address']??'',600);
  if(mobile_strlen($name)<3||!preg_match('/^[0-9+ ()-]{8,25}$/',$phone)||!filter_var($email,FILTER_VALIDATE_EMAIL)||mobile_strlen($address)<4)
    mobile_error('Periksa kembali nama, nomor telepon, alamat, dan email.',422);
  $users=db_read('portal_users');$updated=false;$result=null;
  foreach($users as &$entry){
    if((string)($entry['id']??'')!==(string)$uid)continue;
    if(!($entry['active']??false))mobile_error('Akun tidak aktif. Hubungi pengelola.',403);
    $area=cikoko_area_update($b,$entry,$u['user_role']==='warga');
    $entry['name']=$name;$entry['phone']=$phone;$entry['email']=$email;$entry['address']=$address;
    foreach($area as $key=>$value)$entry[$key]=$value;
    $result=['id'=>$uid,'name'=>$name,'username'=>(string)$entry['username'],'role'=>$u['user_role'],
      'phone'=>$phone,'email'=>$email,'address'=>$address,'nik'=>(string)($entry['nik']??''),'rt'=>(string)($entry['rt']??''),'rw'=>(string)($entry['rw']??'')];
    $updated=true;break;
  }
  unset($entry);
  if(!$updated)mobile_error('Profil akun tidak ditemukan. Silakan masuk kembali.',404);
  if(!db_write('portal_users',$users))mobile_error('Perubahan profil belum dapat disimpan. Silakan coba lagi.',503);
  mobile_json(['ok'=>true,'message'=>'Profil berhasil diperbarui.','user'=>$result]);
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
 // The content writer already sends this event; don't publish it twice.
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
 waris_review_schema($db);
 $sql='SELECT e.id,e.category,e.title,e.message,e.created_at,l.object_type,l.object_id,IF(r.event_id IS NULL,0,1) AS is_read FROM mobile_events e LEFT JOIN mobile_event_links l ON l.event_id=e.id LEFT JOIN mobile_event_reads r ON r.event_id=e.id AND r.user_id=:viewer WHERE e.audience="public" OR (e.audience="admin" AND :admin=1) OR (e.audience="staff" AND :staff=1) OR (e.audience="personal" AND e.recipient=:recipient) ORDER BY e.id DESC LIMIT 60';
 $q=$db->prepare($sql);$q->execute(['viewer'=>(string)$uid,'admin'=>$admin?1:0,'staff'=>$u['user_role']!=='warga'?1:0,'recipient'=>(string)$uid]);
 $rows=$q->fetchAll();
 mobile_json(['ok'=>true,'events'=>$rows,'unread_count'=>count(array_filter($rows,static fn($r)=>(int)$r['is_read']===0))]);
}
if($action==='event_read'&&$method==='POST'){
 $b=mobile_body();$id=(int)($b['id']??0);
 if($id<1)mobile_error('Pilih notifikasi yang ingin dibaca.',422);
 $q=$db->prepare('SELECT id FROM mobile_events WHERE id=? AND (audience="public" OR (audience="admin" AND ?=1) OR (audience="staff" AND ?=1) OR (audience="personal" AND recipient=?))');
 $q->execute([$id,$admin?1:0,$u['user_role']!=='warga'?1:0,(string)$uid]);
 if(!$q->fetchColumn())mobile_error('Notifikasi tidak tersedia.',404);
 $db->prepare('INSERT IGNORE INTO mobile_event_reads(user_id,event_id) VALUES(?,?)')->execute([(string)$uid,$id]);
 mobile_json(['ok'=>true,'message'=>'Notifikasi telah dibaca.']);
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
if($action==='waris_format'&&$method==='GET'){
 mobile_need($u,'waris:create');
 mobile_json(['ok'=>true,'upload_format'=>'split_v1',
   'staged_uploads'=>true,'stage_batch_size'=>8,
   'max_file_uploads'=>(int)ini_get('max_file_uploads'),
   'post_max_size'=>(string)ini_get('post_max_size')]);
}
if($action==='waris'&&$method==='POST'){
 mobile_need($u,'waris:create');
 require_once dirname(__DIR__).'/ahli-waris/bootstrap.php';
 try {aw_prepare_schema($db);}catch(Throwable $e){error_log('Cikoko waris migration failure: '.$e->getMessage());mobile_error('Struktur database Ahli Waris belum diperbarui. Admin perlu menjalankan migrasi.',503);} 
 if($_POST===[]&&$_FILES===[]){mobile_error('Data dan foto tidak diterima server. Periksa batas upload_max_filesize, post_max_size dan max_file_uploads pada cPanel.',413);}
 $nik=mobile_text($_POST['nik']??'',16);if(!preg_match('/^[0-9]{16}$/',$nik))mobile_error('NIK wajib 16 angka',422);
 foreach(['name','phone','address','relation','deceased_name','heirs'] as $k)if(trim((string)($_POST[$k]??''))==='')mobile_error('Lengkapi '.$k,422);
 $children=min(10,max(0,(int)($_POST['child_count']??0)));
 $format=(string)($_POST['document_format']??'');
 if(!in_array($format,['','split_v1'],true))mobile_error('Format dokumen tidak dikenali.',422);
 // V2516: new clients upload three distinct photos per heir and per child.
 // Old combined codes are still accepted from older APKs for compatibility.
 $split=$format==='split_v1';
 $required=waris_required_upload_codes($children,$split);
 $stagedKey=trim((string)($_POST['draft_key']??''));
 if($stagedKey!==''){
  $stagedKey=waris_stage_key($stagedKey);
  if(!$split)mobile_error('Pengiriman bertahap hanya untuk format dokumen terbaru.',422);
 }
 $stagedRows=$stagedKey!==''?waris_stage_rows($db,(string)$uid,$stagedKey):[];
 $missing=[];
 $labels=waris_codes($children);
 foreach($required as $k){
  if($stagedKey!==''){
   $row=$stagedRows[$k]??null;
   $path=dirname(__DIR__).'/ahli-waris/private/uploads/'.($row['storage_name']??'');
   if(!$row||!is_file($path))$missing[]=$labels[$k]??$k;
  }else{
   $file=$_FILES[$k]??null;
   if(!is_array($file)||is_array($file['name'])||
      ($file['error']??UPLOAD_ERR_NO_FILE)!==UPLOAD_ERR_OK){
    $missing[]=$labels[$k]??$k;
   }
  }
 }
 if($missing){
  mobile_error('Foto wajib yang belum diterima server: '.implode('; ',$missing).
   '. Jika sudah dipilih di HP, periksa max_file_uploads ('.
   (int)ini_get('max_file_uploads').' berkas), post_max_size ('.
   (string)ini_get('post_max_size').') dan pasang patch API terbaru.',422);
 }
 for($i=1;$i<=$children;$i++){
  if(trim((string)($_POST['child_name_'.$i]??''))==='')mobile_error('Nama anak ke-'.$i.' wajib diisi.',422);
 }
 $reference='AW-'.date('Ymd').'-'.strtoupper(bin2hex(random_bytes(4)));
 $db->beginTransaction();$paths=[];
 try {
  $names=[];for($i=1;$i<=$children;$i++)$names[]=['number'=>$i,'name'=>mobile_text($_POST['child_name_'.$i]??'',180)];
  $sql='INSERT INTO aw_applications(reference_no,account_id,applicant_name,applicant_nik,applicant_phone,applicant_address,relationship,deceased_name,marital_status,deceased_birthplace,deceased_birthdate,deceased_deathdate,deceased_marriage_date,heirs,children_json) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)';
  $db->prepare($sql)->execute([$reference,$uid,mobile_text($_POST['name'],160),$nik,mobile_text($_POST['phone'],40),mobile_text($_POST['address'],3000),mobile_text($_POST['relation'],100),mobile_text($_POST['deceased_name'],200),mobile_text($_POST['marital_status']??'Tidak diketahui',40),mobile_text($_POST['birthplace']??'',160),($_POST['birthdate']??'')?:null,($_POST['deathdate']??'')?:null,($_POST['marriage_date']??'')?:null,mobile_text($_POST['heirs'],12000),json_encode($names,JSON_UNESCAPED_UNICODE)]);
  $id=(int)$db->lastInsertId();$ins=$db->prepare('INSERT INTO aw_attachments(application_id,requirement_code,original_name,storage_name,mime_type,size_bytes) VALUES(?,?,?,?,?,?)');
  $dir=dirname(__DIR__).'/ahli-waris/private/uploads';if(!is_dir($dir))mkdir($dir,0750,true);
  foreach(array_merge($required,['r7','r8']) as $key){
   if($stagedKey!==''){
    $row=$stagedRows[$key]??null;
    if($row)$ins->execute([$id,$key,$row['original_name'],$row['storage_name'],
      $row['mime_type'],(int)$row['size_bytes']]);
    continue;
   }
   $f=$_FILES[$key]??null;if(!$f||($f['error']??4)===UPLOAD_ERR_NO_FILE)continue;
   if(($f['error']??4)!==UPLOAD_ERR_OK||($f['size']??0)>4*1024*1024||!is_uploaded_file($f['tmp_name']))throw new RuntimeException('Foto '.$key.' gagal atau melebihi 4 MB');
   $mime=(new finfo(FILEINFO_MIME_TYPE))->file($f['tmp_name']);$ext=['image/jpeg'=>'jpg','image/png'=>'png','image/webp'=>'webp'][$mime]??null;if(!$ext)throw new RuntimeException('Foto '.$key.' harus JPG/PNG/WebP');
   $name=bin2hex(random_bytes(20)).'.'.$ext;if(!move_uploaded_file($f['tmp_name'],$dir.'/'.$name))throw new RuntimeException('Simpan dokumen gagal');$paths[]=$dir.'/'.$name;$ins->execute([$id,$key,basename($f['name']),$name,$mime,(int)$f['size']]);
  }
  $db->prepare('INSERT INTO aw_history(application_id,previous_status,new_status,actor_id,notes) VALUES (?,NULL,"masuk",?,"Permohonan dari Android")')->execute([$id,$uid]);
  if($stagedKey!=='')$db->prepare('DELETE FROM mobile_waris_staging WHERE user_id=? AND draft_key=?')->execute([$uid,$stagedKey]);
  $db->commit();
 }catch(Throwable $e){if($db->inTransaction())$db->rollBack();foreach($paths as $f)@unlink($f);error_log('Waris mobile upload error: '.$e->getMessage());mobile_error('Permohonan belum berhasil disimpan. Data tetap berada di formulir. Periksa dokumen atau hubungi admin jika masalah berulang.',503);}
 mobile_emit('surat','Surat Ahli Waris baru','Pengajuan '.$reference.' masuk','admin');waris_review_schema($db);waris_emit_link($db,'waris',$id,'progres_surat','Permohonan diterima',$reference,'personal',(string)$uid);mobile_json(['ok'=>true,'reference'=>$reference]);
}
if($action==='history'){
 $st=$db->prepare('SELECT id,kind AS title,"report" AS kind,status,created_at FROM mobile_reports WHERE user_id=? ORDER BY id DESC LIMIT 70');$st->execute([$uid]);$rows=$st->fetchAll();
 try{$st=$db->prepare('SELECT id,reference_no AS reference,"Ahli Waris" AS title,"waris" AS kind,status,created_at FROM aw_applications WHERE account_id=? ORDER BY id DESC LIMIT 70');$st->execute([$uid]);$rows=array_merge($rows,$st->fetchAll());}catch(Throwable $e){error_log('waris history: '.$e->getMessage());}
 usort($rows,fn($a,$b)=>strcmp($b['created_at'],$a['created_at']));
 foreach($rows as &$entry){$entry=cikoko_v2525_identity_row($entry,($entry['kind']??'report')==='waris'?'waris':'report');}unset($entry);
 mobile_json(['ok'=>true,'api_build'=>'V2525-HARDCHECK-ID','items'=>array_slice($rows,0,100)]);
}
if($action==='admin_waris_date') {
 require_once __DIR__.'/admin_waris_date.php';
 cikoko_admin_waris_date($method,$db,$u);
}
if($action==='admin_reports'){
 mobile_need($u,'reports:view');$rows=$db->query('SELECT id,kind AS title,user_name AS name,"report" AS kind,status,created_at FROM mobile_reports ORDER BY id DESC LIMIT 100')->fetchAll();
 try{$rows=array_merge($rows,$db->query('SELECT id,reference_no AS reference,applicant_name AS name,"waris" AS kind,status,created_at FROM aw_applications ORDER BY id DESC LIMIT 100')->fetchAll());}catch(Throwable $e){}
 foreach($rows as &$entry){$entry=cikoko_v2525_identity_row($entry,($entry['kind']??'report')==='waris'?'waris':'report');}unset($entry);
 mobile_json(['ok'=>true,'api_build'=>'V2525-HARDCHECK-ID','items'=>$rows]);
}
if($action==='status'&&$method==='POST'){
 mobile_need($u,'reports:verify');
 $b=mobile_body();if(!$b && !empty($_POST))$b=$_POST;
 $status=strtolower(mobile_text($b['status']??$b['new_status']??'',40));
 $status=['diproses'=>'proses','dalam proses'=>'proses','disetujui'=>'selesai','perbaikan'=>'revisi'][$status]??$status;
 $kind=strtolower(mobile_text($b['kind']??'report',24));
 $awRef=cikoko_v2525_reference_from_input($b);
 if($awRef!=='')$kind='waris';
 if(!in_array($kind,['report','waris'],true))mobile_error('Jenis permohonan tidak dikenal',422);
 $id=0;
 foreach(['id','application_id','request_id','report_id','reference_no','reference','document_key','title'] as $field){
  if(!array_key_exists($field,$b))continue;
  $candidate=cikoko_v2525_identifier($db,$b[$field],$kind);
  if($candidate>0){$id=$candidate;break;}
 }
 if($id<1 && $awRef!=='')$id=cikoko_v2525_identifier($db,$awRef,'waris');
 if($id<1){error_log('[Cikoko V2525] status: missing numeric ID, kind='.$kind.', submitted_keys='.implode(',',array_intersect(array_keys($b),['id','reference','reference_no','title','document_key'])));mobile_error('API belum menerima ID surat yang valid. Periksa versi server dan muat ulang daftar.',422);}
 if(!in_array($status,['masuk','proses','revisi','selesai','ditolak'],true))mobile_error('Status tidak dikenal',422);
 if($kind==='waris'){
  $st=$db->prepare('SELECT account_id,status FROM aw_applications WHERE id=?');$st->execute([$id]);$row=$st->fetch();if(!$row)mobile_error('Permohonan tidak ditemukan',404);
  $db->prepare('UPDATE aw_applications SET status=? WHERE id=?')->execute([$status,$id]);$db->prepare('INSERT INTO aw_history(application_id,previous_status,new_status,actor_id,notes) VALUES (?,?,?,?,?)')->execute([$id,$row['status'],$status,$uid,'Pembaruan via aplikasi']);$owner=$row['account_id'];
 }else{
  $st=$db->prepare('SELECT user_id,status FROM mobile_reports WHERE id=?');$st->execute([$id]);$report=$st->fetch();if(!$report)mobile_error('Laporan tidak ditemukan',404);
  $owner=$report['user_id'];
  $db->beginTransaction();
  try{
   $db->prepare('UPDATE mobile_reports SET status=? WHERE id=?')->execute([$status,$id]);
   require_once __DIR__.'/report_progress.php';
   cikoko_report_history_log($db,$id,(string)$uid,(string)$report['status'],$status);
   $db->commit();
  }catch(Throwable $e){if($db->inTransaction())$db->rollBack();throw $e;}
 }
 if($kind==='waris'){waris_review_schema($db);waris_emit_link($db,'waris',$id,'progres_surat','Status Ahli Waris: '.ucfirst($status),'Periksa rincian dan progres surat Anda.','personal',(string)$owner);}else{mobile_emit('progres_surat','Status permohonan: '.ucfirst($status),'Periksa rincian permohonan pada aplikasi','personal',(string)$owner);}mobile_json(['ok'=>true]);
}
mobile_error('Endpoint tidak tersedia',404);
