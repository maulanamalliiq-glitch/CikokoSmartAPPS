<?php
require __DIR__.'/lib.php';
need_admin();
$defaults=[
 ['slug'=>'eco-edu-wisata-ciliwung','title'=>'ECO EDU WISATA CILIWUNG','summary'=>'Edukasi lingkungan dan wisata berbasis masyarakat di bantaran Sungai Ciliwung.','body'=>'','image'=>''],
 ['slug'=>'cikoko-bio-farm-education','title'=>'CIKOKO BIO FARM EDUCATION','summary'=>'Edukasi pertanian perkotaan di Kelurahan Cikoko.','body'=>'','image'=>''],
 ['slug'=>'kampung-inggris','title'=>'KAMPUNG INGGRIS','summary'=>'Pembelajaran bahasa Inggris bagi masyarakat Cikoko.','body'=>'','image'=>''],
];
$rows=db_read('cikoko_innovations');$found=[];foreach($rows as $r)if(isset($r['slug']))$found[$r['slug']]=$r;
$items=[];foreach($defaults as $def)$items[]=array_merge($def,$found[$def['slug']]??[]);
$message='';
if($_SERVER['REQUEST_METHOD']==='POST'){
 csrf_check();$slug=(string)($_POST['slug']??'');$index=array_search($slug,array_column($items,'slug'),true);
 if($index===false)$message='Inovasi tidak ditemukan.';
 else{
  $title=trim((string)($_POST['title']??''));$summary=trim((string)($_POST['summary']??''));$body=trim((string)($_POST['body']??''));$image=trim((string)($_POST['image']??''));
  if($title===''||$summary==='')$message='Judul dan ringkasan wajib diisi.';
  elseif($image!==''&&(!filter_var($image,FILTER_VALIDATE_URL)||parse_url($image,PHP_URL_SCHEME)!=='https'))$message='Tautan foto harus menggunakan HTTPS.';
  else{$items[$index]=array_merge($items[$index],['title'=>substr($title,0,160),'summary'=>substr($summary,0,500),'body'=>substr($body,0,8000),'image'=>substr($image,0,255)]);
   $message=db_write('cikoko_innovations',$items)?'Informasi inovasi berhasil disimpan.':'Penyimpanan belum berhasil.';}
 }
}
?><!doctype html><html lang="id"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Kelola Inovasi — Kelurahan Cikoko</title><style>
:root{font-family:system-ui,-apple-system,sans-serif;color:#173957;background:#f3f7fc}*{box-sizing:border-box}body{margin:0}header{background:#11385c;color:white;padding:18px 24px;display:flex;justify-content:space-between;gap:15px}header a{color:white}main{max-width:1160px;margin:24px auto;padding:0 18px}h1{font-size:24px;margin:0 0 6px}.muted{color:#61798c;font-size:13px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(295px,1fr));gap:16px}.card{background:white;border:1px solid #dce5ed;border-radius:15px;padding:18px;box-shadow:0 3px 10px #12385c0c}label{display:block;font-weight:700;font-size:12px;margin:11px 0 5px}input,textarea{width:100%;font:inherit;padding:11px;border:1px solid #cddbe9;border-radius:9px}button{margin-top:14px;border:0;border-radius:9px;padding:11px 18px;background:#216bdb;color:white;font-weight:700;cursor:pointer}small{color:#728496}.notice{background:#e2f2ff;border-radius:8px;padding:10px;margin-bottom:12px}a{color:#1856a4}
</style></head><body><header><strong>Kelurahan Cikoko · Manajemen Inovasi</strong><nav><a href="admin.php">Kembali ke Admin</a> · <a href="inovasi.php">Lihat Publik</a></nav></header><main><h1>Kelola Tiga Inovasi Kelurahan</h1><p class="muted">Konten dapat diedit melalui panel ini dan akan tersedia pada website serta aplikasi. Untuk keamanan, deskripsi dipublikasikan sebagai teks, bukan skrip.</p><?php if($message):?><div class="notice"><?=esc($message)?></div><?php endif;?><div class="grid">
<?php foreach($items as $r):?><form class="card" method="post"><input type="hidden" name="csrf" value="<?=esc(csrf())?>"><input type="hidden" name="slug" value="<?=esc($r['slug'])?>"><h2><?=esc($r['title'])?></h2><label>Judul Inovasi</label><input name="title" maxlength="160" required value="<?=esc($r['title'])?>"><label>Ringkasan</label><textarea name="summary" rows="3" required><?=esc($r['summary'])?></textarea><label>Konten Detail / Deskripsi</label><textarea name="body" rows="8"><?=esc($r['body'])?></textarea><label>URL Foto Sampul (HTTPS)</label><input name="image" value="<?=esc($r['image'])?>"><small>Foto harus berasal dari sumber yang boleh dipublikasikan.</small><div><button>Simpan Inovasi</button></div></form><?php endforeach; ?></div></main></body></html>
