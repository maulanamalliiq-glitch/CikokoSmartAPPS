<?php
declare(strict_types=1);
require __DIR__.'/bootstrap.php';
$user=aw_identity();
if(!$user['id']){http_response_code(401);exit('Silakan login terlebih dahulu.');}
$id=filter_input(INPUT_GET,'id',FILTER_VALIDATE_INT);
if(!$id || $id<1){http_response_code(400);exit('ID lampiran tidak valid.');}
$db=aw_db();$st=$db->prepare('SELECT d.id,d.storage_name,d.mime_type,d.original_name,a.account_id FROM aw_attachments d JOIN aw_applications a ON a.id=d.application_id WHERE d.id=?');$st->execute([$id]);$row=$st->fetch(PDO::FETCH_ASSOC);
if(!$row){http_response_code(404);exit('Dokumen tidak ditemukan.');}
$role=strtolower((string)($user['role']??''));
$admin=in_array($role,['admin','administrator','asn','lurah'],true);
$owner=$role==='warga'&&hash_equals((string)$row['account_id'],(string)$user['id']);
if(!$admin&&!$owner){http_response_code(403);exit('Tidak memiliki izin melihat dokumen.');}
$dir=realpath(__DIR__.'/private/uploads');
$name=(string)$row['storage_name'];
if(!$dir || !preg_match('/^[a-f0-9]{40}\.(?:jpg|jpeg|png|webp)$/i',$name)){http_response_code(404);exit('Lampiran tidak tersedia.');}
$path=realpath($dir.DIRECTORY_SEPARATOR.$name);
if(!$path || dirname($path)!==$dir || !is_file($path)){http_response_code(404);exit('Berkas tidak ditemukan.');}
$mime=strtolower((string)$row['mime_type']);
if(!in_array($mime,['image/jpeg','image/png','image/webp'],true)){http_response_code(415);exit('Format foto tidak didukung.');}
$isPreview=isset($_GET['preview']) && $_GET['preview']==='1';
header('Content-Type: '.$mime);
header('Content-Disposition: '.($isPreview?'inline':'attachment').'; filename="lampiran-ahli-waris-'.$id.'.'.pathinfo($name,PATHINFO_EXTENSION).'"');
header('Content-Security-Policy: default-src \'none\'; sandbox');
header('Referrer-Policy: no-referrer');
header('X-Content-Type-Options: nosniff');
header('Cache-Control: private, no-store, max-age=0');
header('Content-Length: '.filesize($path));
readfile($path);
