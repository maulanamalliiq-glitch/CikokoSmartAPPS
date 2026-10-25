<?php
declare(strict_types=1);
/**
 * Cikoko SmartApp — halaman detail konten publik.
 * Memulihkan tautan detail.php?id=service-* dari page.php?p=layanan.
 * Tidak mengubah konfigurasi, database, atau sesi pengguna.
 */
require __DIR__.'/lib.php';

$id = trim((string)($_GET['id'] ?? ''));
// Konten hanya dicari menurut ID yang dikeluarkan CMS.
if ($id === '' || strlen($id) > 100 || !preg_match('/^[a-zA-Z0-9_-]+$/D', $id)) {
    http_response_code(404);
    $item = null;
} else {
    $item = null;
    foreach (db_read('content') as $entry) {
        if (is_array($entry) && (string)($entry['id'] ?? '') === $id &&
            in_array((string)($entry['type'] ?? ''), ['layanan', 'berita', 'pengumuman', 'galeri'], true)) {
            $item = $entry;
            break;
        }
    }
}

if (!$item) {
    http_response_code(404);
}

$isService = $item !== null && ($item['type'] ?? '') === 'layanan';
$details = [];
if ($isService) {
    $all = db_read('service_details');
    $candidate = $all[$id] ?? [];
    $details = is_array($candidate) ? $candidate : [];
    // Respect settings in the existing CMS; unpublished services are not exposed.
    if (isset($details['active']) && !$details['active']) {
        http_response_code(404);
        $item = null;
        $isService = false;
        $details = [];
    }
}

$title = $item ? (string)($item['title'] ?? 'Detail Pelayanan') : 'Halaman Tidak Ditemukan';
$category = $item ? (sections()[(string)($item['type'] ?? '')] ?? 'Informasi Kelurahan') : 'Informasi Kelurahan';
$summary = $item ? trim((string)($details['summary'] ?? $item['body'] ?? '')) : '';
$created = $item ? strtotime((string)($item['created_at'] ?? '')) : false;

/** Restrict optional media to known local uploads/assets and trusted site HTTPS URLs. */
function cikoko_detail_image_url(string $path): string {
    $path = trim($path);
    if ($path === '' || strpos($path, '..') !== false || strpos($path, "\\") !== false || preg_match('/[\x00-\x1f]/', $path)) return '';
    if (preg_match('~^(assets|uploads)/[a-zA-Z0-9_./-]+$~D', $path)) return url($path);
    if (filter_var($path, FILTER_VALIDATE_URL)) {
        $u = parse_url($path);
        $site = (string)($_SERVER['HTTP_HOST'] ?? 'datawebs.my.id');
        if (strtolower((string)($u['scheme'] ?? '')) === 'https' && strtolower((string)($u['host'] ?? '')) === strtolower(explode(':', $site)[0])) return $path;
    }
    return '';
}
function cikoko_detail_link(string $raw): string {
    $raw = trim($raw);
    if ($raw !== '' && filter_var($raw, FILTER_VALIDATE_URL)) {
        $parsed = parse_url($raw);
        if (in_array(strtolower((string)($parsed['scheme'] ?? '')), ['https','http'], true)) return $raw;
    }
    return '';
}

