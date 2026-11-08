<?php
declare(strict_types=1);
function cikoko_home_slides():array {
 $saved=db_read('cikoko_home_slides');$slides=[];
 foreach($saved as $row){
  $name=is_array($row)?(string)($row['name']??''):'';
  if(preg_match('/^[a-f0-9]{40}\.(jpg|png|webp)$/D',$name))$slides[]=['name'=>$name];
 }
 return array_slice($slides,0,5);
}
function cikoko_home_slides_dispatch(string $action,string $method):void {
 if($action==='home_slides'&&$method==='GET')mobile_json(['ok'=>true,'slides'=>cikoko_home_slides()]);
 if($action==='home_slide_photo'&&$method==='GET'){
  $name=(string)($_GET['name']??'');$published=in_array($name,array_column(cikoko_home_slides(),'name'),true);
  if(!$published){$u=mobile_auth();if(($u['user_role']??'')!=='admin')mobile_error('Foto tidak tersedia.',404);}
  if(!preg_match('/^[a-f0-9]{40}\.(jpg|png|webp)$/D',$name))mobile_error('Foto tidak tersedia.',404);
  $dir=realpath(__DIR__.'/private/home-slides');$path=$dir?realpath($dir.'/'.$name):false;
  if(!$path||dirname($path)!==$dir||!is_file($path))mobile_error('Foto tidak tersedia.',404);
  $mime=(new finfo(FILEINFO_MIME_TYPE))->file($path);
  if(!in_array($mime,['image/jpeg','image/png','image/webp'],true))mobile_error('Foto tidak tersedia.',404);
  header('Content-Type: '.$mime);header('Cache-Control: public, max-age=300');header('Content-Length: '.filesize($path));readfile($path);exit;
 }
 $u=mobile_auth();if(($u['user_role']??'')!=='admin')mobile_error('Pengaturan foto beranda hanya tersedia untuk Admin Utama.',403);
 if($method!=='POST')mobile_error('Metode tidak diperbolehkan.',405);
 if($action==='home_slide_upload'){
  $name=mobile_file('photo',true);$dir=__DIR__.'/private/home-slides';
  if(!is_dir($dir)&&!mkdir($dir,0750,true))mobile_error('Foto belum dapat disimpan.',503);
  if(!rename(__DIR__.'/private/'.$name,$dir.'/'.$name))mobile_error('Foto belum dapat disimpan.',503);
  mobile_json(['ok'=>true,'name'=>$name]);
 }
 if($action==='home_slides_save'){
  $body=mobile_body();$names=$body['slides']??null;
  if(!is_array($names)||count($names)>5)mobile_error('Pilih paling banyak 5 foto beranda.',422);
  $slides=[];$dir=realpath(__DIR__.'/private/home-slides');
  foreach($names as $name){
   if(!is_string($name)||!preg_match('/^[a-f0-9]{40}\.(jpg|png|webp)$/D',$name))mobile_error('Pilihan foto tidak valid.',422);
   $path=$dir?realpath($dir.'/'.$name):false;
   if(!$path||dirname($path)!==$dir||!is_file($path))mobile_error('Foto belum tersedia. Silakan unggah kembali.',422);
   if(in_array($name,array_column($slides,'name'),true))mobile_error('Setiap foto hanya dapat dipilih satu kali.',422);
   $slides[]=['name'=>$name];
  }
  if(!db_write('cikoko_home_slides',$slides))mobile_error('Pengaturan foto belum dapat disimpan.',503);
  mobile_json(['ok'=>true,'slides'=>$slides,'message'=>'Foto beranda berhasil diperbarui.']);
 }
 mobile_error('Layanan tidak ditemukan.',404);
}
