<?php
declare(strict_types=1);

/**
 * Layanan Terpadu Cikoko.
 * Public URL catalog is readable ONLY by signed-in accounts.
 * Admin Utama can update it. No database tables/records are changed.
 * The store is a PHP file protected with __halt_compiler so arbitrary
 * JSON never executes or becomes readable from a direct HTTP request.
 */
function cikoko_integrated_default():array {
    $names=[
      ['ptsp','PTSP','Pelayanan perizinan dan nonperizinan DKI Jakarta.','https://ptsp.jakarta.go.id/'],
      ['dukcapil','Dukcapil','Administrasi kependudukan dan dokumen warga.','https://kependudukancapil.jakarta.go.id/layanan-online/'],
      ['alpukat','Alpukat Betawi','Permohonan dokumen kependudukan secara daring.','https://alpukat-dukcapil.jakarta.go.id/'],
      ['jakevo','Jak Evo','Pengajuan layanan izin dan nonperizinan.','https://jakevo.jakarta.go.id/'],
      ['sosial','Sosial','Informasi pelayanan kesejahteraan sosial.','https://dinsos.jakarta.go.id/'],
      ['puskesmas','Puskesmas','Informasi pendaftaran dan layanan kesehatan.','https://www.jakarta.go.id/index.php/aplikasi-jaksehat'],
      ['kecamatan','Kecamatan','Pelayanan dan informasi Kecamatan Pancoran.',''],
      ['pajak','Pajak Online','Layanan pajak daerah, termasuk PBB.','https://pajakonline.jakarta.go.id/'],
      ['jawara','Jawara','Layanan sesuai tautan yang ditetapkan pengelola.',''],
      ['jaksehat','Jak-Sehat','Aplikasi dan layanan kesehatan Jakarta.','https://www.jakarta.go.id/index.php/aplikasi-jaksehat'],
      ['bpjstk','BPJS Ketenagakerjaan','Layanan jaminan sosial ketenagakerjaan.','https://www.bpjsketenagakerjaan.go.id/'],
    ];
    return array_map(static fn($v)=>[
        'id'=>$v[0],'title'=>$v[1],'description'=>$v[2],
        'url'=>$v[3],'logo_url'=>'','active'=>true,
    ],$names);
}
function cikoko_integrated_store_path():string {
    return __DIR__.'/.cikoko-integrated-services.php';
}
function cikoko_integrated_read():array {
    $path=cikoko_integrated_store_path();
    if(!is_file($path))return cikoko_integrated_default();
    $contents=@file_get_contents($path);
    $marker='<?php __halt_compiler(); ?>';
    if($contents===false || !str_starts_with($contents,$marker)){
        error_log('Cikoko integrated services store invalid.');
        return cikoko_integrated_default();
    }
    $decoded=json_decode(substr($contents,strlen($marker)),true);
    return is_array($decoded)&&array_is_list($decoded)?$decoded:cikoko_integrated_default();
}
function cikoko_integrated_https(string $url):bool {
    if($url==='')return true;
    if(strlen($url)>1500 || filter_var($url,FILTER_VALIDATE_URL)===false)return false;
    $p=parse_url($url);
    return is_array($p)&&strtolower((string)($p['scheme']??''))==='https'
      && strlen((string)($p['host']??''))>3
      && !isset($p['user']) && !isset($p['pass']);
}
function cikoko_integrated_dispatch(string $action,string $method):void {
    // Must authenticate on BOTH read and write, because the user asked to
    // show this list only for logged-in accounts.
    $user=mobile_auth();
    if($action==='integrated_services'){
        if($method!=='GET')mobile_error('Metode tidak tersedia.',405);
        $all=cikoko_integrated_read();
        $items=($user['user_role']??'')==='admin'
           ? $all : array_values(array_filter($all,static fn($a)=>($a['active']??true)!==false));
        mobile_json(['ok'=>true,'items'=>$items]);
    }
    if($action!=='integrated_services_save' || $method!=='POST'){
        mobile_error('Layanan tidak tersedia.',404);
    }
    if(($user['user_role']??'')!=='admin')mobile_error('Hanya Admin Utama dapat mengatur layanan.',403);
    $payload=mobile_body();
    $rows=$payload['items']??null;
    if(!is_array($rows)||!array_is_list($rows)||count($rows)>60)mobile_error('Daftar layanan tidak valid.',422);
    $safe=[];$ids=[];
    foreach($rows as $row){
        if(!is_array($row))mobile_error('Isi layanan tidak valid.',422);
        $id=trim((string)($row['id']??''));
        $name=trim((string)($row['title']??''));
        $desc=trim((string)($row['description']??''));
        $url=trim((string)($row['url']??''));
        $logo=trim((string)($row['logo_url']??''));
        if(!preg_match('/^[a-zA-Z0-9_-]{1,45}$/',$id) || isset($ids[$id])
           || $name==='' || mb_strlen($name)>80 || mb_strlen($desc)>300
           || !cikoko_integrated_https($url) || !cikoko_integrated_https($logo)){
            mobile_error('Periksa kembali judul, logo dan tautan HTTPS pada layanan.',422);
        }
        $ids[$id]=true;
        $safe[]=[
          'id'=>$id,'title'=>$name,'description'=>$desc,
          'url'=>$url,'logo_url'=>$logo,'active'=>($row['active']??true)===true,
        ];
    }
    $path=cikoko_integrated_store_path();
    $tmp=$path.'.'.bin2hex(random_bytes(8)).'.tmp';
    $json=json_encode($safe,JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES|JSON_THROW_ON_ERROR);
    if(@file_put_contents($tmp,'<?php __halt_compiler(); ?>'.$json,LOCK_EX)===false){
        error_log('Unable to persist Cikoko integrated services.');
        mobile_error('Pengaturan belum berhasil disimpan. Hubungi pengelola.',503);
    }
    @chmod($tmp,0600);
    if(!@rename($tmp,$path)){
        @unlink($tmp);
        mobile_error('Pengaturan belum berhasil disimpan. Silakan mencoba kembali.',503);
    }
    mobile_json(['ok'=>true,'items'=>$safe]);
}
