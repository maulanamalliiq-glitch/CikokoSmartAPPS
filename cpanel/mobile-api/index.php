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
    echo json_encode(['ok'=>false,'error'=>'Layanan sedang mengalami kendala. Silakan coba kembali atau hubungi petugas kelurahan.'],JSON_UNESCAPED_UNICODE);
});
$action=(string)($_GET['action']??'');
$method=(string)($_SERVER['REQUEST_METHOD']??'GET');
if($action==='health'){
    $files=[
        'website_lib'=>is_file(dirname(__DIR__).'/lib.php'),
        'roles_lib'=>is_file(dirname(__DIR__).'/roles-lib.php'),
        'api_bootstrap'=>is_file(__DIR__.'/bootstrap.php'),
        'api_permissions'=>is_file(__DIR__.'/permissions.php'),
        'api_governance'=>is_file(__DIR__.'/governance_review.php'),
        'api_rt_rw'=>is_file(__DIR__.'/rt_rw_service.php'),
        'api_lpj'=>is_file(__DIR__.'/civic_lpj.php'),
        'api_waris_staging'=>is_file(__DIR__.'/waris_staging.php'),
        'api_pdf'=>is_file(__DIR__.'/pdf_native.php'),
        'api_integrated_services'=>is_file(__DIR__.'/integrated_services.php'),
        'api_release_core'=>is_file(__DIR__.'/release_core.php'),
        'api_account_support'=>is_file(__DIR__.'/account_support.php'),
        'db_config'=>is_file(dirname(__DIR__).'/ahli-waris/config.php'),
    ];
    $ready=!in_array(false,$files,true);
    http_response_code($ready?200:503);
    echo json_encode(['ok'=>$ready,'service'=>'Cikoko API','version'=>'2542.rc1','ready'=>$ready,
        'checks'=>$files,'message'=>$ready?'Berkas API terpasang. Koneksi database belum diuji.':'Ada dependensi API yang belum terpasang.'],JSON_UNESCAPED_UNICODE);
    exit;
}
require __DIR__.'/bootstrap.php';
require __DIR__.'/permissions.php';
if(in_array($action,['home_slides','home_slide_photo','home_slide_upload','home_slides_save'],true)){
 require_once __DIR__.'/home_slides.php';
 cikoko_home_slides_dispatch($action,$method);
}

if(in_array($action,['integrated_services','integrated_services_save','integrated_services_logo_upload'],true)){
 require_once __DIR__.'/integrated_services.php';
 cikoko_integrated_dispatch($action,$method);
}


