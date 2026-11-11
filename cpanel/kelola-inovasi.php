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
 csrf_check();
 $slug=(string)($_POST['slug']??'');
 $index=array_search($slug,array_column($items,'slug'),true);
 if($index===false){$message='Inovasi tidak ditemukan.';}
 else {
  $title=trim((string)($_POST['title']??''));
  $summary=trim((string)($_POST['summary']??''));
  $body=trim((string)($_POST['body']??''));
  $images=array_values(array_filter($items[$index]['images']??[],'is_string'));
  if(!$images&&!empty($items[$index]['image']))$images=[(string)$items[$index]['image']];
  $remove=array_map('strval',(array)($_POST['remove_images']??[]));
  $images=array_values(array_diff($images,$remove));
  $added=[];
  if($title===''||$summary===''){$message='Judul dan ringkasan wajib diisi.';}
  else {
   $uploads=$_FILES['photos']??null;
   if($uploads && is_array($uploads['name']??null)){
    foreach($uploads['name'] as $i=>$original){
     $error=(int)($uploads['error'][$i]??UPLOAD_ERR_NO_FILE);
     if($error===UPLOAD_ERR_NO_FILE)continue;
     if($error!==UPLOAD_ERR_OK||count($images)>=5){$message='Unggah gagal atau jumlah foto melebihi 5.';break;}
     $tmp=$uploads['tmp_name'][$i]??'';
     if(!is_uploaded_file($tmp)||($uploads['size'][$i]??0)>4*1024*1024){$message='Setiap foto maksimal 4 MB.';break;}
     $mime=(new finfo(FILEINFO_MIME_TYPE))->file($tmp);
     $ext=['image/jpeg'=>'jpg','image/png'=>'png','image/webp'=>'webp'][$mime]??null;
     if(!$ext){$message='Gunakan foto JPG, PNG, atau WebP.';break;}
     $dir=__DIR__.'/assets/images';
     if(!is_dir($dir)&&!mkdir($dir,0755,true)){$message='Folder foto tidak dapat dibuat.';break;}
     $relative='assets/images/inovasi-'.bin2hex(random_bytes(16)).'.'.$ext;
     if(!move_uploaded_file($tmp,__DIR__.'/'.$relative)){$message='Foto gagal disimpan.';break;}
     $added[]=$relative;$images[]=$relative;
    }
   }
   if($message===''){
    $items[$index]=array_merge($items[$index],[
     'title'=>substr($title,0,160),'summary'=>substr($summary,0,500),
     'body'=>substr($body,0,8000),'images'=>$images,'image'=>$images[0]??''
    ]);
    $message=db_write('cikoko_innovations',$items)?'Inovasi dan foto berhasil disimpan.':'Penyimpanan gagal.';
   }
   if($message!=='Inovasi dan foto berhasil disimpan.')foreach($added as $file)@unlink(__DIR__.'/'.$file);
  }
 }
}
?><!doctype html><html lang="id"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Kelola Inovasi — Kelurahan Cikoko</title><style>
:root{font-family:system-ui,-apple-system,sans-serif;color:#173957;background:#f3f7fc}*{box-sizing:border-box}body{margin:0}header{background:#11385c;color:white;padding:18px 24px;display:flex;justify-content:space-between;gap:15px}header a{color:white}main{max-width:1160px;margin:24px auto;padding:0 18px}h1{font-size:24px;margin:0 0 6px}.muted{color:#61798c;font-size:13px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(295px,1fr));gap:16px}.card{background:white;border:1px solid #dce5ed;border-radius:15px;padding:18px;box-shadow:0 3px 10px #12385c0c}label{display:block;font-weight:700;font-size:12px;margin:11px 0 5px}input,textarea{width:100%;font:inherit;padding:11px;border:1px solid #cddbe9;border-radius:9px}button{margin-top:14px;border:0;border-radius:9px;padding:11px 18px;background:#216bdb;color:white;font-weight:700;cursor:pointer}small{color:#728496}.notice{background:#e2f2ff;border-radius:8px;padding:10px;margin-bottom:12px}a{color:#1856a4}.thumb{width:100%;max-height:150px;object-fit:cover;border-radius:8px}.photos{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:8px}.photo{background:#f2f6fa;padding:6px;border-radius:9px}.photo label{font-weight:500}
</style></head><body><header><strong>Kelurahan Cikoko · Manajemen Inovasi</strong><nav><a href="admin.php">Kembali ke Admin</a> · <a href="inovasi.php">Lihat Publik</a></nav></header><main><h1>Kelola Tiga Inovasi Kelurahan</h1><p class="muted">Konten dapat diedit melalui panel ini dan akan tersedia pada website serta aplikasi. Untuk keamanan, deskripsi dipublikasikan sebagai teks, bukan skrip.</p><?php if($message):?><div class="notice"><?=esc($message)?></div><?php endif;?><div class="grid">
<?php foreach($items as $r):?><form class="card" method="post" enctype="multipart/form-data"><input type="hidden" name="csrf" value="<?=esc(csrf())?>"><input type="hidden" name="slug" value="<?=esc($r['slug'])?>"><h2><?=esc($r['title'])?></h2><label>Judul Inovasi</label><input name="title" maxlength="160" required value="<?=esc($r['title'])?>"><label>Ringkasan</label><textarea name="summary" rows="3" required><?=esc($r['summary'])?></textarea><label>Konten Detail / Deskripsi</label><textarea name="body" rows="8"><?=esc($r['body'])?></textarea><label>Foto Inovasi (maksimal 5)</label><div class="photos"><?php $photos=array_values(array_filter($r['images']??[],'is_string'));if(!$photos&&!empty($r['image']))$photos=[(string)$r['image']];foreach($photos as $photo):$src=(preg_match('~^https://~',$photo)?$photo:('/'.ltrim($photo,'/')));?><div class="photo"><img class="thumb" src="<?=esc($src)?>" alt="Foto inovasi"><label><input type="checkbox" name="remove_images[]" value="<?=esc($photo)?>"> Hapus foto</label></div><?php endforeach;?></div><label>Tambah Foto dari Galeri</label><input type="file" name="photos[]" accept="image/jpeg,image/png,image/webp" multiple><small>JPG, PNG, WebP; maksimal 4 MB per foto dan 5 foto total.</small><div><button>Simpan Inovasi</button></div></form><?php endforeach; ?></div></main></body></html>
