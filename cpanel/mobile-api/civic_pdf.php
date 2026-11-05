<?php
declare(strict_types=1);
/**
 * Dependency-free, private A4 LPJ preview. Explicitly labels incomplete
 * approvals; PIN audit trail is not a certified electronic signature.
 */
function cikoko_civic_output_pdf(array $doc,array $approvals):void{
 require_once __DIR__.'/rt_rw_pdf.php';
 $payload=json_decode((string)$doc['payload_json'],true);
 if(!is_array($payload))mobile_error('Isi LPJ tidak valid.',503);
 $kindLabels=[
  'lpj_rt'=>'LAPORAN PERTANGGUNGJAWABAN RT',
  'lpj_rw'=>'LAPORAN PERTANGGUNGJAWABAN RW',
  'lpj_lmk_a'=>'LPJ LMK - MODUL A',
  'lpj_lmk_b'=>'LPJ LMK - MODUL B',
 ];
 $kind=$kindLabels[$doc['kind']]??'LAPORAN PERTANGGUNGJAWABAN';
 $pages=[];$lines=[];$lineLimit=40;
 $add=function(string $t)use(&$lines,&$pages,$lineLimit):void{
  $text=trim(preg_replace('/\s+/u',' ',$t)??'');
  $parts=explode("\n",wordwrap($text,86,"\n",true));
  foreach($parts as $line){
   if(count($lines)>=$lineLimit){$pages[]=$lines;$lines=[];}
   $lines[]=$line;
  }
 };
 $add($kind);
 $add('Register sistem: CIKOKO-LPJ/'.(int)$doc['id']);
 $add('Periode: '.$doc['period'].'   |   RT '.$doc['rt'].' / RW '.$doc['rw']);
 $add('Penyusun: '.$doc['creator_name']);
 $add('Status: '.$doc['status']);
 if($doc['status']!=='selesai')$add('DRAFT / BELUM DISAHKAN - TIDAK UNTUK BUKTI PENGESAHAN');
 $add('----------------------------------------------------------');
 $money=static fn($v):string=>'Rp '.number_format((int)$v,0,',','.');
 $add('Saldo awal: '.$money($payload['opening']??0));
 $add('Penerimaan: '.$money($payload['income']??0));
 $add('Total pengeluaran: '.$money($payload['total_expenses']??0));
 $add('Saldo akhir: '.$money($payload['closing']??0));
 $add('RINCIAN PENGELUARAN');
 $i=0;
 foreach($payload['entries']??[] as $item){
  if(!is_array($item))continue;
  $i++;
  $add($i.'. '.(string)($item['activity']??'-').' - '.$money($item['amount']??0));
  if(trim((string)($item['notes']??''))!=='')$add('    Catatan: '.(string)$item['notes']);
 }
 if($i===0)$add('Tidak ada pengeluaran pada periode ini.');
 $add('----------------------------------------------------------');
 $add('RIWAYAT PERSETUJUAN INTERNAL');
 foreach($approvals as $entry){
  $add(strtoupper((string)$entry['duty']).' | '.(string)$entry['action'].' | '.(string)$entry['created_at']);
  if(!empty($entry['notes']))$add('    Catatan: '.(string)$entry['notes']);
 }
 if(!$approvals)$add('Belum ada persetujuan.');
 $add('Pengesahan memakai PIN akun berwenang; bukan TTE tersertifikasi.');
 $add('Tanda tangan/cap basah ditempatkan sesuai prosedur kantor.');
 if($lines)$pages[]=$lines;
 $objects=[];$addObject=function(string $x)use(&$objects):int{$objects[]=$x;return count($objects);};
 $catalog=$addObject('<< /Type /Catalog /Pages 2 0 R >>');
 $pageTree=$addObject('');
 $font=$addObject('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>');
 $pageRefs=[];
 foreach($pages as $index=>$pageLines){
  $cmd=[];$y=785;
  foreach($pageLines as $line){
   $size=($y===785?12:9);
   $cmd[]='BT /F1 '.$size.' Tf 45 '.$y.' Td ('.cikoko_pdf_text($line).') Tj ET';
   $y-=16;
  }
  $cmd[]='BT /F1 8 Tf 45 35 Td (Cikoko SmartAPP - Halaman '.($index+1).' / '.count($pages).') Tj ET';
  $stream=implode("\n",$cmd)."\n";
  $page=$addObject('');
  $data=$addObject('<< /Length '.strlen($stream).' >>'."\nstream\n".$stream.'endstream');
  $objects[$page-1]='<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 '.$font.' 0 R >> >> /Contents '.$data.' 0 R >>';
  $pageRefs[]=$page.' 0 R';
 }
 $objects[$pageTree-1]='<< /Type /Pages /Kids ['.implode(' ',$pageRefs).'] /Count '.count($pageRefs).' >>';
 $pdf="%PDF-1.4\n%\xE2\xE3\xCF\xD3\n";$offsets=[0];
 foreach($objects as $i=>$object){$offsets[]=strlen($pdf);$pdf.=($i+1)." 0 obj\n".$object."\nendobj\n";}
 $xref=strlen($pdf);$count=count($objects)+1;
 $pdf.="xref\n0 ".$count."\n0000000000 65535 f \n";
 for($i=1;$i<$count;$i++)$pdf.=sprintf('%010d 00000 n ',$offsets[$i])."\n";
 $pdf.="trailer\n<< /Size ".$count." /Root ".$catalog." 0 R >>\nstartxref\n".$xref."\n%%EOF";
 header('Content-Type: application/pdf');
 header('Content-Disposition: inline; filename="lpj-cikoko-'.(int)$doc['id'].'.pdf"');
 header('Content-Length: '.strlen($pdf));
 header('Cache-Control: private,no-store');
 echo $pdf;exit;
}