$image = $item ? cikoko_detail_image_url((string)($details['image'] ?? $item['image'] ?? '')) : '';
$actionUrl = $item ? cikoko_detail_link((string)($details['link'] ?? $item['link'] ?? '')) : '';
$related = $isService ? entries('layanan') : [];
$css = esc(url('assets/cikoko-service-detail.css?v=20261025'));
ob_start();
head_html($title);
$head = ob_get_clean();
echo str_replace('</head>', '<link rel="stylesheet" href="'.$css.'"></head>', $head);
?>
<div class="site-shell">
<?php public_header(); ?>
<main class="csd-main">
  <div class="csd-breadcrumb"><a href="<?=esc(url('index.php'))?>">Beranda</a><span>›</span><a href="<?=esc(url('page.php?p=layanan'))?>">Layanan Masyarakat</a><span>›</span><span><?=esc($title)?></span></div>
  <?php if (!$item): ?>
    <section class="csd-card csd-empty">
      <span class="csd-pill">Kelurahan Cikoko</span>
      <h1>Informasi belum tersedia</h1>
      <p>Halaman layanan ini tidak ditemukan. Silakan kembali ke daftar pelayanan atau menghubungi petugas kelurahan untuk informasi lebih lanjut.</p>
      <a class="csd-button" href="<?=esc(url('page.php?p=layanan'))?>">Kembali ke Layanan Masyarakat</a>
    </section>
  <?php else: ?>
  <section class="csd-hero">
    <div class="csd-hero-content">
      <span class="csd-pill"><?=esc($category)?></span>
      <h1><?=esc($title)?></h1>
      <p><?=esc($summary)?></p>
      <div class="csd-hero-actions">
        <a class="csd-button csd-button-light" href="<?=esc(url('page.php?p=layanan'))?>">← Semua Pelayanan</a>
        <?php if ($actionUrl): ?><a class="csd-button csd-button-outline-light" href="<?=esc($actionUrl)?>" target="_blank" rel="noopener noreferrer"><?=esc($details['button'] ?? 'Buka Halaman Pelayanan')?> ↗</a><?php endif; ?>
      </div>
    </div>
    <?php if ($image): ?><img class="csd-cover" src="<?=esc($image)?>" alt="Ilustrasi <?=esc($title)?>" loading="lazy"><?php endif; ?>
  </section>
  <div class="csd-grid">
    <article class="csd-article">
      <section class="csd-card">
        <div class="csd-section-title"><span class="csd-icon">i</span><div><span class="csd-overline">PENJELASAN</span><h2>Tentang Pelayanan</h2></div></div>
        <div class="csd-body"><?=nl2br(esc((string)($item['body'] ?? $summary)))?></div>
      </section>
      <?php foreach (['requirements'=>['Persyaratan Pelayanan','Dokumen dan ketentuan yang perlu disiapkan'],'steps'=>['Alur Pelayanan','Langkah-langkah pengajuan']] as $field=>$meta): ?>
        <?php if (trim((string)($details[$field] ?? '')) !== ''): ?>
          <section class="csd-card">
            <div class="csd-section-title"><span class="csd-icon"><?=$field==='requirements'?'✓':'↗'?></span><div><span class="csd-overline">INFORMASI RESMI</span><h2><?=esc($meta[0])?></h2></div></div>
            <p class="csd-muted"><?=esc($meta[1])?></p>
            <div class="csd-body"><?=nl2br(esc((string)$details[$field]))?></div>
          </section>
        <?php endif; ?>
      <?php endforeach; ?>
      <section class="csd-card csd-help">
        <div><h2>Memerlukan bantuan?</h2><p>Petugas Kelurahan Cikoko siap memberikan informasi mengenai persyaratan dan prosedur layanan.</p></div>
        <a class="csd-button" href="<?=esc(url('page.php?p=kontak'))?>">Hubungi Kelurahan →</a>
      </section>
    </article>
    <aside class="csd-sidebar">
      <?php if($isService): ?>
      <section class="csd-card csd-info"><h2>Informasi Pelayanan</h2>
        <?php foreach(['hours'=>'Waktu Pelayanan','cost'=>'Biaya','duration'=>'Estimasi Proses'] as $field=>$label): ?>
          <?php if(trim((string)($details[$field]??''))!==''):?><div class="csd-meta"><span><?=esc($label)?></span><b><?=esc($details[$field])?></b></div><?php endif; ?>
        <?php endforeach; ?>
        <?php if (!$actionUrl): ?><p class="csd-muted">Untuk pengajuan dan persyaratan terbaru, silakan hubungi petugas kelurahan.</p><?php endif; ?>
      </section>
      <section class="csd-card csd-list"><h2>Layanan Lainnya</h2>
        <?php foreach($related as $entry): ?>
          <?php if(($entry['id']??'')!==$id): ?>
          <a href="<?=esc(url('detail.php?id='.rawurlencode((string)$entry['id'])))?>"><span><?=esc($entry['title']??'Pelayanan')?></span><span aria-hidden="true">→</span></a>
          <?php endif; ?>
        <?php endforeach; ?>
      </section>
      <?php else: ?>
      <section class="csd-card"><h2>Informasi</h2><?php if($created): ?><p class="csd-muted">Diterbitkan: <?=esc(date('d-m-Y', $created))?></p><?php endif; ?><a class="csd-button" href="<?=esc(url('page.php?p=berita'))?>">Lihat Informasi Lainnya</a></section>
      <?php endif; ?>
    </aside>
  </div>
  <?php endif; ?>
</main>
</div>
<?php footer_html(); ?>
