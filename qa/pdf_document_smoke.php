<?php
declare(strict_types=1);
/** Produce synthetic PDFs to stdout. No production credentials or citizen data. */
if(PHP_SAPI!=='cli')exit(2);
$mode=$argv[1]??'';
$api=dirname(__DIR__).'/cpanel/mobile-api';
if($mode==='rt_rw'){
 require_once $api.'/rt_rw_pdf.php';
 $private=$api.'/private';
 if(!is_dir($private))mkdir($private,0750,true);
 $jpeg=base64_decode('/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAUDBAQEAwUEBAQFBQUGBwwIBwcHBw8LCwkMEQ8SEhEPERETFhwXExQaFRERGCEYGh0dHx8fExciJCIeJBweHx7/2wBDAQUFBQcGBw4ICA4eFBEUHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh7/wAARCAACAAIDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAj/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFAEBAAAAAAAAAAAAAAAAAAAAAP/EABQRAQAAAAAAAAAAAAAAAAAAAAD/2gAMAwEAAhEDEQA/ALLAB//Z',true);
 if(!$jpeg)exit(3);
 $parts=['rt_signature','rt_stamp','rw_signature','rw_stamp'];
 $names=[];$files=[];
 foreach($parts as $i=>$field){
  $name=str_repeat(dechex($i+10),40).'.jpg';
  $names[$field]=$name;$files[]=$private.'/'.$name;
  if(file_put_contents($private.'/'.$name,$jpeg)===false)exit(4);
 }
 register_shutdown_function(static function()use($files):void{
  foreach($files as $file)@unlink($file);
 });
 $form=[
  'nama'=>'WARGA CONTOH','tempat_lahir'=>'Jakarta','tanggal_lahir'=>'1990-01-01',
  'no_ktp_kk'=>'0000000000000000','agama'=>'Contoh',
  'kewarganegaraan'=>'WNI','pendidikan'=>'SMA',
  'jenis_kelamin'=>'Laki-laki','status'=>'Belum menikah',
  'pekerjaan'=>'Contoh','alamat'=>'Jl. Contoh', 'maksud_keperluan'=>'Pengantar',
 ];
 cikoko_rt_rw_output_pdf([
  ...$names,'id'=>1,'created_at'=>'2026-11-06 08:00:00',
  'status'=>'terverifikasi','rt'=>'02','rw'=>'05',
  'form_json'=>json_encode($form,JSON_UNESCAPED_UNICODE),
 ]);
}
if($mode==='civic'){
 require_once $api.'/civic_pdf.php';
 $data=[
  'opening'=>1000000,'income'=>3000000,
  'total_expenses'=>500000,'closing'=>3500000,
  'entries'=>[['activity'=>'Pengelolaan lingkungan','amount'=>500000,'notes'=>'Contoh']],
 ];
 cikoko_civic_output_pdf([
  'id'=>2,'kind'=>'lpj_rt','creator_name'=>'Petugas Contoh',
  'period'=>'2026-11','rt'=>'02','rw'=>'05',
  'status'=>'selesai','payload_json'=>json_encode($data),
 ],[['duty'=>'rt','action'=>'approve','notes'=>'Disetujui',
  'created_at'=>'2026-11-06 08:00:00']]);
}
fwrite(STDERR,"Unknown PDF smoke mode.\n");exit(2);
