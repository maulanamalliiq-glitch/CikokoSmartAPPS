<?php
declare(strict_types=1);
// Offline smoke test for ONE-PAGE A4 letter generation; no real employee details.
function mobile_error(string $message,int $status=400):void {throw new RuntimeException($message.' HTTP '.$status);}
require dirname(__DIR__).'/cpanel/mobile-api/pjlp_leave.php';
require dirname(__DIR__).'/cpanel/mobile-api/pjlp_leave_pdf.php';
$db=new PDO('sqlite::memory:');
$db->setAttribute(PDO::ATTR_ERRMODE,PDO::ERRMODE_EXCEPTION);
$db->exec("CREATE TABLE pjlp_leave_approvals(id INTEGER PRIMARY KEY,request_id INT,stage TEXT,actor_user_id TEXT,decision TEXT)");
$db->exec("CREATE TABLE pjlp_officials(user_id TEXT,full_name TEXT,title TEXT,nip TEXT,qr_file TEXT)");
$db->exec("CREATE TABLE pjlp_leave_balances(employee_id INT,leave_year INT,allowance_days INT,adjustment_days INT)");
$db->exec("CREATE TABLE pjlp_leave_requests(employee_id INT,leave_year INT,requested_days INT,status TEXT)");
$db->exec("INSERT INTO pjlp_leave_approvals VALUES(1,12,'supervisor','atasan1','approve'),(2,12,'lurah','lurah1','approve')");
$db->exec("INSERT INTO pjlp_leave_balances VALUES(1,2026,12,0)");
$db->exec("INSERT INTO pjlp_leave_requests VALUES(1,2026,1,'approved')");
$dir=pjlp_private_dir('qr');
$img=imagecreatetruecolor(120,120);
imagefill($img,0,0,imagecolorallocate($img,255,255,255));
$black=imagecolorallocate($img,0,0,0);
for($i=0;$i<12;$i++)for($j=0;$j<12;$j++)if(($i+$j)%3===0)imagefilledrectangle($img,$i*10,$j*10,$i*10+8,$j*10+8,$black);
$qr='pjlp-ci-test-'.getmypid().'.png';
imagepng($img,$dir.'/'.$qr);imagedestroy($img);
try{
 $p=$db->prepare('INSERT INTO pjlp_officials VALUES(?,?,?,?,?)');
 $p->execute(['atasan1','Atasan Contoh','Kasi Ekonomi dan Pembangunan','123456789',$qr]);
 $p->execute(['lurah1','Lurah Contoh','Lurah Kelurahan Cikoko','987654321',$qr]);
 $row=[
  'id'=>12,'employee_id'=>1,'leave_year'=>2026,'id_phl'=>'PHL1234',
  'user_id'=>'pegawai1','full_name'=>'PEGAWAI CONTOH','position_name'=>'PJLP PPSU',
  'work_unit'=>'Kantor Kelurahan Cikoko','hired_on'=>'2021-01-01',
  'supervisor_user_id'=>'atasan1','submitted_at'=>'2026-11-13 09:00:00',
  'verified_at'=>'2026-11-13 10:00:00','official_number'=>'12/KG 11.01',
  'reason'=>'Keperluan keluarga','start_date'=>'2026-11-16',
  'end_date'=>'2026-11-16','requested_days'=>1,'leave_address'=>'Jakarta Selatan',
  'phone'=>'081234567890',
 ];
 $pdf=pjlp_pdf_build($db,$row);
 if(strncmp($pdf,'%PDF-',5)!==0||strlen($pdf)<1000)throw new RuntimeException('Invalid PDF');
 if(substr_count($pdf,'/Type /Page ')!==1||!str_contains($pdf,'/Count 1'))throw new RuntimeException('Expected exactly one A4 page');
 fwrite(STDOUT,$pdf);
}finally{@unlink($dir.'/'.$qr);}
