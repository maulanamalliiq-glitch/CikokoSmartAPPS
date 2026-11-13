<?php
declare(strict_types=1);
/** Public, read-only official directory entry opened from an admin-generated QR. */
require_once __DIR__.'/bootstrap.php';
header('X-Content-Type-Options: nosniff');
header('Referrer-Policy: no-referrer');
header('X-Frame-Options: DENY');
header('Cache-Control: public, max-age=120');
header('X-Robots-Tag: noindex, nofollow');
$token=(string)($_GET['id']??'');
if(!preg_match('/^[a-f0-9]{48}$/D',$token)){http_response_code(404);exit('Profil tidak ditemukan');}
try {
 $db=mobile_db();
 $s=$db->prepare('SELECT full_name,title,nip,work_unit,photo_file FROM pjlp_officials WHERE public_token=? AND is_public=1 LIMIT 1');
 $s->execute([$token]);$p=$s->fetch(PDO::FETCH_ASSOC);
}catch(Throwable $e){error_log('PPSU profile: '.$e->getMessage());http_response_code(503);exit('Profil belum tersedia');}
if(!$p){http_response_code(404);exit('Profil tidak ditemukan');}
if(($_GET['photo']??'')==='1'){
 $file=(string)($p['photo_file']??'');
 if(!preg_match('/^[a-f0-9]{32}\.(jpg|png)$/D',$file)){http_response_code(404);exit;}
 $path=__DIR__.'/private/pjlp/photos/'.$file;
 if(!is_file($path)){http_response_code(404);exit;}
 $type=str_ends_with($file,'.png')?'image/png':'image/jpeg';
 header('Content-Type: '.$type);header('Content-Length: '.filesize($path));readfile($path);exit;
}
if(($_GET['signature']??'')==='1'){
 foreach(['png'=>'image/png','jpg'=>'image/jpeg'] as $ext=>$mime){
  $path=__DIR__.'/private/pjlp/signatures/'.$token.'.'.$ext;
  if(is_file($path)){
   header('Content-Type: '.$mime);
   header('Content-Length: '.filesize($path));
   header('Cache-Control: private, no-store');
   readfile($path);exit;
  }
 }
 http_response_code(404);exit;
}
header("Content-Security-Policy: default-src 'none'; img-src 'self'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'");
function esc(string $v):string{return htmlspecialchars($v,ENT_QUOTES|ENT_SUBSTITUTE,'UTF-8');}
$name=esc((string)$p['full_name']);$title=esc((string)$p['title']);
$nip=esc((string)$p['nip']);$unit=esc((string)$p['work_unit']);
$hasSignature=is_file(__DIR__.'/private/pjlp/signatures/'.$token.'.png')||is_file(__DIR__.'/private/pjlp/signatures/'.$token.'.jpg');
$signature=$hasSignature?'<img class="signature" src="?id='.esc($token).'&amp;signature=1" alt="Gambar tanda tangan pimpinan">':'<div class="signature-empty">Tanda tangan belum diunggah admin</div>';
$photo=$p['photo_file']?'<img class="portrait" src="?id='.esc($token).'&amp;photo=1" alt="Foto resmi pimpinan">':'<div class="portrait empty">Foto belum tersedia</div>';
echo '<!doctype html><html lang="id"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Profil Pimpinan - Kelurahan Cikoko</title><style>
*{box-sizing:border-box}body{margin:0;background:#edf3fa;color:#163253;font:16px system-ui,-apple-system,Arial,sans-serif}
header{background:#0e4b8b;color:white;padding:25px 18px;text-align:center}
main{max-width:560px;margin:25px auto;padding:0 16px}.card{background:white;border-radius:17px;padding:24px;box-shadow:0 5px 24px #183b6417;text-align:center}
.portrait{display:block;margin:0 auto 20px;width:155px;height:190px;object-fit:cover;border-radius:12px;background:#dfe9f4}.empty{display:grid;place-items:center;color:#64748b;font-size:13px}
h1{font-size:22px;margin:5px 0 8px}h2{font-size:16px;font-weight:500;color:#46617d;margin:0 0 22px}
dl{text-align:left;margin:0}dt{font-size:12px;text-transform:uppercase;color:#6b7f96;letter-spacing:.06em;margin-top:16px}dd{margin:3px 0 0;font-weight:600}
.signature{display:block;max-width:240px;max-height:125px;object-fit:contain;margin:12px auto}.signature-empty{font-size:13px;color:#6b7f96;margin:15px 0}.verified{display:inline-flex;gap:8px;align-items:center;color:#147b3e;background:#e8f8ed;border-radius:24px;padding:9px 14px;font-weight:700;font-size:13px;margin:16px 0}.note{font-size:13px;line-height:1.55;color:#49617c;background:#f2f7fd;padding:13px;border-radius:9px;margin-top:22px}
footer{text-align:center;color:#6b7f96;font-size:12px;padding:18px}
</style></head><body><header><strong>PEMERINTAH PROVINSI DKI JAKARTA</strong><div>Kelurahan Cikoko · Kecamatan Pancoran</div></header><main><section class="card">'.$photo.'<h1>'.$name.'</h1><h2>'.$title.'</h2><div class="verified">✓ Profil terverifikasi oleh Admin</div><dl><dt>NIP</dt><dd>'.$nip.'</dd><dt>Unit Kerja</dt><dd>'.$unit.'</dd></dl><h2 style="margin:22px 0 8px;font-weight:700">Tanda Tangan</h2>'.$signature.'<p class="note">Data profil ini disimpan dan dipublikasikan oleh admin Kelurahan Cikoko. Status terverifikasi menunjukkan pengelolaan data oleh admin, bukan tanda tangan elektronik tersertifikasi atau bukti persetujuan surat.</p></section><footer>Informasi sesuai data terbaru yang disimpan admin.</footer></main></body></html>';