if(in_array($action,['account_help','account_request','account_requests','account_request_resolve'],true)){
 require_once __DIR__.'/account_support.php';cikoko_account_dispatch($action,$method);
}
if($action==='login'&&$method==='POST'){
 $limitDb=mobile_db();cikoko_rate_limit($limitDb,'login_ip',(string)($_SERVER['REMOTE_ADDR']??''),200,900);
 $body=mobile_body();$username=mobile_text($body['username']??'',100);$pass=(string)($body['password']??'');$found=null;
 cikoko_rate_limit($limitDb,'login_account',strtolower($username),10,900);
 $a=db_read('admin');if($username!==''&&hash_equals((string)($a['username']??''),$username) && password_verify($pass,(string)($a['password_hash']??''))){$found=['id'=>'admin','name'=>'Administrator','username'=>$username,'role'=>'admin'];}
 if(!$found)foreach(db_read('portal_users') as $u){if(hash_equals((string)($u['username']??''),$username)&&($u['active']??false)&&password_verify($pass,(string)($u['password_hash']??''))){$found=['id'=>$u['id'],'name'=>$u['name'],'username'=>$u['username'],'role'=>$u['role'],'department'=>$u['department']??''];break;}}
 if(!$found)mobile_error('Username, password, atau status akun tidak sesuai',401);
 $token=rtrim(strtr(base64_encode(random_bytes(48)),'+/','-_'),'=');$st=mobile_db()->prepare('INSERT INTO mobile_tokens(token_hash,user_id,username,user_role,expires_at) VALUES(?,?,?,?,DATE_ADD(NOW(),INTERVAL 30 DAY))');$st->execute([hash('sha256',$token),$found['id'],$found['username'],$found['role']]);mobile_json(['ok'=>true,'token'=>$token,'user'=>$found]);
}
if($action==='register'&&$method==='POST'){
 cikoko_rate_limit(mobile_db(),'register',(string)($_SERVER['REMOTE_ADDR']??''),10,3600);
 $b=mobile_body();$name=mobile_text($b['name']??'',120);$username=mobile_text($b['username']??'',80);$pass=(string)($b['password']??'');$confirm=(string)($b['confirm']??'');$address=mobile_text($b['address']??'',600);$phone=mobile_text($b['phone']??'',40);$email=mobile_text($b['email']??'',160);
 $rawRt=trim(mobile_text($b['rt']??'',12));
 $rawRw=trim(mobile_text($b['rw']??'',12));
 if(($rawRt==='')!==($rawRw===''))mobile_error('RT dan RW harus diisi bersamaan.',422);
 if($rawRt!==''&&(!preg_match('/^\d{1,2}$/',$rawRt)||
    !preg_match('/^\d{1,2}$/',$rawRw)||
    (int)$rawRt<1||(int)$rawRt>99||(int)$rawRw<1||(int)$rawRw>99)){
  mobile_error('RT dan RW harus angka 01 sampai 99.',422);
 }
 $rt=$rawRt===''?'':str_pad((string)(int)$rawRt,2,'0',STR_PAD_LEFT);
 $rw=$rawRw===''?'':str_pad((string)(int)$rawRw,2,'0',STR_PAD_LEFT);
 if(!cikoko_password_valid($pass))mobile_error('Kata sandi minimal 10 karakter dan memuat huruf serta angka, maksimal 128 karakter.',422);
 if($pass===''||$pass!==$confirm)mobile_error('Konfirmasi password tidak sama atau kosong',422);
 if(mobile_strlen($name)<3 || !preg_match('/^[a-zA-Z0-9_.-]{4,40}$/',$username)||!preg_match('/^[0-9+ -]{8,20}$/',$phone)||$address===''||!filter_var($email,FILTER_VALIDATE_EMAIL))mobile_error('Periksa nama, username, alamat, nomor telepon dan email',422);
 $users=db_read('portal_users');$a=db_read('admin');$taken=strcasecmp((string)($a['username']??''),$username)===0;foreach($users as $v)if(strcasecmp((string)($v['username']??''),$username)===0)$taken=true;
 if($taken)mobile_error('Username sudah digunakan',409);
 $users[]=['id'=>bin2hex(random_bytes(12)),'name'=>$name,'username'=>$username,'password_hash'=>password_hash($pass,PASSWORD_DEFAULT),'role'=>'warga','department'=>'Warga','address'=>$address,'phone'=>$phone,'email'=>$email,'rt'=>$rt,'rw'=>$rw,'active'=>true,'created_at'=>date('c')];
 if(!db_write('portal_users',$users))mobile_error('Data akun gagal disimpan',503);
 mobile_json(['ok'=>true,'message'=>'Akun sudah aktif']);
}
if($action==='public_letter_status' && $method==='GET'){
 require_once __DIR__.'/public_letter_status_v2536.php';
 cikoko_public_letter_status_v2536();
}
if($action==='content'&&$method==='GET'){
 $allowed=['berita','pengumuman','layanan','galeri'];$rows=[];foreach($allowed as $type)foreach(array_slice(entries($type),0,50) as $v){$rows[]=['id'=>$v['id']??'','type'=>$type,'title'=>$v['title']??'','body'=>mobile_text(strip_tags((string)($v['body']??'')),4000),'image'=>$v['image']??'','created_at'=>$v['created_at']??''];}mobile_json(['ok'=>true,'items'=>$rows]);
}
$u=mobile_auth();$db=mobile_db();$uid=$u['user_id'];$admin=in_array($u['user_role'],['admin','admin_kelurahan'],true);
if(in_array($action,['support_admin_thread','officer_reports','officer_waris','officer_report_detail','officer_report_decide','officer_report_photo','territory_monitoring'],true)){
 require_once __DIR__.'/governance_review.php';
 cikoko_governance_dispatch($action,$method,$db,$u);
}

