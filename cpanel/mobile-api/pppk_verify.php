<?php
declare(strict_types=1);
header('Content-Type: text/html; charset=utf-8');
header('X-Content-Type-Options: nosniff');
header('Cache-Control: no-store');
require __DIR__.'/bootstrap.php';
$token=(string)($_GET['token']??'');
if(!preg_match('/^[a-f0-9]{48}$/D',$token)){http_response_code(404);exit('Dokumen tidak ditemukan');}
$db=mobile_db();
$q=$db->prepare("SELECT report_month,employee_name,employee_nip,reviewed_at,status FROM pppk_monthly_reports WHERE approved_token=? AND status='approved' LIMIT 1");
$q->execute([$token]);$r=$q->fetch(PDO::FETCH_ASSOC);
if(!$r){http_response_code(404);exit('Dokumen belum disetujui atau tidak ditemukan');}
function e(string $s):string{return htmlspecialchars($s,ENT_QUOTES|ENT_SUBSTITUTE,'UTF-8');}
echo '<!doctype html><html lang="id"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Verifikasi Laporan Kinerja PPPK</title><body style="font:16px system-ui;background:#f3f7fc;padding:24px"><main style="background:white;border-radius:16px;max-width:540px;margin:30px auto;padding:28px"><h2>Kelurahan Cikoko</h2><h3>Verifikasi Laporan Kinerja PPPK</h3><p style="color:green"><b>Disetujui Admin</b></p><p>Pegawai: '.e((string)$r['employee_name']).'</p><p>NIP/No. Pegawai: '.e((string)$r['employee_nip']).'</p><p>Bulan: '.e((string)$r['report_month']).'</p><p>Tanggal persetujuan: '.e((string)$r['reviewed_at']).'</p><p>QR ini merupakan verifikasi persetujuan administratif, bukan tanda tangan elektronik tersertifikasi.</p></main></body></html>';
