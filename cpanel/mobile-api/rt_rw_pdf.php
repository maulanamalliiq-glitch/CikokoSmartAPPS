<?php
declare(strict_types=1);
/**
 * Minimal self-contained PDF renderer for approved RT/RW documents.
 * Embeds the exact officer-authorized signature/stamp image snapshots.
 * These images are not a government-certified electronic signature.
 */
function cikoko_pdf_text($raw):string {
 $s=(string)$raw;
 $s=preg_replace('/[\x00-\x1f\x7f]/u',' ',$s)??'';
 if(function_exists('iconv')){
  $trans=@iconv('UTF-8','Windows-1252//TRANSLIT',$s);
  if($trans!==false)$s=$trans;
 }
 $s=preg_replace('/[^\x20-\x7e\x80-\xff]/','?',$s)??'';
 return str_replace(['\\','(',')'],['\\\\','\\(','\\)'],$s);
}
function cikoko_pdf_jpeg(string $basename):array {
 if(!preg_match('/^[a-f0-9]{40}\.(jpg|jpeg|png|webp)$/i',$basename))mobile_error('Berkas tanda tangan tidak valid.',503);
 $path=__DIR__.'/private/'.$basename;
 if(!is_file($path)||filesize($path)>4*1024*1024)mobile_error('Berkas tanda tangan belum tersedia.',503);
 $bytes=file_get_contents($path);
 if($bytes===false)mobile_error('Foto tanda tangan belum tersedia.',503);
 $info=@getimagesizefromstring($bytes);
 if(!$info||$info[0]>4096||$info[1]>4096)mobile_error('Dimensi foto tanda tangan tidak valid.',503);
 if($info['mime']!=='image/jpeg'){
  if(!function_exists('imagecreatefromstring')||!function_exists('imagejpeg')){
   mobile_error('Hosting membutuhkan ekstensi GD untuk gambar tanda tangan non-JPEG.',503);
  }
  $im=@imagecreatefromstring($bytes);
  if($im===false)mobile_error('Format foto tanda tangan tidak didukung.',503);
  ob_start();imagejpeg($im,null,88);$bytes=ob_get_clean();
  imagedestroy($im);
  if(!is_string($bytes))mobile_error('Konversi gambar gagal.',503);
 }
 return [$bytes,(int)$info[0],(int)$info[1]];
}
function cikoko_rt_rw_output_pdf(array $letter):void {
 foreach(['rt_signature','rt_stamp','rw_signature','rw_stamp'] as $k){
  if(empty($letter[$k]))mobile_error('Tanda tangan atau stempel belum lengkap.',409);
 }
 $forms=json_decode((string)$letter['form_json'],true);
 if(!is_array($forms))mobile_error('Data pengajuan tidak valid.',503);
 $objects=[];
 $add=function(string $str)use(&$objects):int {
  $objects[]=$str;return count($objects);
 };
 // Stable references for Catalog, Pages, Page, Font, Content.
 $catalog=$add('<< /Type /Catalog /Pages 2 0 R >>');
 $pages=$add('<< /Type /Pages /Kids [3 0 R] /Count 1 >>');
 $page=$add('');
 $font=$add('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>');
 $contentId=$add('');
 $images=[];$resources=[];
 foreach(['rt_signature','rt_stamp','rw_signature','rw_stamp'] as $i=>$k){
  [$jpeg,$w,$h]=cikoko_pdf_jpeg((string)$letter[$k]);
  $id=$add('<< /Type /XObject /Subtype /Image /Width '.$w.' /Height '.$h.' /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length '.strlen($jpeg).' >>'."\nstream\n".$jpeg."\nendstream");
  $label='S'.($i+1);
  $resources[]='/'.$label.' '.$id.' 0 R';
  $images[$k]=$label;
 }
 $cmd=[];$y=805;
 $write=static function(string $text,int $size=10,int $x=49)use(&$cmd,&$y):void {
  $cmd[]='BT /F1 '.$size.' Tf '.$x.' '.$y.' Td ('.cikoko_pdf_text($text).') Tj ET';
  $y-=$size+9;
 };
 $write('KELURAHAN CIKOKO - SURAT PENGANTAR RT/RW',15);
 $write('Register internal: CIKOKO/RT-RW/'.(int)$letter['id'],10);
 $write('Tanggal pengajuan: '.substr((string)$letter['created_at'],0,10),10);
 $write('RT '.$letter['rt'].' / RW '.$letter['rw'].' - Wilayah Kelurahan Cikoko',10);
 $y-=8;
 $fields=[
  'Nama Pemohon'=>'nama','Tempat Lahir'=>'tempat_lahir',
  'Tanggal Lahir'=>'tanggal_lahir','Nomor KTP/KK'=>'no_ktp_kk',
  'Agama'=>'agama','Warga Negara'=>'kewarganegaraan',
  'Pendidikan'=>'pendidikan','Jenis Kelamin'=>'jenis_kelamin',
  'Status'=>'status','Pekerjaan'=>'pekerjaan',
  'Alamat'=>'alamat','Maksud Surat'=>'maksud_keperluan',
 ];
 foreach($fields as $label=>$k){
  $value=trim(preg_replace('/\s+/u',' ',(string)($forms[$k]??''))??'');
  // Bound printable width to prevent text spilling over the margin.
  $chunks=wordwrap($value,66,"\n",true);
  $lines=explode("\n",$chunks);
  $write($label.': '.array_shift($lines),10);
  foreach(array_slice($lines,0,2) as $next)$write('                  '.$next,10);
 }
 $y-=12;
 $write('Persetujuan wilayah (cap/TTD berupa gambar, bukan TTE tersertifikasi)',10);
 $rtY=$y-66;$rwY=$rtY;
 foreach([
  ['rt_signature',55,$rtY,88,43],['rt_stamp',145,$rtY,47,43],
  ['rw_signature',338,$rwY,88,43],['rw_stamp',428,$rwY,47,43],
 ] as [$key,$x,$iy,$w,$h]){
  $cmd[]='q '.$w.' 0 0 '.$h.' '.$x.' '.$iy.' cm /'.$images[$key].' Do Q';
 }
 $cmd[]='BT /F1 10 Tf 70 '.($rtY-17).' Td (Ketua RT '.$letter['rt'].') Tj ET';
 $cmd[]='BT /F1 10 Tf 355 '.($rwY-17).' Td (Ketua RW '.$letter['rw'].') Tj ET';
 $cmd[]='BT /F1 8 Tf 45 32 Td (Dokumen dari sistem administrasi Cikoko. Verifikasi fisik dan kewenangan tetap diperlukan.) Tj ET';
 $contents=implode("\n",$cmd)."\n";
 $objects[$contentId-1]='<< /Length '.strlen($contents).' >>'."\nstream\n".$contents."endstream";
 $objects[$page-1]='<< /Type /Page /Parent '.$pages.' 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 '.$font.' 0 R >> /XObject << '.implode(' ',$resources).' >> >> /Contents '.$contentId.' 0 R >>';
 $out="%PDF-1.4\n%\xE2\xE3\xCF\xD3\n";
 $offsets=[0];
 foreach($objects as $i=>$obj){
  $offsets[]=strlen($out);
  $out.=($i+1)." 0 obj\n".$obj."\nendobj\n";
 }
 $xref=strlen($out);$count=count($objects)+1;
 $out.="xref\n0 ".$count."\n0000000000 65535 f \n";
 for($i=1;$i<$count;$i++)$out.=sprintf('%010d 00000 n ',$offsets[$i])."\n";
 $out.="trailer\n<< /Size ".$count." /Root 1 0 R >>\nstartxref\n".$xref."\n%%EOF";
 header('Content-Type: application/pdf');
 header('Content-Disposition: inline; filename="surat-pengantar-cikoko-'.(int)$letter['id'].'.pdf"');
 header('Content-Length: '.strlen($out));
 header('Cache-Control: private, no-store');
 echo $out;exit;
}
