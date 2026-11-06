<?php
declare(strict_types=1);
function mobile_error(string $message,int $code=400):void {throw new RuntimeException($message);}
require __DIR__.'/../cpanel/mobile-api/pdf_native.php';
$lines=['CIKOKO LPJ PDF QA - NOT A REAL DOCUMENT'];
for($i=1;$i<=100;$i++)$lines[]="Test aktivitas ke-{$i}: pengeluaran dan verifikasi tercetak tanpa hilang.";
cikoko_pdf_render('cikoko-qa.pdf',$lines);