if(in_array($action,['waris_format','waris_stage'],true)){
 require_once __DIR__.'/waris_staging.php';
 cikoko_waris_stage_route($action,$method,$u,(string)$uid);
}

if(in_array($action,[
 'rt_rw_list','rt_rw_submit','rt_rw_decide','rt_rw_reaffirm',
 'rt_rw_officers','rt_rw_officer_assign',
 'rt_rw_signer_status','rt_rw_signer_upload','rt_rw_pdf',
],true)){
 require_once __DIR__.'/rt_rw_service.php';
 cikoko_rt_dispatch($action,$method,$db,$u,(string)$uid);
}

if(in_array($action,[
 'civic_catalog','civic_list','civic_submit','civic_detail',
 'civic_pin_set','civic_review','civic_pdf',
],true)){
 require_once __DIR__.'/rt_rw_service.php';
 require_once __DIR__.'/civic_lpj.php';
 cikoko_civic_dispatch($action,$method,$db,$u,(string)$uid);
}

if(in_array($action,['waris_witness_capabilities','waris_add_witnesses'],true)){
 require_once __DIR__.'/waris_witnesses.php';
 cikoko_waris_witness_dispatch($action,$method,$db,$u,(string)$uid);
}
require_once __DIR__.'/waris_review.php';
if(in_array($action,['document_detail','waris_attachment','waris_request_correction','waris_resubmit'],true))waris_review_dispatch($action,$method,$db,$u,(string)$uid);
if($action==='me'){
  $profile=['id'=>$uid,'name'=>'Administrator','username'=>$u['username'],'role'=>$u['user_role']];
  if($u['user_role']!=='admin'){
    foreach(db_read('portal_users') as $entry){
      if((string)($entry['id']??'')===(string)$uid){
        $profile=['id'=>$uid,'name'=>(string)($entry['name']??''),'username'=>(string)($entry['username']??''),'role'=>$u['user_role'],
          'phone'=>(string)($entry['phone']??''),'email'=>(string)($entry['email']??''),'address'=>(string)($entry['address']??''),'nik'=>(string)($entry['nik']??''),
           'rt'=>(string)($entry['rt']??''),'rw'=>(string)($entry['rw']??'')];
        break;
      }
    }
  }
  mobile_json(['ok'=>true,'user'=>$profile]);
}
// Manajemen akun: hak eksklusif Admin Utama. Penghapusan akun tidak
// menghapus laporan/arsip historis yang diperlukan untuk audit.
if(in_array($action,['accounts_list','accounts_create','accounts_delete'],true)){
 if((string)$u['user_role']!=='admin')mobile_error('Hanya Admin Utama yang dapat mengelola akun petugas.',403);
 if($action==='accounts_list'&&$method==='GET'){
  $items=[];
  foreach(db_read('portal_users') as $entry){
   if(($entry['role']??'')==='admin')continue;
   $items[]=['id'=>(string)($entry['id']??''),'name'=>(string)($entry['name']??''),
    'username'=>(string)($entry['username']??''),'role'=>(string)($entry['role']??''),
    'rt'=>(string)($entry['rt']??''),'rw'=>(string)($entry['rw']??''),
    'active'=>(bool)($entry['active']??false)];
  }
  mobile_json(['ok'=>true,'roles'=>portal_roles(),'items'=>$items]);
 }
 if($method!=='POST')mobile_error('Metode tidak diizinkan.',405);
 $b=mobile_body();
 if($action==='accounts_create'){
  $name=mobile_text($b['name']??'',120);$username=mobile_text($b['username']??'',80);
  $password=(string)($b['password']??'');$role=mobile_text($b['role']??'',50);
  $allowed=portal_roles();unset($allowed['warga']);
  if(!isset($allowed[$role])||mobile_strlen($name)<3||
    !preg_match('/^[a-zA-Z0-9_.-]{4,40}$/',$username)||strlen($password)<8)
   mobile_error('Periksa nama, username, password dan peran.',422);
  $users=db_read('portal_users');
  if(strcasecmp((string)(db_read('admin')['username']??''),$username)===0)
   mobile_error('Username sudah digunakan.',409);
  foreach($users as $entry)if(strcasecmp((string)($entry['username']??''),$username)===0)
   mobile_error('Username sudah digunakan.',409);
  $users[]=['id'=>bin2hex(random_bytes(12)),'name'=>$name,'username'=>$username,
   'password_hash'=>password_hash($password,PASSWORD_DEFAULT),'role'=>$role,
   'department'=>(string)$allowed[$role],'rt'=>mobile_text($b['rt']??'',12),
   'rw'=>mobile_text($b['rw']??'',12),'phone'=>mobile_text($b['phone']??'',40),
   'email'=>mobile_text($b['email']??'',160),'active'=>true,'created_at'=>date('c')];
  if(!db_write('portal_users',$users))mobile_error('Akun gagal disimpan.',503);
  mobile_json(['ok'=>true,'message'=>'Akun petugas berhasil dibuat.']);
 }
 if($action==='accounts_delete'){
  $id=mobile_text($b['id']??'',80);
  $confirmation=mobile_text($b['confirm_username']??'',100);
  if($id===''||$confirmation==='')mobile_error('Konfirmasi akun diperlukan.',422);
  if($id===(string)$uid||$id==='admin')mobile_error('Akun Admin Utama tidak dapat dihapus.',403);
  $users=db_read('portal_users');$found=null;$remaining=[];
  foreach($users as $entry){
   if((string)($entry['id']??'')===$id){$found=$entry;continue;}
   $remaining[]=$entry;
  }
  if(!$found)mobile_error('Akun tidak ditemukan atau sudah dihapus.',404);
  if(($found['role']??'')==='admin'||($found['role']??'')==='warga')
   mobile_error('Hanya akun petugas dan pegawai yang dapat dihapus.',403);
  if(!hash_equals((string)($found['username']??''),$confirmation))
   mobile_error('Username konfirmasi tidak sesuai.',422);
  if(!db_write('portal_users',$remaining))mobile_error('Penghapusan akun gagal disimpan.',503);
  // Putus semua sesi dan token notifikasi milik akun terhapus.
  $db->prepare('DELETE FROM mobile_tokens WHERE user_id=?')->execute([$id]);
  $db->prepare('DELETE FROM mobile_devices WHERE user_id=?')->execute([$id]);
  mobile_json(['ok'=>true,'message'=>'Akun dihapus permanen. Riwayat laporan tetap tersimpan.']);
 }
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
    $entry['name']=$name;$entry['phone']=$phone;$entry['email']=$email;$entry['address']=$address;
    $result=['id'=>$uid,'name'=>$name,'username'=>(string)$entry['username'],'role'=>$u['user_role'],
      'phone'=>$phone,'email'=>$email,'address'=>$address,'nik'=>(string)($entry['nik']??'')];
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
// Release only this account/device pair. Never delete another account's device.
if($action==='device_unregister'&&$method==='POST'){
 $b=mobile_body();$token=mobile_text($b['fcm_token']??'',255);
 if(strlen($token)<40)mobile_error('Token perangkat tidak valid',422);
 $st=$db->prepare('DELETE FROM mobile_devices WHERE user_id=? AND fcm_token=?');
 $st->execute([(string)$uid,$token]);
 mobile_json(['ok'=>true,'message'=>'Perangkat dilepas dari notifikasi akun.']);
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
// Account inbox: never mix broadcast, other staff, or other applicants here.
// Public news and aggregate submission counts remain on the Beranda endpoints.
if($action==='events'){
 waris_review_schema($db);
 $sql='SELECT e.id,e.category,e.title,e.message,e.created_at,e.audience,e.recipient,l.object_type,l.object_id,IF(r.event_id IS NULL,0,1) AS is_read
   FROM mobile_events e
   LEFT JOIN mobile_event_links l ON l.event_id=e.id
   LEFT JOIN mobile_event_reads r ON r.event_id=e.id AND r.user_id=:viewer
   WHERE e.audience="personal" AND e.recipient=:recipient
   ORDER BY e.id DESC LIMIT 60';
 $q=$db->prepare($sql);
 $q->execute(['viewer'=>(string)$uid,'recipient'=>(string)$uid]);
 $rows=$q->fetchAll(PDO::FETCH_ASSOC);
 mobile_json(['ok'=>true,'events'=>$rows,'unread_count'=>count(array_filter($rows,static fn($r)=>(int)$r['is_read']===0))]);
}
if($action==='event_read'&&$method==='POST'){
 $b=mobile_body();$id=(int)($b['id']??0);
 if($id<1)mobile_error('Pilih notifikasi yang ingin dibaca.',422);
 $q=$db->prepare('SELECT id FROM mobile_events WHERE id=? AND audience="personal" AND recipient=?');
 $q->execute([$id,(string)$uid]);
 if(!$q->fetchColumn())mobile_error('Notifikasi tidak tersedia untuk akun ini.',404);
 $db->prepare('INSERT IGNORE INTO mobile_event_reads(user_id,event_id) VALUES(?,?)')->execute([(string)$uid,$id]);
 mobile_json(['ok'=>true,'message'=>'Notifikasi telah dibaca.']);
}
if($action==='chat_send'&&$method==='POST'){
 $b=mobile_body();$message=mobile_text($b['message']??'',2500);if(mobile_strlen($message)<2)mobile_error('Pesan terlalu pendek',422);
 $st=$db->prepare('SELECT created_at FROM mobile_chat WHERE user_id=? AND sender="warga" ORDER BY id DESC LIMIT 1');$st->execute([$uid]);$last=$st->fetchColumn();if($last && strtotime($last)>time()-3)mobile_error('Tunggu sebentar sebelum mengirim lagi',429);
 $st=$db->prepare('INSERT INTO mobile_chat(user_id,name,sender,message) VALUES(?,?,?,?)');$st->execute([$uid,$u['username'],'warga',$message]);$sentId=(int)$db->lastInsertId();mobile_emit('chat','Pesan warga baru','Ada pesan baru untuk admin','admin');mobile_json(['ok'=>true,'id'=>$sentId,'sender'=>'warga','created_at'=>date('Y-m-d H:i:s'),'delivery_status'=>'sent']);
}
if($action==='chat'&&$method==='GET'){
 mobile_json(cikoko_chat_page($db,(string)$uid,'warga'));
}
if($action==='chat_inbox'&&$method==='GET'){
 // A resident receives messages when the authenticated app polls its inbox.
 $q=$db->prepare('SELECT MAX(id) FROM mobile_chat WHERE user_id=? AND sender="admin"');
 $q->execute([(string)$uid]);$last=(int)$q->fetchColumn();
 if($last>0)cikoko_chat_ack($db,(string)$uid,'warga','delivered',$last);
 mobile_json(['ok'=>true,'latest_admin_id'=>$last]);
}
if($action==='chat_threads'){
 mobile_need($u,'chat:reply');
 $before=max(0,(int)($_GET['before_id']??0));$search=mobile_text($_GET['search']??'',100);
 $sql='SELECT m.id,m.user_id,m.name,m.message,m.created_at FROM mobile_chat m INNER JOIN (SELECT user_id,MAX(id) AS last_id FROM mobile_chat GROUP BY user_id) z ON m.id=z.last_id WHERE 1=1';$args=[];
 if($before>0){$sql.=' AND m.id<?';$args[]=$before;}
 if($search!==''){$sql.=' AND (m.name LIKE ? OR m.message LIKE ?)';$args[]='%'.$search.'%';$args[]='%'.$search.'%';}
 $q=$db->prepare($sql.' ORDER BY m.id DESC LIMIT 51');$q->execute($args);$rows=$q->fetchAll();$more=count($rows)>50;
 $rows=array_slice($rows,0,50);
 // Viewing the admin inbox means delivered, not read. Reading requires the thread.
 foreach($rows as $thread){
   $owner=(string)$thread['user_id'];if($owner==='')continue;
   $q=$db->prepare('SELECT MAX(id) FROM mobile_chat WHERE user_id=? AND sender="warga"');
   $q->execute([$owner]);$lastId=(int)$q->fetchColumn();
   if($lastId>0)cikoko_chat_ack($db,$owner,'admin','delivered',$lastId);
 }
 mobile_json(['ok'=>true,'threads'=>$rows,'has_more'=>$more]);
}
if($action==='chat_reply'&&$method==='POST'){
 mobile_need($u,'chat:reply');$b=mobile_body();$target=mobile_text($b['user_id']??'',80);$msg=mobile_text($b['message']??'',2500);if($target===''||$msg==='')mobile_error('Isi penerima dan pesan',422);
 $chk=$db->prepare('SELECT name FROM mobile_chat WHERE user_id=? LIMIT 1');$chk->execute([$target]);if(!$chk->fetch())mobile_error('Penerima tidak ditemukan',404);
 $st=$db->prepare('INSERT INTO mobile_chat(user_id,name,sender,message) VALUES(?,?,"admin",?)');$st->execute([$target,'Admin Kelurahan',$msg]);$sentId=(int)$db->lastInsertId();mobile_emit('chat','Pesan dibalas oleh Admin','Buka Hubungi Kami untuk melihat balasan','personal',$target);mobile_json(['ok'=>true,'id'=>$sentId,'sender'=>'admin','created_at'=>date('Y-m-d H:i:s'),'delivery_status'=>'sent']);
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
 $children=min(10,max(0,(int)($_POST['child_count']??0)));
 $split=($_POST['document_format']??'')==='split_v1';
 $draft='';$staged=[];
 if($split){
  require_once __DIR__.'/waris_staging.php';
  $draft=cikoko_waris_stage_key($_POST['draft_key']??'');
  $staged=cikoko_waris_stage_collect((string)$uid,$draft,$children);
 }else{
  foreach(['r1','r2','r3','r4','r5','r6'] as $k)
   if(!isset($_FILES[$k])||$_FILES[$k]['error']!==UPLOAD_ERR_OK)
    mobile_error('Persyaratan foto belum lengkap: '.$k,422);
  for($i=1;$i<=$children;$i++)
   if(!isset($_FILES['child_'.$i]))mobile_error('Foto anak ke-'.$i.' belum ada',422);
 }
 $reference='AW-'.date('Ymd').'-'.strtoupper(bin2hex(random_bytes(4)));
 $db->beginTransaction();$paths=[];
 try {
  $names=[];for($i=1;$i<=$children;$i++)$names[]=['number'=>$i,'name'=>mobile_text($_POST['child_name_'.$i]??'',180)];
  $sql='INSERT INTO aw_applications(reference_no,account_id,applicant_name,applicant_nik,applicant_phone,applicant_address,relationship,deceased_name,marital_status,deceased_birthplace,deceased_birthdate,deceased_deathdate,deceased_marriage_date,heirs,children_json) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)';
  $db->prepare($sql)->execute([$reference,$uid,mobile_text($_POST['name'],160),$nik,mobile_text($_POST['phone'],40),mobile_text($_POST['address'],3000),mobile_text($_POST['relation'],100),mobile_text($_POST['deceased_name'],200),mobile_text($_POST['marital_status']??'Tidak diketahui',40),mobile_text($_POST['birthplace']??'',160),($_POST['birthdate']??'')?:null,($_POST['deathdate']??'')?:null,($_POST['marriage_date']??'')?:null,mobile_text($_POST['heirs'],12000),json_encode($names,JSON_UNESCAPED_UNICODE)]);
  $id=(int)$db->lastInsertId();$ins=$db->prepare('INSERT INTO aw_attachments(application_id,requirement_code,original_name,storage_name,mime_type,size_bytes) VALUES(?,?,?,?,?,?)');
  $dir=dirname(__DIR__).'/ahli-waris/private/uploads';if(!is_dir($dir))mkdir($dir,0750,true);
  if($split){cikoko_waris_stage_persist($staged,$dir,$id,$ins,$paths);}
  else {
  foreach(array_merge(['r1','r2','r3','r4','r5','r6','r7','r8'],($children>0?array_map(fn($n)=>'child_'.$n,range(1,$children)):[])) as $key){$f=$_FILES[$key]??null;if(!$f||($f['error']??4)===UPLOAD_ERR_NO_FILE)continue;
   if(($f['error']??4)!==UPLOAD_ERR_OK||($f['size']??0)>4*1024*1024||!is_uploaded_file($f['tmp_name']))throw new RuntimeException('Foto '.$key.' gagal atau melebihi 4 MB');
   $mime=(new finfo(FILEINFO_MIME_TYPE))->file($f['tmp_name']);$ext=['image/jpeg'=>'jpg','image/png'=>'png','image/webp'=>'webp'][$mime]??null;if(!$ext)throw new RuntimeException('Foto '.$key.' harus JPG/PNG/WebP');
   $name=bin2hex(random_bytes(20)).'.'.$ext;if(!move_uploaded_file($f['tmp_name'],$dir.'/'.$name))throw new RuntimeException('Simpan dokumen gagal');$paths[]=$dir.'/'.$name;$ins->execute([$id,$key,basename($f['name']),$name,$mime,(int)$f['size']]);
  }
  }
  $db->prepare('INSERT INTO aw_history(application_id,previous_status,new_status,actor_id,notes) VALUES (?,NULL,"masuk",?,"Permohonan dari Android")')->execute([$id,$uid]);$db->commit();
  if($split)cikoko_waris_stage_clean((string)$uid,$draft);
 }catch(Throwable $e){if($db->inTransaction())$db->rollBack();foreach($paths as $f)@unlink($f);error_log('Waris mobile upload error: '.$e->getMessage());mobile_error('Permohonan belum berhasil disimpan. Data tetap berada di formulir. Periksa dokumen atau hubungi admin jika masalah berulang.',503);}
 mobile_emit('surat','Surat Ahli Waris baru','Pengajuan '.$reference.' masuk','admin');waris_review_schema($db);waris_emit_link($db,'waris',$id,'progres_surat','Permohonan diterima',$reference,'personal',(string)$uid);mobile_json(['ok'=>true,'reference'=>$reference]);
}
if($action==='history'){
 $st=$db->prepare('SELECT id,kind AS title,"report" AS kind,status,created_at FROM mobile_reports WHERE user_id=? ORDER BY id DESC LIMIT 70');$st->execute([$uid]);$rows=$st->fetchAll();
 try{$st=$db->prepare('SELECT id,reference_no AS reference,"Ahli Waris" AS title,"waris" AS kind,status,created_at FROM aw_applications WHERE account_id=? ORDER BY id DESC LIMIT 70');$st->execute([$uid]);$rows=array_merge($rows,$st->fetchAll());}catch(Throwable $e){error_log('waris history: '.$e->getMessage());}
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
  mobile_need($u,'waris:verify');
  $st=$db->prepare('SELECT account_id,status FROM aw_applications WHERE id=?');$st->execute([$id]);$row=$st->fetch();if(!$row)mobile_error('Permohonan tidak ditemukan',404);
  $db->prepare('UPDATE aw_applications SET status=? WHERE id=?')->execute([$status,$id]);$db->prepare('INSERT INTO aw_history(application_id,previous_status,new_status,actor_id,notes) VALUES (?,?,?,?,?)')->execute([$id,$row['status'],$status,$uid,'Pembaruan via aplikasi']);$owner=$row['account_id'];
 }else{
  $st=$db->prepare('SELECT user_id FROM mobile_reports WHERE id=?');$st->execute([$id]);$owner=$st->fetchColumn();if(!$owner)mobile_error('Laporan tidak ditemukan',404);
  $db->prepare('UPDATE mobile_reports SET status=? WHERE id=?')->execute([$status,$id]);
 }
 if($kind==='waris'){waris_review_schema($db);waris_emit_link($db,'waris',$id,'progres_surat','Status Ahli Waris: '.ucfirst($status),'Periksa rincian dan progres surat Anda.','personal',(string)$owner);}else{mobile_emit('progres_surat','Status permohonan: '.ucfirst($status),'Periksa rincian permohonan pada aplikasi','personal',(string)$owner);}mobile_json(['ok'=>true]);
}
if($action==='admin_waris_date'&&$method==='POST'){
 if(($u['user_role']??'')!=='admin')mobile_error('Perubahan tanggal pengajuan hanya dapat dilakukan Admin Utama.',403);
 mobile_need($u,'reports:verify');
 $b=mobile_body();if(!$b && !empty($_POST))$b=$_POST;
 $id=(int)($b['id']??0);$date=trim((string)($b['date']??''));
 if($id<1)mobile_error('ID permohonan tidak valid.',422);
 if(!preg_match('/^\d{4}-\d{2}-\d{2}$/',$date)||!checkdate((int)substr($date,5,2),(int)substr($date,8,2),(int)substr($date,0,4))||strtotime($date)>time()+86400)mobile_error('Format tanggal tidak valid atau masih di masa depan.',422);
 $db->beginTransaction();
 try{
  $st=$db->prepare('SELECT id,account_id,status,reference_no,created_at FROM aw_applications WHERE id=? FOR UPDATE');$st->execute([$id]);$app=$st->fetch(PDO::FETCH_ASSOC);if(!$app)throw new RuntimeException('Permohonan tidak ditemukan.');
  $old=(string)($app['created_at']??'');$oldDate=strlen($old)>=10?substr($old,0,10):'';
  if($oldDate===$date)throw new RuntimeException('Tanggal pengajuan tidak berubah.');
  $time=(strlen($old)>=19?substr($old,11,8):'00:00:00');$newDt=$date.' '.$time;
  $delta=strtotime($newDt)-strtotime($old);
  $db->prepare('UPDATE aw_applications SET created_at=? WHERE id=?')->execute([$newDt,$id]);
  // Geser SELURUH tanggal di riwayat progres (progres) agar konsisten dengan tanggal pengajuan baru.
  $db->prepare('UPDATE aw_history SET created_at=DATE_ADD(created_at, INTERVAL ? SECOND) WHERE application_id=?')->execute([$delta,$id]);
  $db->prepare('INSERT INTO aw_history(application_id,previous_status,new_status,actor_id,notes) VALUES(?,?,?,?,?)')->execute([$id,$app['status'],$app['status'],$uid,'Tanggal pengajuan diubah admin: '.$oldDate.' → '.$date.' (seluruh riwayat progres digeser otomatis)']);
  $db->commit();
 }catch(Throwable $e){if($db->inTransaction())$db->rollBack();mobile_error($e->getMessage(),422);}
 try{waris_review_schema($db);waris_emit_link($db,'waris',$id,'progres_surat','Tanggal pengajuan diperbarui','Tanggal pengajuan Ahli Waris diubah menjadi '.$date.'. Seluruh tanggal di riwayat progres (progres) digeser otomatis.','personal',(string)$app['account_id']);}catch(Throwable $e){error_log('admin_waris_date notify: '.$e->getMessage());}
 mobile_json(['ok'=>true,'message'=>'Tanggal pengajuan dan SELURUH tanggal di riwayat progres (progres) telah digeser otomatis.']);
}
mobile_error('Endpoint tidak tersedia',404);

