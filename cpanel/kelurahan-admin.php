<?php
require __DIR__.'/roles-lib.php';portal_need();
if(portal_role()!=='admin_kelurahan' && !is_admin()){http_response_code(403);exit('Akses khusus Admin Kelurahan.');}
$tab=(string)($_GET['tab']??'arsip');if(!in_array($tab,['arsip','berita','pengumuman'],true))$tab='arsip';
if($tab==='arsip'){require __DIR__.'/kelurahan-arsip-waris.php';exit;}
$kind=$tab;$message='';$error='';
if($_SERVER['REQUEST_METHOD']==='POST'){
  csrf_check();$title=trim((string)($_POST['title']??''));$body=trim((string)($_POST['body']??''));
  if($title===''||$body==='')$error='Judul dan isi wajib diisi.';
  else{
    $photo='';if(isset($_FILES['photo']) && $_FILES['photo']['error']!==UPLOAD_ERR_NO_FILE){
      $f=$_FILES['photo'];if($f['error']===UPLOAD_ERR_OK && $f['size']<=4*1024*1024){
        $mime=(new finfo(FILEINFO_MIME_TYPE))->file($f['tmp_name']);$ext=['image/jpeg'=>'jpg','image/png'=>'png','image/webp'=>'webp'][$mime]??null;
        if($ext){$photo='assets/images/upload-'.bin2hex(random_bytes(12)).'.'.$ext;if(!move_uploaded_file($f['tmp_name'],__DIR__.'/'.$photo)){$photo='';$error='Upload foto gagal.';}}
        else $error='Hanya foto JPG, PNG, WebP.';
      }else $error='Foto maksimal 4 MB.';
    }
    if(!$error){$all=db_read('content');$all[]=['id'=>bin2hex(random_bytes(12)),'type'=>$kind,'title'=>$title,'body'=>$body,'link'=>'','image'=>$photo,'created_at'=>date('Y-m-d H:i:s')];if(db_write('content',$all)){header('Location: kelurahan-admin.php?tab='.$kind.'&saved=1');exit;}else $error='Gagal menyimpan konten.';}
  }
}
$list=entries($kind);$message=isset($_GET['saved'])?'Konten berhasil diterbitkan.':'';
?><!doctype html><html lang="id"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Admin Kelurahan Cikoko</title><link rel="stylesheet" href="assets/portal.css"><style>body{margin:0;background:#f3f7fd;font:14px system-ui;color:#153455}.office{display:grid;grid-template-columns:245px 1fr;min-height:100vh}.side{background:#103457;color:white;padding:22px}.side a{display:block;color:#eaf1fb;padding:12px;text-decoration:none;border-radius:10px}.side a.sel{background:#2875df}.main{padding:24px}.box{max-width:1000px;background:white;border:1px solid #dce6f0;border-radius:16px;padding:20px}.box input,.box textarea{display:block;width:100%;box-sizing:border-box;padding:11px;margin:7px 0 14px;border:1px solid #dce6f0;border-radius:10px}.box button{background:#2473df;color:white;border:0;border-radius:10px;padding:11px 24px;cursor:pointer}.row{padding:12px 0;border-bottom:1px solid #edf1f5}@media(max-width:740px){.office{grid-template-columns:1fr}.side{position:relative}.main{padding:12px}}</style></head><body><div class="office"><nav class="side"><h3>Admin Kelurahan</h3><a href="kelurahan-admin.php?tab=arsip">Tambah / Arsip Ahli Waris</a><a class="<?=$tab==='berita'?'sel':''?>" href="?tab=berita">Tambah Berita</a><a class="<?=$tab==='pengumuman'?'sel':''?>" href="?tab=pengumuman">Tambah Pengumuman</a><a href="mobile-api/admin-panel.php">Hubungi Kami · Pesan</a><a href="index.php">Lihat Website</a><a href="portal.php?tab=profile">Profil</a></nav><main class="main"><h1>Tambah <?=$tab==='berita'?'Berita':'Pengumuman'?></h1><?php if($error):?><p role="alert"><?=esc($error)?></p><?php endif;?><?php if($message):?><p><?=esc($message)?></p><?php endif;?><div class="box"><form method="post" enctype="multipart/form-data"><input type="hidden" name="csrf" value="<?=esc(csrf())?>"><label>Judul<input name="title" required maxlength="200"></label><label>Isi Konten<textarea name="body" required rows="5"></textarea></label><label>Foto (opsional)<input type="file" name="photo" accept="image/jpeg,image/png,image/webp"></label><button>Simpan dan Terbitkan</button></form><h3>Konten Terkini</h3><?php foreach(array_slice($list,0,20) as $item):?><div class="row"><?=esc($item['title'])?></div><?php endforeach;?></div></main></div></body></html>
