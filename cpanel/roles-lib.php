<?php
require_once __DIR__.'/lib.php';
function portal_roles(): array {return ["admin_kelurahan"=>"Admin Kelurahan", "lurah"=>"Lurah", "ptsp"=>"PTSP", "dukcapil"=>"Dukcapil", "dasawisma"=>"Dasawisma", "ppsu"=>"PPSU", "asn"=> "ASN", "pppk"=>"PPPK", "pjlp"=>"PJLP", "pkk"=>"PKK", "fkdm"=>"FKDM", "lmk"=>"LMK", "jumantik_rt"=>"JUMANTIK RT", "jumantik_rw"=>"JUMANTIK RW", "posyandu"=>"POSYANDU", "rw"=>"RW", "rt"=>"RT", "warga"=>"Warga"];}
function portal_role(): string {return (string)($_SESSION['portal_role']??'');}
function portal_user(): array {return ['id'=>(string)($_SESSION['portal_uid']??''),'name'=>(string)($_SESSION['portal_name']??''),'role'=>portal_role()];}
function portal_need(): void {if(!portal_role()){header('Location: '.url('login.php'));exit;}}
function portal_admin(): void {need_admin();}
function portal_setting(): array {$d=db_read('portal_config');return array_merge(['letters'=>['Surat Ahli Waris','Surat Pengantar RT/RW','Surat Keterangan Domisili','Surat Keterangan Usaha'],'reports'=>['Laporan Kegiatan','Laporan Lapangan','Laporan Pemantauan'],'role_reports'=>[],'warga_reports'=>['Laporan Jumantik Warga']],$d);}
function portal_allowed_reports(string $r): array {$s=portal_setting();return $s['role_reports'][$r]??$s['reports'];}
function portal_logged_in(): bool {return is_admin()||portal_role()!=='';}
function portal_redirect(): void {header('Location: '.url(is_admin()?'admin.php':'portal.php'));exit;}
function portal_save_upload(string $name): string {
 if(!isset($_FILES[$name])||($_FILES[$name]['error']??UPLOAD_ERR_NO_FILE)===UPLOAD_ERR_NO_FILE)return '';
 $f=$_FILES[$name];if($f['error']!==UPLOAD_ERR_OK || $f['size']>4*1024*1024)throw new RuntimeException('Foto gagal diunggah atau terlalu besar (maksimum 4 MB).');
 $mime=(new finfo(FILEINFO_MIME_TYPE))->file($f['tmp_name']);$ext=['image/jpeg'=>'jpg','image/png'=>'png','image/webp'=>'webp','application/pdf'=>'pdf'][$mime]??'';
 if(!$ext)throw new RuntimeException('Lampiran harus JPG, PNG, WebP, atau PDF.');
 $dir=__DIR__.'/assets/portal-uploads';if(!is_dir($dir))mkdir($dir,0755,true);
 $n=bin2hex(random_bytes(16)).'.'.$ext;if(!move_uploaded_file($f['tmp_name'],$dir.'/'.$n))throw new RuntimeException('Folder upload tidak dapat ditulis.');return 'assets/portal-uploads/'.$n;
}
function portal_esc($s): string {return esc($s);}

function portal_departments(): array {
 $d=db_read('portal_departments');
 if(is_array($d)&&count($d))return array_values(array_filter($d,'is_string'));
 return ['Sekretariat','Pelayanan Terpadu Satu Pintu (PTSP)','Pemerintahan','Kesejahteraan Rakyat','Ekonomi dan Pembangunan','Ketenteraman dan Ketertiban','ASN','PPPK','PJLP','PKK','FKDM','LMK','Jumantik','Posyandu','RW','RT'];
}
