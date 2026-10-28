<?php
declare(strict_types=1);
/**
 * Add missing KTP saksi to existing Ahli Waris submissions.
 * Uses existing aw_applications, aw_attachments and aw_history tables.
 * No migrations, UPDATE of application rows, or replacement of older files.
 * The caller (mobile-api/index.php) already authenticated the Bearer token.
 */
function cikoko_waris_witness_dispatch(string $action,string $method,PDO $db,array $u,string $uid):void {
    if($action==='waris_witness_capabilities'){
        if($method!=='GET')mobile_error('Metode tidak tersedia.',405);
        mobile_json(['ok'=>true,'supported'=>true,'codes'=>['saksi_1','saksi_2']]);
    }
    if($action!=='waris_add_witnesses'||$method!=='POST')mobile_error('Layanan tidak ditemukan.',404);
    $id=(int)($_POST['application_id']??0);
    $reference=trim((string)($_POST['reference']??''));
    if($id<1 && ($reference==='' || strlen($reference)>120))mobile_error('Nomor pengajuan tidak valid.',422);
    $allowed=['saksi_1'=>'KTP Saksi Pertama','saksi_2'=>'KTP Saksi Kedua'];
    $codes=array_keys($_FILES);
    if(!$codes||count($codes)>2)mobile_error('Pilih satu atau kedua KTP saksi.',422);
    foreach($codes as $code){
        if(!isset($allowed[$code]))mobile_error('Jenis foto yang dikirim tidak sesuai.',422);
        $file=$_FILES[$code];
        if(!is_array($file)||is_array($file['name'])||($file['error']??4)!==UPLOAD_ERR_OK
          ||($file['size']??0)<100||$file['size']>4*1024*1024
          ||!isset($file['tmp_name'])||!is_uploaded_file($file['tmp_name'])){
            mobile_error('Foto '.$allowed[$code].' tidak dapat diterima. Gunakan JPG, PNG atau WebP maksimal 4 MB.',422);
        }
    }
    $dir=dirname(__DIR__).'/ahli-waris/private/uploads';
    if(!is_dir($dir)&&!@mkdir($dir,0750,true))mobile_error('Penyimpanan dokumen belum tersedia.',503);
    $savedPaths=[];$app=null;
    try{
        $db->beginTransaction();
        if($id>0){
            $q=$db->prepare('SELECT id,account_id,status,reference_no FROM aw_applications WHERE id=? FOR UPDATE');
            $q->execute([$id]);
        }else{
            $q=$db->prepare('SELECT id,account_id,status,reference_no FROM aw_applications WHERE reference_no=? FOR UPDATE');
            $q->execute([$reference]);
        }
        $app=$q->fetch(PDO::FETCH_ASSOC);
        if(!$app)throw new DomainException('Pengajuan tidak ditemukan.',404);
        if(!hash_equals((string)$app['account_id'],$uid))throw new DomainException('Hanya pemohon yang dapat melengkapi dokumen.',403);
        if((string)$app['status']==='ditolak')throw new DomainException('Pengajuan yang ditolak tidak dapat ditambahkan lampiran.',409);
        $applicationId=(int)$app['id'];
        $q=$db->prepare('SELECT requirement_code FROM aw_attachments WHERE application_id=? AND requirement_code IN ("saksi_1","saksi_2")');
        $q->execute([$applicationId]);
        $previous=$q->fetchAll(PDO::FETCH_COLUMN);
        foreach($codes as $code){
            if(in_array($code,$previous,true))throw new DomainException('KTP saksi sudah tersimpan. Dokumen lama tidak akan ditimpa.',409);
        }
        $insert=$db->prepare('INSERT INTO aw_attachments(application_id,requirement_code,original_name,storage_name,mime_type,size_bytes) VALUES(?,?,?,?,?,?)');
        foreach($codes as $code){
            $file=$_FILES[$code];
            $mime=(new finfo(FILEINFO_MIME_TYPE))->file($file['tmp_name']);
            $ext=['image/jpeg'=>'jpg','image/png'=>'png','image/webp'=>'webp'][$mime]??null;
            if(!$ext)throw new DomainException('Foto saksi harus JPG, PNG atau WebP.',422);
            $storage=bin2hex(random_bytes(20)).'.'.$ext;
            $path=$dir.'/'.$storage;
            if(!move_uploaded_file($file['tmp_name'],$path))throw new RuntimeException('Tidak dapat menyimpan foto saksi.');
            $savedPaths[]=$path;
            $insert->execute([$applicationId,$code,mobile_text($file['name'],200),$storage,$mime,(int)$file['size']]);
        }
        $history=$db->prepare('INSERT INTO aw_history(application_id,previous_status,new_status,actor_id,notes) VALUES(?,?,?,?,?)');
        $history->execute([$applicationId,$app['status'],$app['status'],$uid,'Pelengkapan KTP dua orang saksi: '.implode(', ',$codes)]);
        $db->commit();
    }catch(DomainException $e){
        if($db->inTransaction())$db->rollBack();
        foreach($savedPaths as $path)@unlink($path);
        mobile_error($e->getMessage(),$e->getCode()>=400?$e->getCode():422);
    }catch(Throwable $e){
        if($db->inTransaction())$db->rollBack();
        foreach($savedPaths as $path)@unlink($path);
        error_log('Cikoko saksi upload: '.$e->getMessage());
        mobile_error('Dokumen saksi belum berhasil disimpan. Silakan coba kembali.',503);
    }
    // Inform the existing admin workflow without changing the request status.
    mobile_emit('surat','KTP Saksi Ahli Waris dilengkapi','Periksa kelengkapan pengajuan '.$app['reference_no'],'admin');
    mobile_json(['ok'=>true,'reference'=>$app['reference_no'],'uploaded_codes'=>$codes]);
}
