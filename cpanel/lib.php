<?php
declare(strict_types=1);
$config = require __DIR__.'/config.php';
date_default_timezone_set($config['timezone'] ?? 'Asia/Jakarta');
ini_set('session.use_strict_mode', '1');
ini_set('session.cookie_httponly', '1');
if (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ini_set('session.cookie_secure', '1');
header('X-Content-Type-Options: nosniff');
header('Referrer-Policy: strict-origin-when-cross-origin');
header('X-Frame-Options: SAMEORIGIN');
session_start();
function esc($value): string { return htmlspecialchars((string)$value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8'); }
function cfg(string $key): string { global $config; return (string)($config[$key] ?? ''); }
function base(): string { $v=cfg('base_url'); if($v!=='') return rtrim($v,'/'); $path=dirname($_SERVER['SCRIPT_NAME'] ?? '/'); return $path==='/'||$path==='.' ? '' : rtrim($path,'/'); }
function url(string $path=''): string { return base().'/'.ltrim($path,'/'); }
function data_path(string $name): string { return __DIR__.'/data/'.$name.'.json'; }
function db_read(string $name): array { $path=data_path($name); if(!is_file($path)) return []; $fp=fopen($path,'rb'); if(!$fp) return []; flock($fp,LOCK_SH); $raw=stream_get_contents($fp); flock($fp,LOCK_UN); fclose($fp); $result=json_decode($raw?:'[]',true); return is_array($result)?$result:[]; }
function db_write(string $name,array $rows): bool { $before=$name==='content'?db_read('content'):[]; $path=data_path($name); $fp=fopen($path,'c+'); if(!$fp) return false; if(!flock($fp,LOCK_EX)){fclose($fp);return false;} ftruncate($fp,0);rewind($fp);$ok=fwrite($fp,json_encode($rows,JSON_UNESCAPED_UNICODE|JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES))!==false; fflush($fp);flock($fp,LOCK_UN);fclose($fp);
 if($ok && $name==='content'){
  $ids=array_column($before,'id');
  foreach($rows as $entry){
   if(!in_array($entry['id']??null,$ids,true)&&in_array($entry['type']??'', ['berita','pengumuman'],true)){
     try {require_once __DIR__.'/mobile-api/bootstrap.php';mobile_emit((string)$entry['type'],(string)($entry['title']??'Informasi baru'),'Publikasi terbaru Kelurahan Cikoko','public');}
     catch(Throwable $ignored){error_log('Event publish: '.$ignored->getMessage());}
   }
  }
 }
 return $ok; }
function csrf(): string { if(empty($_SESSION['csrf'])) $_SESSION['csrf']=bin2hex(random_bytes(24)); return $_SESSION['csrf']; }
function csrf_check(): void { if(!hash_equals(csrf(),(string)($_POST['csrf'] ?? ''))) {http_response_code(419);exit('Token keamanan tidak valid. Muat ulang halaman.');} }
function is_admin(): bool {return isset($_SESSION['admin']) && $_SESSION['admin']===true;}
function need_admin(): void { if(!is_admin()){header('Location: '.url('login.php'));exit;} }
function setup_complete(): bool {return is_file(__DIR__.'/data/admin.json');}
function sections(): array { return ['berita'=>'Berita & Informasi','pengumuman'=>'Pengumuman','galeri'=>'Galeri Kegiatan','layanan'=>'Layanan Online']; }
function entries(string $type): array { $all=db_read('content'); $found=array_values(array_filter($all,fn($v)=>($v['type']??'')===$type)); usort($found,fn($a,$b)=>strcmp($b['created_at']??'',$a['created_at']??''));return $found; }
function excerpt(string $body,int $limit=110): string { $body=trim(strip_tags($body));return function_exists('mb_strimwidth')?mb_strimwidth($body,0,$limit,'…'):substr($body,0,$limit); }

function appearance_defaults(): array {return [
'brand_logo'=>['file'=>'assets/images/logo-cikoko-keren.jpg','width'=>42,'height'=>42,'zoom'=>100,'x'=>50,'y'=>50,'fit'=>'contain'],
'hero'=>['file'=>'assets/images/kantor-cikoko.jpg','width'=>100,'height'=>100,'zoom'=>100,'x'=>50,'y'=>50,'fit'=>'cover'],
'news'=>['file'=>'','width'=>100,'height'=>100,'zoom'=>100,'x'=>50,'y'=>50,'fit'=>'cover'],
'gallery'=>['file'=>'','width'=>100,'height'=>100,'zoom'=>100,'x'=>50,'y'=>50,'fit'=>'cover'],
'service'=>['file'=>'','width'=>58,'height'=>58,'zoom'=>100,'x'=>50,'y'=>50,'fit'=>'contain'],
'service_1'=>['file'=>'','width'=>58,'height'=>58,'zoom'=>100,'x'=>50,'y'=>50,'fit'=>'contain'],
'service_2'=>['file'=>'','width'=>58,'height'=>58,'zoom'=>100,'x'=>50,'y'=>50,'fit'=>'contain'],
'service_3'=>['file'=>'','width'=>58,'height'=>58,'zoom'=>100,'x'=>50,'y'=>50,'fit'=>'contain'],
'service_4'=>['file'=>'','width'=>58,'height'=>58,'zoom'=>100,'x'=>50,'y'=>50,'fit'=>'contain'],
'service_5'=>['file'=>'','width'=>58,'height'=>58,'zoom'=>100,'x'=>50,'y'=>50,'fit'=>'contain'],
'service_6'=>['file'=>'','width'=>58,'height'=>58,'zoom'=>100,'x'=>50,'y'=>50,'fit'=>'contain']
];}
function appearance(): array {return array_replace_recursive(appearance_defaults(),db_read('appearance'));}
function ap(string $slot): array {$a=appearance();return $a[$slot]??appearance_defaults()['service'];}
function media_css(string $slot,bool $background=false): string {$a=ap($slot);$fit=$a['fit']==='contain'?'contain':'cover';$x=(int)$a['x'];$y=(int)$a['y'];$zoom=(int)$a['zoom'];if($background) return 'background-position:'.$x.'% '.$y.'%;background-size:'.($zoom*1.0).'%;';return 'object-fit:'.$fit.';object-position:'.$x.'% '.$y.'%;transform:scale('.($zoom/100).');';}
function ap_logo(): string {$a=ap('brand_logo');return url($a['file'] ?: 'assets/logo.svg');}
function ap_image(string $slot,string $fallback=''): string {$a=ap($slot);return $a['file']?:$fallback;}

function head_html(string $title=''): void { $title=$title ? esc($title).' | Kelurahan Cikoko':'Kelurahan Cikoko | Website Resmi Pelayanan'; echo '<!doctype html><html lang="id"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="theme-color" content="#0b3156"><meta name="description" content="Portal informasi dan pelayanan Kelurahan Cikoko Kecamatan Pancoran Jakarta Selatan"><title>'.$title.'</title><link rel="stylesheet" href="'.esc(url('assets/style.css')).'"><link rel="icon" type="image/png" href="'.esc(url('assets/cikoko-favicon.png')).'"></head><body>'; }
function public_header(string $active=''): void {echo '<header class="topbar"><a href="'.esc(url()).'" class="identity"><span class="brand-img-wrap" style="width:'.(int)ap('brand_logo')['width'].'px;height:'.(int)ap('brand_logo')['height'].'px"><img style="'.esc(media_css('brand_logo')).'" src="'.esc(ap_logo()).'" alt="Logo Kelurahan Cikoko"></span><span><strong>Kelurahan Cikoko</strong><small>Kecamatan Pancoran · Jakarta Selatan</small></span></a><button class="menu-toggle" aria-label="Buka menu" aria-expanded="false" onclick="document.body.classList.toggle(\'nav-open\');this.setAttribute(\'aria-expanded\',document.body.classList.contains(\'nav-open\'))">☰</button><nav class="navlinks"><a href="'.esc(url()).'">Beranda</a><a href="'.esc(url('index.php#profil')).'">Profil</a><a href="'.esc(url('index.php#layanan')).'">Layanan</a><a href="'.esc(url('index.php#informasi')).'">Informasi</a><a href="'.esc(url('index.php#berita')).'">Berita</a><a href="'.esc(url('index.php#kontak')).'">Kontak</a><a class="login-link" href="'.esc(url('login.php')).'">♙ Login</a></nav></header>';}
function footer_html(): void { echo '<footer class="footer" id="kontak"><div><div class="footer-brand"><span class="brand-img-wrap" style="width:'.(int)ap('brand_logo')['width'].'px;height:'.(int)ap('brand_logo')['height'].'px"><img style="'.esc(media_css('brand_logo')).'" src="'.esc(ap_logo()).'" alt="Logo Cikoko"></span><div><b>Kelurahan Cikoko</b><small>Kecamatan Pancoran · Jakarta Selatan</small></div></div><p>Pelayanan publik yang mudah diakses, transparan, dan responsif.</p></div><div><b>Tautan Cepat</b><a href="'.esc(url()).'">Beranda</a><a href="'.esc(url('index.php#profil')).'">Profil</a><a href="'.esc(url('index.php#layanan')).'">Layanan</a><a href="'.esc(url('index.php#berita')).'">Berita</a></div><div><b>Kontak Kami</b><p>Kelurahan Cikoko, Kecamatan Pancoran, Jakarta Selatan</p><p>Senin–Kamis 07.30–16.00 WIB<br>Jumat 07.30–16.30 WIB</p></div></footer><div class="copyright">© '.date('Y').' Kelurahan Cikoko. Portal demonstrasi siap dikonfigurasi untuk operasional.</div><link rel="stylesheet" href="'.esc(url('assets/mobile-chat.css')).'"><script defer src="'.esc(url('assets/mobile-chat.js')).'"></script><script src="'.esc(url('assets/app.js')).'" defer></script></body></html>'; }
