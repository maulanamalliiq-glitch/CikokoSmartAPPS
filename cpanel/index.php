<?php
declare(strict_types=1);
require __DIR__.'/lib.php';
// Public homepage reuses the existing CMS and account routes, never a second database.
$news=array_slice(entries('berita'),0,3);
$announcements=array_slice(entries('pengumuman'),0,2);
$services=array_slice(entries('layanan'),0,6);
$slides=[];
foreach(db_read('cikoko_home_slides') as $row){
 $name=is_array($row)?(string)($row['name']??''):'';
 if(preg_match('/^[a-f0-9]{40}\.(jpg|png|webp)$/D',$name))$slides[]=url('mobile-api/index.php?action=home_slide_photo&name='.rawurlencode($name));
 if(count($slides)>=5)break;
}
$logo=ap_logo();
$accountPath='login.php';
$accountLabel='Masuk Akun';
if(is_admin()){
    $accountPath='admin.php';
    $accountLabel='Dashboard Admin';
}elseif(!empty($_SESSION['portal_uid']) && !empty($_SESSION['portal_role'])){
    $accountPath='portal.php';
    $accountLabel='Buka Akun';
}
header('Content-Type: text/html; charset=utf-8');
?><!doctype html>
<html lang="id"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="theme-color" content="#12366f"><meta name="description" content="Layanan dan informasi resmi Kelurahan Cikoko, Kecamatan Pancoran, Jakarta Selatan.">
<title>Cikoko SmartAPP — Kelurahan Cikoko</title>
<link rel="stylesheet" href="<?=esc(url('assets/cikoko-smartapp-home-2546.css'))?>"></head>
<body class="cs-app"><a class="cs-skip" href="#cs-main">Langsung ke isi</a>
<header class="cs-topbar"><div class="cs-topbar-inner">
<a class="cs-brand" href="<?=esc(url())?>"><img src="<?=esc($logo)?>" width="46" height="46" alt="Logo Kelurahan Cikoko"><span><strong>Cikoko SmartAPP</strong><small>Portal Kelurahan Cikoko</small></span></a>
<nav class="cs-desktop-nav" aria-label="Navigasi utama"><a href="<?=esc(url())?>" aria-current="page">Beranda</a><a href="<?=esc(url('page.php?p=profil'))?>">Tentang Kami</a><a href="<?=esc(url('listing.php?type=layanan'))?>">Layanan</a><a href="<?=esc(url('informasi.php'))?>">Informasi</a><a href="<?=esc(url('inovasi.php'))?>">Inovasi</a></nav>
<a class="cs-login" href="<?=esc(url($accountPath))?>"><?=esc($accountLabel)?> ↗</a>
</div></header>
<main id="cs-main" class="cs-shell">
<section class="cs-hero"><div class="cs-hero-text">
<span class="cs-kicker"><span class="cs-dot"></span> Informasi dan pelayanan masyarakat</span>
<h1>Selamat Datang di<br><span>Cikoko SmartAPP</span></h1>
<p>Akses informasi kelurahan, layanan administrasi dan kegiatan warga melalui portal yang terhubung dengan layanan resmi.</p>
<div class="cs-hero-actions"><a class="cs-btn cs-primary" href="<?=esc(url('listing.php?type=layanan'))?>">Jelajahi Layanan →</a><a class="cs-btn cs-outline" href="<?=esc(url('portal.php'))?>">Akun Warga</a></div>
</div><div class="cs-hero-media" data-gallery>
<?php if($slides):foreach($slides as $i=>$src):?><img class="cs-hero-slide<?=$i===0?' is-active':''?>" src="<?=esc($src)?>" alt="Dokumentasi Cikoko <?=($i+1)?>" data-slide loading="<?=$i===0?'eager':'lazy'?>">
<?php endforeach;else:?><div class="cs-hero-placeholder"><span>CIKOKO</span><b>SMARTAPP</b><small>Kelurahan Cikoko · Pancoran</small></div><?php endif;?>
<div class="cs-hero-caption"><b>◆</b><div><strong>Kelurahan Cikoko</strong><small>Kecamatan Pancoran, Jakarta Selatan</small></div></div></div></section>
<section class="cs-overview" aria-label="Akses cepat">
<a href="<?=esc(url('listing.php?type=layanan'))?>"><b>01</b><span>Pelayanan<br><strong>Terintegrasi</strong></span><i>↗</i></a>
<a href="<?=esc(url('informasi.php'))?>"><b>02</b><span>Informasi<br><strong>Kelurahan</strong></span><i>↗</i></a>
<a href="<?=esc(url('portal.php'))?>"><b>03</b><span>Layanan<br><strong>Akun Warga</strong></span><i>↗</i></a></section>
<section class="cs-section" id="layanan"><div class="cs-heading"><div><span class="cs-eyebrow">AKSES LAYANAN</span><h2>Layanan untuk Warga</h2><p>Pilih layanan dan ikuti persyaratan yang tercantum.</p></div><a class="cs-more" href="<?=esc(url('listing.php?type=layanan'))?>">Seluruh Layanan ↗</a></div><div class="cs-service-grid">
<?php if($services):foreach($services as $i=>$item):
$id=(string)($item['id']??'');
$href=$id!==''&&preg_match('/^[A-Za-z0-9_-]{1,120}$/D',$id)?url('detail.php?id='.rawurlencode($id)):url('listing.php?type=layanan');
$icons=['▣','▤','◇','♧','◉','▦'];?>
<a class="cs-service" href="<?=esc($href)?>"><span class="cs-service-icon"><?=esc($icons[$i%6])?></span><strong><?=esc((string)($item['title']??'Layanan Kelurahan'))?></strong><small><?=esc(excerpt((string)($item['body']??''),95))?></small><span class="cs-service-arrow">→</span></a>
<?php endforeach;else:?><a class="cs-service" href="<?=esc(url('listing.php?type=layanan'))?>"><span class="cs-service-icon">▣</span><strong>Daftar Pelayanan</strong><small>Informasi terbaru dari Kelurahan Cikoko.</small>→</a><?php endif;?>
</div></section>
<section class="cs-section"><div class="cs-heading"><div><span class="cs-eyebrow">KABAR TERKINI</span><h2>Informasi Cikoko</h2><p>Berita dan pengumuman kelurahan.</p></div><a class="cs-more" href="<?=esc(url('informasi.php'))?>">Lihat Semua ↗</a></div><div class="cs-news-grid">
<?php foreach($announcements as $item):?><article class="cs-news"><span class="cs-news-type">PENGUMUMAN</span><h3><?=esc((string)($item['title']??'Pengumuman'))?></h3><p><?=esc(excerpt((string)($item['body']??''),135))?></p><a href="<?=esc(url('informasi.php?type=pengumuman'))?>">Buka pengumuman →</a></article><?php endforeach;?>
<?php foreach($news as $item):?><article class="cs-news"><span class="cs-news-type">BERITA</span><h3><?=esc((string)($item['title']??'Berita Kelurahan'))?></h3><p><?=esc(excerpt((string)($item['body']??''),135))?></p><a href="<?=esc(url('informasi.php?type=berita'))?>">Buka berita →</a></article><?php endforeach;?>
<?php if(!$news&&!$announcements):?><div class="cs-news">Belum ada publikasi terbaru. <a href="<?=esc(url('informasi.php'))?>">Buka Pusat Informasi →</a></div><?php endif;?>
</div></section>
<section class="cs-help"><div class="cs-help-icon">♧</div><div><h2>Butuh Bantuan Pelayanan?</h2><p>Petugas kelurahan dapat membantu Anda menggunakan aplikasi dan layanan masyarakat.</p></div><a href="<?=esc(url('page.php?p=kontak'))?>">Hubungi Kelurahan ↗</a></section></main>
<footer class="cs-footer"><span><img src="<?=esc($logo)?>" width="30" height="30" alt=""> Kelurahan Cikoko · Kecamatan Pancoran</span><small>© <?=date('Y')?> Cikoko SmartAPP</small></footer>
<nav class="cs-mobile-nav" aria-label="Navigasi bawah"><a href="<?=esc(url('page.php?p=profil'))?>"><span>▤</span>Tentang Kami</a><a href="<?=esc(url('listing.php?type=layanan'))?>"><span>▦</span>Menu</a><a class="cs-center" href="<?=esc(url())?>" aria-current="page"><span>⌂</span>Beranda</a><a href="<?=esc(url('inovasi.php'))?>"><span>✧</span>Inovasi</a><a href="<?=esc(url('portal.php'))?>"><span>♙</span>Akun</a></nav>
<script src="<?=esc(url('assets/cikoko-smartapp-home-2546.js'))?>" defer></script>
</body></html>
