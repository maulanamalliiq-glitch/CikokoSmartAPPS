<?php
declare(strict_types=1);
require dirname(__DIR__).'/cpanel/mobile-api/public_letters.php';
function check_public(bool $yes,string $name):void {
  if(!$yes)throw new RuntimeException('FAIL '.$name);
  echo 'OK '.$name."\n";
}
foreach(['masuk','menunggu_rt'] as $s)
 check_public(cikoko_public_letter_bucket($s)==='masuk',$s);
foreach(['proses','revisi','menunggu_rw','ditolak'] as $s)
 check_public(cikoko_public_letter_bucket($s)==='proses',$s);
foreach(['selesai','terverifikasi'] as $s)
 check_public(cikoko_public_letter_bucket($s)==='selesai',$s);
check_public(cikoko_public_letter_status('menunggu_rw')==='Menunggu verifikasi RW','RT/RW progress label');
$public=file_get_contents(dirname(__DIR__).'/cpanel/mobile-api/public_letters.php');
$index=file_get_contents(dirname(__DIR__).'/cpanel/mobile-api/index.php');
$detail=file_get_contents(dirname(__DIR__).'/cpanel/mobile-api/waris_review.php');
check_public(strpos($index,"if(\$action==='public_letters'") < strpos($index,'$u=mobile_auth()'),'public route before bearer auth');
check_public(!str_contains($public,'applicant_name')&&!str_contains($public,'applicant_nik')&&!str_contains($public,'user_name')&&!str_contains($public,'applicant_address'),'no private fields in public payload');
check_public(str_contains($detail,'hash_equals((string)$report'),'report detail enforces owner before output');
check_public(str_contains($index,'mobile_report_progress') || str_contains($index,'cikoko_report_history_log'),'report progress audit enabled');
echo "Public privacy and status checks passed.\n";
