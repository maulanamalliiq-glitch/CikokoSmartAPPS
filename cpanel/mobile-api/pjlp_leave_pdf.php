<?php
declare(strict_types=1);
/**
 * A4 portrait leave-letter renderer modeled after Surat-Cuti-6.pdf.
 * Fixed 595 x 842 pt; no Composer requirement. PDF is snapshotted on final approval.
 * QR images are fixed admin uploads, NOT digitally certified signatures.
 */
require_once __DIR__.'/pdf_native.php';

function pjlp_print_date(string $value,bool $dayName=false):string {
 $d=new DateTimeImmutable(substr($value,0,10));
 $months=[1=>'Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember'];
 $days=[1=>'Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu'];
 return ($dayName?$days[(int)$d->format('N')].', ':'').$d->format('j').' '.$months[(int)$d->format('n')].' '.$d->format('Y');
}
function pjlp_pdf_safe(string $s,int $chars=100):string {
 $s=trim(preg_replace('/\s+/u',' ',$s)??'');
 if(function_exists('mb_strlen')&&mb_strlen($s)>$chars)return mb_substr($s,0,$chars-3).'...';
 if(strlen($s)>$chars)return substr($s,0,$chars-3).'...';
 return $s;
}
function pjlp_pdf_build(PDO $db,array $r):string {
 $a=$db->prepare('SELECT * FROM pjlp_leave_approvals WHERE request_id=? ORDER BY id');
 $a->execute([(int)$r['id']]);$approvals=$a->fetchAll(PDO::FETCH_ASSOC);
 $supUid=(string)$r['supervisor_user_id'];
 $super=pjlp_valid_official($db,$supUid);
 // The document names the responsible Lurah from the admin-maintained roster;
 // its administrative approval is separately recorded under the admin actor.
 $lurahSt=$db->query("SELECT user_id FROM pjlp_officials WHERE LOWER(title) LIKE '%lurah%' ORDER BY user_id LIMIT 1");
 $lurahUid=(string)($lurahSt->fetchColumn()?:'');
 $lurah=$lurahUid?pjlp_valid_official($db,$lurahUid):null;
 if(!$super||!$lurah||empty($super['qr_file'])||empty($lurah['qr_file']))pjlp_fail('Data QR pejabat belum lengkap',503);
 $base=pjlp_private_dir('qr').'/';
 $qrFiles=[$base.$super['qr_file'],$base.$lurah['qr_file']];
 $images=[];
 foreach($qrFiles as $path){
  if(!is_file($path))pjlp_fail('File QR pejabat tidak ditemukan',503);
  $jpeg=cikoko_pdf_image($path);
  $dims=@getimagesizefromstring($jpeg);
  if(!$dims)pjlp_fail('QR pejabat tidak bisa dibaca',503);
  $images[]=['jpg'=>$jpeg,'width'=>(int)$dims[0],'height'=>(int)$dims[1]];
 }
 $s=$db->prepare("SELECT b.allowance_days,b.adjustment_days,COALESCE((SELECT SUM(requested_days) FROM pjlp_leave_requests WHERE employee_id=b.employee_id AND leave_year=b.leave_year AND status='approved'),0) used_days FROM pjlp_leave_balances b WHERE b.employee_id=? AND b.leave_year=?");
 $s->execute([(int)$r['employee_id'],(int)$r['leave_year']]);$balance=$s->fetch(PDO::FETCH_ASSOC)?:[];
 $remaining=(int)($balance['allowance_days']??0)+(int)($balance['adjustment_days']??0)-(int)($balance['used_days']??0);
 $hired=new DateTimeImmutable((string)$r['hired_on']);
 $submitted=new DateTimeImmutable((string)$r['submitted_at']);$tenure=$hired->diff($submitted);
 $workAge=sprintf('%02d tahun %d bulan',$tenure->y,$tenure->m);
 $c="0 G 0 g\n"; // black, vector strokes
 $ln=static function(float $x,float $y,float $xx,float $yy)use(&$c):void {
  $c.=sprintf("%.2f %.2f m %.2f %.2f l S\n",$x,$y,$xx,$yy);
 };
 $rect=static function(float $x,float $y,float $w,float $h)use(&$c):void {
  $c.=sprintf("%.2f %.2f %.2f %.2f re S\n",$x,$y,$w,$h);
 };
 $t=static function(float $x,float $y,string $value,float $size=8,bool $bold=false)use(&$c):void {
  $c.=sprintf("BT /%s %.1f Tf %.2f %.2f Td (%s) Tj ET\n",$bold?'F2':'F1',$size,$x,$y,cikoko_pdf_escape($value));
 };
 $center=static function(float $centerX,float $y,string $value,float $size=8,bool $bold=false)use($t):void{
  $length=function_exists('mb_strlen')?mb_strlen($value):strlen($value);
  $t($centerX-$length*$size*($bold?0.285:0.25),$y,$value,$size,$bold);
 };
 $header=static function(float $top,float $bottom,string $title)use($rect,$ln,$t):void{
  $rect(42,$bottom,510,$top-$bottom);$ln(42,$top-14,552,$top-14);
  $t(48,$top-10,$title,8.5,true);
 };
 $field=static function(float $x,float $y,string $value,int $limit=100)use($t):void{
  $t($x,$y,pjlp_pdf_safe($value,$limit),7.7);
 };
 $tick=static function(float $x,float $y)use($ln):void{
  $ln($x-4,$y,$x,$y-4);$ln($x,$y-4,$x+8,$y+5);
 };

 // Recipient and letter identity.
 $t(405,799,'Yth. Lurah Kelurahan Cikoko',8);
 $t(397,788,'Kota Administrasi Jakarta Selatan',8);
 $center(470,777,'Di',8);$center(470,766,'Jakarta',8);
 $center(297,740,'SURAT CUTI PJLP KELURAHAN CIKOKO',10.5,true);
 $center(297,726,'Nomor : '.pjlp_pdf_safe((string)$r['official_number'],70),8);
 $t(42,710,'Pengajuan Surat : '.pjlp_print_date((string)$r['submitted_at'],true),8);
 $t(42,699,'Terverifikasi Surat : '.pjlp_print_date((string)$r['verified_at'],true),8);

 // I. Employee profile.
 $header(678,622,'I. DATA PEGAWAI');
 foreach([651,637] as $y)$ln(42,$y,552,$y);
 $ln(109,622,109,664);$ln(354,637,354,664);$ln(418,637,418,664);
 $field(48,654,'Nama');$field(115,654,(string)$r['full_name'],47);
 $field(360,654,'ID PHL');$field(424,654,(string)$r['id_phl'],24);
 $field(48,640,'Jabatan');$field(115,640,(string)$r['position_name'],40);
 $field(360,640,'Masa Kerja');$field(424,640,$workAge,24);
 $field(48,626,'Unit Kerja');$field(115,626,(string)$r['work_unit'],75);

 // II. Leave reason, always visible within two lines.
 $header(616,574,'II. ALASAN CUTI');
 $reason=trim((string)$r['reason']);
 $field(48,589,function_exists('mb_substr')?mb_substr($reason,0,95):substr($reason,0,95),95);
 if((function_exists('mb_strlen')?mb_strlen($reason):strlen($reason))>95){
  $field(48,579,function_exists('mb_substr')?mb_substr($reason,95,95):substr($reason,95,95),95);
 }

 // III. Dates.
 $header(561,530,'III. LAMANYA CUTI');
 foreach([98,244,326,410,440] as $x)$ln($x,530,$x,547);
 $field(48,536,'Selama');$field(105,536,(int)$r['requested_days'].' hari');
 $field(250,536,'mulai tanggal');$field(333,536,pjlp_print_date((string)$r['start_date']),25);
 $field(414,536,'s/d');$field(446,536,pjlp_print_date((string)$r['end_date']),25);

 // IV. Balance.
 $header(516,454,'IV. CATATAN CUTI');
 $ln(42,488,552,488);$ln(42,474,552,474);
 $t(48,491,'CUTI TAHUNAN',8.2,true);
 $ln(96,454,96,488);$ln(132,454,132,488);
 $field(48,479,'Tahun');$field(101,479,'Sisa');$field(140,479,'Keterangan');
 $field(48,459,(string)$r['leave_year']);
 $field(101,459,(string)max(0,$remaining));
 $field(140,459,(int)$r['requested_days'].' hari');

 // V. Address and applicant's name.
 $header(442,329,'V. ALAMAT SELAMA MENJALANKAN CUTI');
 $ln(331,329,331,428);$ln(331,412,552,412);$ln(419,412,419,428);
 $address=(string)$r['leave_address'];
 foreach([0,57,114] as $i=>$offset){
  $part=function_exists('mb_substr')?mb_substr($address,$offset,57):substr($address,$offset,57);
  if($part!=='')$field(48,416-$i*11,$part,57);
 }
 $field(337,417,'TELP');$field(426,417,(string)$r['phone'],24);
 $center(442,397,'Hormat saya,',8);
 $center(442,357,pjlp_pdf_safe((string)$r['full_name'],37),8);
 $center(442,344,'ID PHL '.(string)$r['id_phl'],8);

 // VI. Supervisor decision & permanent QR.
 $header(322,195,'VI. PERTIMBANGAN ATASAN LANGSUNG');
 $ln(331,195,331,308);$ln(42,294,331,294);$ln(42,280,331,280);
 $ln(138,280,138,308);$ln(234,280,234,308);
 $center(90,298,'DISETUJUI',6.5);$center(186,298,'PERUBAHAN',6.5);$center(282,298,'DITANGGUHKAN',6.5);
 $tick(88,288);$field(48,270,'Alasan :');
 $center(442,298,pjlp_pdf_safe((string)$super['title'],42),7.2);
 $center(442,215,pjlp_pdf_safe((string)$super['full_name'],38),7.6);
 $center(442,202,'NIP '.(string)$super['nip'],7.4);

 // VII. Lurah final decision & permanent QR.
 $header(188,38,'VII. KEPUTUSAN PEJABAT YANG BERWENANG MEMBERIKAN CUTI');
 $ln(331,38,331,174);$ln(42,160,331,160);$ln(42,146,331,146);
 $ln(138,146,138,174);$ln(234,146,234,174);
 $center(90,164,'DISETUJUI',6.5);$center(186,164,'PERUBAHAN',6.5);$center(282,164,'DITANGGUHKAN',6.5);
 $tick(88,154);$field(48,136,'Alasan :');
 $center(442,165,pjlp_pdf_safe((string)$lurah['title'],42),7.5);
 $center(442,60,pjlp_pdf_safe((string)$lurah['full_name'],38),7.6);
 $center(442,47,'NIP '.(string)$lurah['nip'],7.4);

 // Two independently uploaded fixed QR images, centered in each signatory area.
 $c.="q 61 0 0 61 411 226 cm /Im1 Do Q\n";
 $c.="q 78 0 0 78 403 73 cm /Im2 Do Q\n";
 $objects=[];
 $objects[1]='<< /Type /Catalog /Pages 2 0 R >>';
 $objects[2]='<< /Type /Pages /Kids [5 0 R] /Count 1 >>';
 $objects[3]='<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>';
 $objects[4]='<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>';
 $objects[5]='<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 3 0 R /F2 4 0 R >> /XObject << /Im1 7 0 R /Im2 8 0 R >> >> /Contents 6 0 R >>';
 $objects[6]='<< /Length '.strlen($c)." >>\nstream\n".$c."endstream";
 foreach($images as $i=>$img){
  $objects[7+$i]='<< /Type /XObject /Subtype /Image /Width '.$img['width'].' /Height '.$img['height'].' /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length '.strlen($img['jpg'])." >>\nstream\n".$img['jpg']."\nendstream";
 }
 ksort($objects);$pdf="%PDF-1.4\n%\xE2\xE3\xCF\xD3\n";$offsets=[0];
 foreach($objects as $i=>$obj){$offsets[$i]=strlen($pdf);$pdf.="$i 0 obj\n".$obj."\nendobj\n";}
 $xref=strlen($pdf);$pdf.="xref\n0 9\n0000000000 65535 f \n";
 for($i=1;$i<=8;$i++)$pdf.=sprintf('%010d 00000 n '."\n",$offsets[$i]);
 $pdf.="trailer\n<< /Root 1 0 R /Size 9 >>\nstartxref\n".$xref."\n%%EOF\n";
 return $pdf;
}
