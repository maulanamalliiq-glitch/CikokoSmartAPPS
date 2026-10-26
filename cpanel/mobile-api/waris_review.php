<?php
declare(strict_types=1);
// Cikoko v207: private request details, correction requests, replacement uploads.
// Included from index.php only AFTER mobile_auth(); $u/$uid/$db already exist.
function waris_review_schema(PDO $db):void {
    static $ready=false;
    if($ready)return;
    try {
        $db->exec('CREATE TABLE IF NOT EXISTS mobile_waris_corrections (
            id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            application_id BIGINT UNSIGNED NOT NULL,
            requirement_code VARCHAR(40) NOT NULL,
            reason VARCHAR(1000) NOT NULL,
            requested_by VARCHAR(100) NOT NULL,
            requested_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            resolved_at DATETIME NULL,
            UNIQUE KEY uq_application_code(application_id,requirement_code),
            INDEX idx_pending(application_id,resolved_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
        $db->exec('CREATE TABLE IF NOT EXISTS mobile_event_links (
            event_id BIGINT UNSIGNED NOT NULL PRIMARY KEY,
            object_type VARCHAR(20) NOT NULL,
            object_id BIGINT UNSIGNED NOT NULL,
            INDEX idx_object(object_type,object_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
        $ready=true;
    } catch(Throwable $e) {
        error_log('Cikoko correction schema: '.$e->getMessage());
        mobile_error('Database perlu migrasi v207. Jalankan mobile-api/migrate_waris_v207.sql.',503);
    }
}
/**
 * A document is stored under its own requirement code; legacy combined codes
 * remain recognizable for previously submitted applications and revisions.
 */
function waris_required_upload_codes(int $childCount,bool $split):array {
    $codes=$split
      ? ['r1','r2','r3','r4_ktp','r4_kk','r4_akta','r5','r6']
      : ['r1','r2','r3','r4','r5','r6'];
    for($i=1;$i<=max(0,min(10,$childCount));$i++){
        if($split){
            foreach(['ktp','kk','akta'] as $kind)$codes[]='child_'.$i.'_'.$kind;
        }else{
            $codes[]='child_'.$i;
        }
    }
    return $codes;
}
function waris_codes(int $childCount=10):array {
    $codes=['r1'=>'Surat Pengantar RT/RW','r2'=>'Surat Permohonan','r3'=>'Surat Pernyataan Keabsahan',
       'r4'=>'KTP, KK dan Akta Lahir Ahli Waris (dokumen lama)',
       'r4_ktp'=>'KTP Ahli Waris','r4_kk'=>'KK Ahli Waris','r4_akta'=>'Akta Lahir Ahli Waris',
       'r5'=>'Surat Kematian Pewaris','r6'=>'Surat Nikah Pewaris',
       'r7'=>'Akta Cerai (bila berlaku)','r8'=>'Surat Kematian Ahli Waris (bila berlaku)'];
    for($i=1;$i<=max(0,min(10,$childCount));$i++){
        $codes['child_'.$i]='Foto dokumen Anak ke-'.$i.' (dokumen lama)';
        $codes['child_'.$i.'_ktp']='KTP Anak ke-'.$i;
        $codes['child_'.$i.'_kk']='KK Anak ke-'.$i;
        $codes['child_'.$i.'_akta']='Akta Lahir Anak ke-'.$i;
    }
    return $codes;
}
function waris_children(array $app):array {
    $decoded=json_decode((string)($app['children_json']??'[]'),true);
    return is_array($decoded)?$decoded:[];
}
function waris_load(PDO $db,int $id,array $u,bool $edit=false):array {
    if($id<1)mobile_error('Nomor pengajuan tidak valid.',422);
    $q=$db->prepare('SELECT * FROM aw_applications WHERE id=?');$q->execute([$id]);$app=$q->fetch();
    if(!$app)mobile_error('Pengajuan tidak ditemukan.',404);
    $owner=hash_equals((string)$app['account_id'],(string)$u['user_id']);
    if($edit){if(!mobile_can($u,'waris:verify'))mobile_error('Tidak berwenang meminta perbaikan.',403);}
    elseif(!$owner && !mobile_can($u,'waris:view'))mobile_error('Pengajuan milik akun lain.',403);
    return $app;
}
function waris_emit_link(PDO $db,string $kind,int $id,string $category,string $title,string $message,string $audience,string $recipient):void {
    try {
        $s=$db->prepare('INSERT INTO mobile_events(category,title,message,audience,recipient) VALUES(?,?,?,?,?)');
        $s->execute([$category,mobile_text($title,240),mobile_text($message,2000),$audience,$recipient]);
        $event=(int)$db->lastInsertId();
        $s=$db->prepare('INSERT INTO mobile_event_links(event_id,object_type,object_id) VALUES(?,?,?)');
        $s->execute([$event,$kind,$id]);
    }catch(Throwable $e){error_log('Cikoko linked event: '.$e->getMessage());}
}
function waris_review_dispatch(string $action,string $method,PDO $db,array $u,string $uid):void {
  waris_review_schema($db);
  $type=strtolower((string)($_GET['kind']??'waris'));
  $id=0;
  foreach(['id','application_id','request_id','reference','reference_no'] as $key){
    if(!array_key_exists($key,$_GET))continue;
    $candidate=cikoko_v2525_identifier($db,$_GET[$key],$type);
    if($candidate>0){$id=$candidate;break;}
  }
  if($action==='document_detail' && $method==='GET') {
    $kind=(string)($_GET['kind']??'waris');
    if($kind==='report') {
       $q=$db->prepare('SELECT id,user_id,user_name,user_role,kind,address,phone,notes,status,created_at FROM mobile_reports WHERE id=?');$q->execute([$id]);$report=$q->fetch();
       if(!$report)mobile_error('Laporan tidak ditemukan',404);
       if(!hash_equals((string)$report['user_id'],$uid)&&!mobile_can($u,'reports:view'))mobile_error('Akses laporan ditolak.',403);
       require_once __DIR__.'/report_progress.php';
        $history=cikoko_report_history($db,$id,(string)$report['created_at']);
        mobile_json(['ok'=>true,'kind'=>'report','detail'=>$report,'timeline'=>$history,'corrections'=>[],'documents'=>[]]);
    }
    if($kind!=='waris')mobile_error('Jenis pengajuan tidak dikenal',422);
    $app=waris_load($db,$id,$u);
    $s=$db->prepare('SELECT id,requirement_code,original_name,created_at FROM aw_attachments WHERE application_id=? ORDER BY id DESC');$s->execute([$id]);$attachments=$s->fetchAll();
    $s=$db->prepare('SELECT previous_status,new_status,notes,created_at FROM aw_history WHERE application_id=? ORDER BY id ASC');$s->execute([$id]);$timeline=$s->fetchAll();
    $s=$db->prepare('SELECT requirement_code,reason,requested_at,resolved_at FROM mobile_waris_corrections WHERE application_id=? ORDER BY id');$s->execute([$id]);$corrections=$s->fetchAll();
    $children=waris_children($app);
    $detail=[
      'id'=>(int)$app['id'],'reference_no'=>$app['reference_no'],'status'=>$app['status'],
      'applicant_name'=>$app['applicant_name'],'applicant_nik'=>$app['applicant_nik'],
      'applicant_phone'=>$app['applicant_phone'],'applicant_address'=>$app['applicant_address'],
      'relationship'=>$app['relationship'],'deceased_name'=>$app['deceased_name'],
      'deceased_birthplace'=>$app['deceased_birthplace'],'deceased_birthdate'=>$app['deceased_birthdate'],
      'deceased_deathdate'=>$app['deceased_deathdate'],'deceased_marriage_date'=>$app['deceased_marriage_date'],
      'marital_status'=>$app['marital_status'],'heirs'=>$app['heirs'],'children'=>$children,
      'staff_notes'=>$app['staff_notes'],'created_at'=>$app['created_at']
    ];
    mobile_json(['ok'=>true,'kind'=>'waris','detail'=>$detail,'timeline'=>$timeline,'documents'=>$attachments,'corrections'=>$corrections,'labels'=>waris_codes(count($children)),'can_review'=>mobile_can($u,'waris:verify'),'is_owner'=>hash_equals((string)$app['account_id'],$uid)]);
  }
  if($action==='waris_attachment' && $method==='GET') {
    $q=$db->prepare('SELECT a.application_id,a.storage_name,a.mime_type FROM aw_attachments a WHERE a.id=?');$q->execute([$id]);$file=$q->fetch();
    if(!$file)mobile_error('Foto tidak ditemukan',404);
    waris_load($db,(int)$file['application_id'],$u);
    $dir=realpath(dirname(__DIR__).'/ahli-waris/private/uploads');
    if(!$dir || !preg_match('/^[a-f0-9]{40}\.(jpg|jpeg|png|webp)$/i',(string)$file['storage_name']))mobile_error('Lampiran tidak valid',404);
    $path=realpath($dir.'/'.$file['storage_name']);
    if(!$path || dirname($path)!==$dir || !is_file($path))mobile_error('Foto belum tersedia',404);
    header('Content-Type: '.$file['mime_type']);header('Content-Length: '.filesize($path));
    header('Content-Disposition: inline; filename="dokumen-cikoko.'.pathinfo($path,PATHINFO_EXTENSION).'"');
    header('Cache-Control: private, no-store');readfile($path);exit;
  }
  if($action==='waris_request_correction' && $method==='POST') {
    $body=mobile_body();$id=(int)($body['id']??0);$app=waris_load($db,$id,$u,true);
    if(in_array($app['status'],['selesai','ditolak'],true))mobile_error('Permohonan yang ditutup tidak dapat meminta revisi baru.',409);
    $codes=$body['codes']??[];$reason=mobile_text($body['notes']??'',1000);
    $allowed=waris_codes(count(waris_children($app)));
    if(!is_array($codes)||count($codes)<1||count($codes)>count($allowed)||$reason==='')mobile_error('Pilih dokumen dan isi alasan perbaikan.',422);
    foreach($codes as $code)if(!is_string($code)||!array_key_exists($code,$allowed))mobile_error('Dokumen perbaikan tidak dikenal.',422);
    $codes=array_values(array_unique($codes));
    try {
      $db->beginTransaction();
      $q=$db->prepare('INSERT INTO mobile_waris_corrections(application_id,requirement_code,reason,requested_by,requested_at,resolved_at) VALUES(?,?,?,?,NOW(),NULL) ON DUPLICATE KEY UPDATE reason=VALUES(reason),requested_by=VALUES(requested_by),requested_at=NOW(),resolved_at=NULL');
      foreach($codes as $code)$q->execute([$id,$code,$reason,$uid]);
      $db->prepare('UPDATE aw_applications SET status="revisi",staff_notes=? WHERE id=?')->execute([$reason,$id]);
      $db->prepare('INSERT INTO aw_history(application_id,previous_status,new_status,actor_id,notes) VALUES(?,?,?,?,?)')->execute([$id,$app['status'],'revisi',$uid,$reason]);
      $db->commit();
    }catch(Throwable $e){if($db->inTransaction())$db->rollBack();error_log('waris request revision '.$e->getMessage());mobile_error('Permintaan perbaikan gagal disimpan.',503);}
    waris_emit_link($db,'waris',$id,'progres_surat','Dokumen Ahli Waris perlu diperbaiki',$reason,'personal',(string)$app['account_id']);
    mobile_json(['ok'=>true,'message'=>'Permintaan perbaikan dikirim.']);
  }
  if($action==='waris_resubmit' && $method==='POST') {
    $id=(int)($_POST['application_id']??0);$app=waris_load($db,$id,$u);
    if(!hash_equals((string)$app['account_id'],$uid))mobile_error('Hanya pemohon dapat memperbarui dokumen.',403);
    if($app['status']!=='revisi')mobile_error('Pengajuan tidak dalam status perbaikan.',409);
    $q=$db->prepare('SELECT requirement_code FROM mobile_waris_corrections WHERE application_id=? AND resolved_at IS NULL');$q->execute([$id]);$pending=$q->fetchAll(PDO::FETCH_COLUMN);
    if(!$pending)mobile_error('Belum ada permintaan dokumen.',409);
    $submitted=array_keys($_FILES);if(!$submitted)mobile_error('Silakan pilih foto dokumen yang diminta.',422);
    foreach($submitted as $code)if(!in_array($code,$pending,true))mobile_error('Tidak boleh mengubah dokumen yang tidak diminta: '.$code,403);
    $dir=dirname(__DIR__).'/ahli-waris/private/uploads';if(!is_dir($dir)&&!mkdir($dir,0750,true))mobile_error('Folder penyimpanan tidak tersedia.',503);
    $paths=[];
    try {
      $db->beginTransaction();
      $ins=$db->prepare('INSERT INTO aw_attachments(application_id,requirement_code,original_name,storage_name,mime_type,size_bytes) VALUES(?,?,?,?,?,?)');
      $resolve=$db->prepare('UPDATE mobile_waris_corrections SET resolved_at=NOW() WHERE application_id=? AND requirement_code=? AND resolved_at IS NULL');
      foreach($submitted as $code){$f=$_FILES[$code];
        if(!is_array($f)||is_array($f['name'])||($f['error']??4)!==UPLOAD_ERR_OK||($f['size']??0)<100||$f['size']>4*1024*1024||!is_uploaded_file($f['tmp_name']))throw new RuntimeException('Foto '.$code.' tidak valid atau terlalu besar');
        $mime=(new finfo(FILEINFO_MIME_TYPE))->file($f['tmp_name']);$ext=['image/jpeg'=>'jpg','image/png'=>'png','image/webp'=>'webp'][$mime]??null;if(!$ext)throw new RuntimeException('Format foto harus JPG/PNG/WebP');
        $saved=bin2hex(random_bytes(20)).'.'.$ext;
        if(!move_uploaded_file($f['tmp_name'],$dir.'/'.$saved))throw new RuntimeException('Foto tidak bisa disimpan');
        $paths[]=$dir.'/'.$saved;$ins->execute([$id,$code,mobile_text($f['name'],200),$saved,$mime,(int)$f['size']]);$resolve->execute([$id,$code]);
      }
      $check=$db->prepare('SELECT COUNT(*) FROM mobile_waris_corrections WHERE application_id=? AND resolved_at IS NULL');$check->execute([$id]);$remaining=(int)$check->fetchColumn();
      $newStatus=$remaining===0?'proses':'revisi';
      $db->prepare('UPDATE aw_applications SET status=? WHERE id=?')->execute([$newStatus,$id]);
      $db->prepare('INSERT INTO aw_history(application_id,previous_status,new_status,actor_id,notes) VALUES(?,?,?,?,?)')->execute([$id,$app['status'],$newStatus,$uid,'Dokumen revisi dikirim ulang: '.implode(', ',$submitted)]);
      $db->commit();
    }catch(Throwable $e){if($db->inTransaction())$db->rollBack();foreach($paths as $path)@unlink($path);error_log('waris resubmit '.$e->getMessage());mobile_error('Unggah ulang gagal: '.($e instanceof RuntimeException?$e->getMessage():'Periksa sambungan dan coba lagi'),503);}
    waris_emit_link($db,'waris',$id,'progres_surat','Dokumen pengajuan diperbarui','Foto perbaikan diterima untuk pemeriksaan.','personal',$uid);
    mobile_emit('surat','Pemohon mengunggah ulang berkas','Periksa kembali surat '.$app['reference_no'],'admin');
    mobile_json(['ok'=>true,'remaining'=>$remaining,'status'=>$newStatus]);
  }
  mobile_error('Aksi dokumen tidak dikenali',404);
}
