<?php
declare(strict_types=1);

/**
 * Resident-owned staging for split_v1 inheritance documents.
 * Files are kept behind mobile-api/private/.htaccess. A draft can only be
 * accessed using the authenticated account's own hashed private folder.
 */
function cikoko_waris_stage_key($value):string {
    $key=(string)$value;
    if(!preg_match('/^[a-f0-9]{32}$/D',$key))
        mobile_error('Kunci draft unggahan tidak valid.',422);
    return $key;
}
function cikoko_waris_stage_allowed(string $key):bool {
    return in_array($key,['r1','r2','r3','r4_ktp','r4_kk','r4_akta','r5','r6','r7','r8'],true)
       ||preg_match('/^child_([1-9]|10)_(ktp|kk|akta)$/D',$key)===1;
}
function cikoko_waris_stage_dir(string $uid,string $draft,bool $create=false):string {
    $folder=__DIR__.'/private/waris_staging/'.hash('sha256',$uid).'/'.$draft;
    if($create && !is_dir($folder) && !@mkdir($folder,0750,true))
        mobile_error('Penyimpanan dokumen sementara belum tersedia.',503);
    return $folder;
}
function cikoko_waris_stage_manifest(string $directory):array {
    $path=$directory.'/manifest.json';
    if(!is_file($path))return [];
    $result=json_decode((string)@file_get_contents($path),true);
    return is_array($result)?$result:[];
}
function cikoko_waris_stage_route(string $action,string $method,array $u,string $uid):void {
    mobile_need($u,'waris:create');
    if($action==='waris_format'){
        if($method!=='GET')mobile_error('Metode tidak diizinkan.',405);
        mobile_json(['ok'=>true,'upload_format'=>'split_v1',
          'staged_uploads'=>true,'max_file_uploads'=>8,
          'max_file_size_mb'=>4]);
    }
    if($action!=='waris_stage'||$method!=='POST')
        mobile_error('Metode unggah tidak tersedia.',405);
    $draft=cikoko_waris_stage_key($_POST['draft_key']??'');
    $files=$_FILES;
    if(count($files)<1||count($files)>8)
        mobile_error('Unggah 1 sampai 8 gambar untuk setiap tahap.',422);
    $directory=cikoko_waris_stage_dir($uid,$draft,true);
    $manifest=cikoko_waris_stage_manifest($directory);
    foreach($files as $key=>$file){
        if(!cikoko_waris_stage_allowed((string)$key) || !is_array($file)||
           is_array($file['name']??null)||!is_uploaded_file((string)($file['tmp_name']??''))||
           ($file['error']??UPLOAD_ERR_NO_FILE)!==UPLOAD_ERR_OK||
           ($file['size']??0)<1||($file['size']??0)>4*1024*1024)
            mobile_error('Gambar dokumen tidak valid atau melebihi batas 4 MB.',422);
        $mime=(new finfo(FILEINFO_MIME_TYPE))->file($file['tmp_name']);
        $extension=['image/jpeg'=>'jpg','image/png'=>'png','image/webp'=>'webp'][$mime]??null;
        if(!$extension||@getimagesize($file['tmp_name'])===false)
            mobile_error('Foto dokumen harus berupa gambar JPG/PNG/WebP.',422);
        $name=(string)$key.'.'.$extension;
        $destination=$directory.'/'.$name;
        if(!move_uploaded_file($file['tmp_name'],$destination))
            mobile_error('Gambar sementara gagal disimpan.',503);
        @chmod($destination,0600);
        if(isset($manifest[$key]['storage']) && $manifest[$key]['storage']!==$name)
            @unlink($directory.'/'.basename((string)$manifest[$key]['storage']));
        $manifest[$key]=['storage'=>$name,'name'=>basename((string)$file['name']),
          'mime'=>$mime,'size'=>(int)$file['size']];
    }
    if(count($manifest)>45)mobile_error('Terlalu banyak dokumen dalam satu pengajuan.',422);
    $json=json_encode($manifest,JSON_UNESCAPED_UNICODE|JSON_THROW_ON_ERROR);
    if(@file_put_contents($directory.'/manifest.json',$json,LOCK_EX)===false)
        mobile_error('Daftar dokumen sementara gagal disimpan.',503);
    mobile_json(['ok'=>true,'stored'=>count($manifest),'draft_key'=>$draft]);
}
function cikoko_waris_stage_collect(string $uid,string $draft,int $children):array {
    $directory=cikoko_waris_stage_dir($uid,$draft);
    if(!is_dir($directory))mobile_error('Dokumen sementara tidak ditemukan. Pilih ulang foto.',409);
    $manifest=cikoko_waris_stage_manifest($directory);
    $required=['r1','r2','r3','r4_ktp','r4_kk','r4_akta','r5','r6'];
    for($i=1;$i<=$children;$i++)
        foreach(['ktp','kk','akta'] as $part)$required[]='child_'.$i.'_'.$part;
    foreach($required as $key)if(!isset($manifest[$key]))
        mobile_error('Foto persyaratan belum lengkap: '.$key,422);
    $result=[];
    foreach($manifest as $code=>$entry){
        if(!cikoko_waris_stage_allowed((string)$code)||!is_array($entry))
            mobile_error('Daftar dokumen sementara tidak valid.',422);
        $stored=(string)($entry['storage']??'');
        if($stored===''||!preg_match('/^[a-z0-9_]+\.(jpg|png|webp)$/D',$stored))
            mobile_error('Nama dokumen tidak valid.',422);
        $path=$directory.'/'.$stored;
        if(!is_file($path)||filesize($path)>4*1024*1024||filesize($path)<1)
            mobile_error('File sementara hilang atau rusak. Unggah ulang.',409);
        $result[$code]=[
          'path'=>$path,'name'=>mobile_text($entry['name']??$stored,200),
          'mime'=>(string)$entry['mime'],'size'=>(int)$entry['size'],
        ];
    }
    return $result;
}
function cikoko_waris_stage_persist(array $items,string $uploads,int $id,
   PDOStatement $insert,array &$paths):void {
    foreach($items as $code=>$entry){
        if(!cikoko_waris_stage_allowed((string)$code))throw new RuntimeException('Kode dokumen tidak valid');
        $extension=['image/jpeg'=>'jpg','image/png'=>'png','image/webp'=>'webp'][$entry['mime']]??null;
        if(!$extension)throw new RuntimeException('Format dokumen tidak valid');
        $name=bin2hex(random_bytes(20)).'.'.$extension;
        if(!@copy($entry['path'],$uploads.'/'.$name))
            throw new RuntimeException('Dokumen sementara tidak dapat dipindahkan');
        @chmod($uploads.'/'.$name,0600);
        $paths[]=$uploads.'/'.$name;
        $insert->execute([$id,$code,$entry['name'],$name,$entry['mime'],$entry['size']]);
    }
}
function cikoko_waris_stage_clean(string $uid,string $draft):void {
    $directory=cikoko_waris_stage_dir($uid,$draft);
    foreach(cikoko_waris_stage_manifest($directory) as $entry){
        $filename=basename((string)($entry['storage']??''));
        if($filename!==''&&$filename!=='.')@unlink($directory.'/'.$filename);
    }
    @unlink($directory.'/manifest.json');
    @rmdir($directory);
}
