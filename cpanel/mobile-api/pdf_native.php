<?php
declare(strict_types=1);

/**
 * Minimal server-side A4 PDF generator. Deliberately avoids relying on an
 * uninstalled Composer package. JPEG image embeds require GD for safe
 * normalization. This is an internal printable document, NOT certified TTE.
 */
function cikoko_pdf_escape(string $value):string {
    $value=preg_replace('/[\x00-\x1F\x7F]+/u',' ',$value)??'';
    if(function_exists('iconv')){
        $encoded=@iconv('UTF-8','Windows-1252//TRANSLIT',$value);
        $value=$encoded===false?preg_replace('/[^\x20-\x7E]/','?', $value):$encoded;
    }else{
        $value=preg_replace('/[^\x20-\x7E]/','?',$value)??'';
    }
    return str_replace(['\\','(',')'],['\\\\','\\(','\\)'],$value);
}
function cikoko_pdf_image(string $path):string {
    if(!is_file($path)||!function_exists('imagecreatefromstring')||
       !function_exists('imagejpeg'))mobile_error('Konversi TTD/stempel PDF memerlukan dukungan gambar pada hosting.',503);
    $bytes=@file_get_contents($path);
    if($bytes===false||strlen($bytes)>4*1024*1024)mobile_error('Berkas tanda tangan tidak tersedia.',503);
    $image=@imagecreatefromstring($bytes);
    if($image===false)mobile_error('Berkas TTD/stempel rusak.',503);
    $w=imagesx($image);$h=imagesy($image);
    if($w<1||$h<1||$w>12000||$h>12000){
        imagedestroy($image);mobile_error('Ukuran gambar TTD/stempel tidak valid.',422);
    }
    // Flatten alpha onto white, preserving legible dark ink on printed PDF.
    $target=imagecreatetruecolor($w,$h);
    imagefill($target,0,0,imagecolorallocate($target,255,255,255));
    imagecopy($target,$image,0,0,0,0,$w,$h);
    ob_start();imagejpeg($target,null,84);$jpg=(string)ob_get_clean();
    imagedestroy($target);imagedestroy($image);
    if($jpg==='')mobile_error('Gambar TTD/stempel gagal diproses.',503);
    return $jpg;
}
function cikoko_pdf_render(string $filename,array $lines,array $imageFiles=[]):void {
    $filename=preg_replace('/[^A-Za-z0-9_.-]/','_', $filename)??'dokumen.pdf';
    $layout=[];
    foreach($lines as $index=>$raw){
        $line=trim((string)$raw);
        if($line===''){$layout[]=['text'=>'','font'=>10];continue;}
        foreach(explode("\n",wordwrap($line,96,"\n",true)) as $piece){
            $layout[]=['text'=>$piece,'font'=>$index===0?15:10];
        }
    }
    // Repeating page structures prevent silently truncating long LPJ lists.
    $pages=array_chunk($layout,42);
    if(!$pages)$pages=[[]];
    $images=[];
    foreach(array_slice($imageFiles,0,4) as $path){
        $jpg=cikoko_pdf_image($path);
        $dim=@getimagesizefromstring($jpg);
        if(!is_array($dim))mobile_error('Format gambar tanda tangan tidak valid.',503);
        $images[]=['data'=>$jpg,'w'=>(int)$dim[0],'h'=>(int)$dim[1]];
    }
    $objects=[];
    $objects[1]='<< /Type /Catalog /Pages 2 0 R >>';
    $objects[3]='<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>';
    $pageRefs=[];$imageBase=4+count($pages)*2;
    $xObjects='';
    foreach($images as $i=>$img){
        $id=$imageBase+$i;
        $xObjects.='/Im'.($i+1)." {$id} 0 R ";
        $objects[$id]="<< /Type /XObject /Subtype /Image /Width ".$img['w'].
           " /Height ".$img['h']." /ColorSpace /DeviceRGB /BitsPerComponent 8".
           " /Filter /DCTDecode /Length ".strlen($img['data'])." >>\nstream\n".
           $img['data']."\nendstream";
    }
    $total=count($pages);
    foreach($pages as $page=>$rows){
        $pageId=4+$page*2;
        $contentId=$pageId+1;
        $pageRefs[]="{$pageId} 0 R";
        $stream="0.12 0.20 0.33 rg\n";$y=795;
        foreach($rows as $row){
            $line=(string)$row['text'];
            if($line===''){$y-=9;continue;}
            $font=(int)$row['font'];
            $stream.="BT /F1 {$font} Tf 42 {$y} Td (".cikoko_pdf_escape($line).") Tj ET\n";
            $y-=$font===15?24:15;
        }
        $number=$page+1;
        $stream.="BT /F1 9 Tf 42 37 Td (Halaman {$number} / {$total}) Tj ET\n";
        $thisImages=$page===$total-1;
        if($thisImages){
            $xs=[45,155,315,425];$slotW=94;$slotH=66;
            foreach($images as $i=>$img){
                $h=min($slotH,$slotW*$img['h']/$img['w']);
                $yy=76+($slotH-$h)/2;
                $stream.="q {$slotW} 0 0 {$h} {$xs[$i]} {$yy} cm /Im".($i+1)." Do Q\n";
            }
        }
        $resources=$thisImages?$xObjects:'';
        $objects[$pageId]='<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << '.
           '/Font << /F1 3 0 R >> /XObject << '.$resources.' >> >>'.
           " /Contents {$contentId} 0 R >>";
        $objects[$contentId]="<< /Length ".strlen($stream)." >>\nstream\n".$stream."endstream";
    }
    $objects[2]='<< /Type /Pages /Kids [ '.implode(' ',$pageRefs).' ] /Count '.$total.' >>';
    ksort($objects);
    $pdf="%PDF-1.4\n%\xE2\xE3\xCF\xD3\n";$offsets=[0];
    foreach($objects as $id=>$data){
        $offsets[$id]=strlen($pdf);
        $pdf.="{$id} 0 obj\n".$data."\nendobj\n";
    }
    $xref=strlen($pdf);$size=max(array_keys($objects))+1;
    $pdf.="xref\n0 {$size}\n0000000000 65535 f \n";
    for($i=1;$i<$size;$i++)$pdf.=sprintf('%010d 00000 n '."\n",$offsets[$i]??0);
    $pdf.="trailer\n<< /Root 1 0 R /Size {$size} >>\nstartxref\n{$xref}\n%%EOF\n";
    header('Content-Type: application/pdf');
    header('Content-Disposition: inline; filename="'.$filename.'"');
    header('Content-Length: '.strlen($pdf));
    header('Cache-Control: private, no-store');
    echo $pdf;exit;
}
