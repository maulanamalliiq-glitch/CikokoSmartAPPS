<?php
declare(strict_types=1);
require __DIR__.'/lib.php';
need_admin();
require_once __DIR__.'/mobile-api/bootstrap.php';
require_once __DIR__.'/mobile-api/admin_push_center.php';
$pushHealth=['status'=>'not_run','cron_active'=>false,'devices'=>0,
 'pending'=>0,'accepted'=>0,'last_run'=>'Belum ada'];
try{
 $pushDb=mobile_db();
 cikoko_push_health_schema($pushDb);
 $heartbeat=$pushDb->query('SELECT last_run_at,status,fcm_accepted FROM
   mobile_push_dispatch_health WHERE id=1')->fetch(PDO::FETCH_ASSOC);
 $pushHealth['devices']=(int)$pushDb->query('SELECT COUNT(*) FROM mobile_devices
   WHERE fcm_token<>""')->fetchColumn();
 $pushHealth['pending']=(int)$pushDb->query('SELECT COUNT(*) FROM mobile_events
   WHERE audience="personal" AND dispatched_at IS NULL')->fetchColumn();
 if($heartbeat){
   $pushHealth['status']=(string)$heartbeat['status'];
   $pushHealth['accepted']=(int)$heartbeat['fcm_accepted'];
   $pushHealth['last_run']=(string)$heartbeat['last_run_at'];
   $lastTs=strtotime((string)$heartbeat['last_run_at']);
   $pushHealth['cron_active']=$lastTs!==false && time()-$lastTs<=300;
 }
}catch(Throwable $e){error_log('[Cikoko web push diagnostic] '.$e->getMessage());}


$accountList=[['id'=>'admin','name'=>'Administrator Utama','role'=>'admin']];
foreach(db_read('portal_users') as $account){
    if(!is_array($account)||empty($account['active'])||empty($account['id']))continue;
    $accountList[]=[
        'id'=>(string)$account['id'],
        'name'=>(string)($account['name']??$account['username']??'Pengguna'),
        'role'=>(string)($account['role']??'petugas')
    ];
}
usort($accountList,static function(array $a,array $b):int{
    if($a['id']==='admin')return -1;
    if($b['id']==='admin')return 1;
    return strcmp($a['role'].' '.$a['name'],$b['role'].' '.$b['name']);
});

$notice='';
$error='';
$totalRecipients=0;

if(($_SERVER['REQUEST_METHOD']??'GET')==='POST'){
    csrf_check();
    $category=(string)($_POST['category']??'info_aplikasi');
    $scope=(string)($_POST['scope']??'public');
    $recipient=trim((string)($_POST['recipient']??''));
    $title=trim((string)($_POST['title']??''));
    $message=trim((string)($_POST['message']??''));
    $allowedCategories=['info_aplikasi','berita','pengumuman','inovasi'];
    $allowedScopes=['public','warga','staff','personal'];

    if(!in_array($category,$allowedCategories,true)
       ||!in_array($scope,$allowedScopes,true)){
        $error='Jenis dan penerima tidak valid.';
    }elseif(strlen($title)<5||strlen($title)>180
          ||strlen($message)<10||strlen($message)>900){
        $error='Judul harus 5–180 karakter, pesan 10–900 karakter.';
    }elseif(empty($_POST['confirm_send'])){
        $error='Konfirmasikan pengiriman terlebih dahulu.';
    }elseif((int)($_SESSION['cikoko_notice_last_sent']??0)>time()-30){
        $error='Tunggu setidaknya 30 detik sebelum pengiriman berikutnya.';
    }else{
        $allowedIds=array_column($accountList,'id');
        if($scope==='personal'&&
          ($recipient===''||!in_array($recipient,$allowedIds,true))){
            $error='Akun penerima tidak ditemukan atau sudah tidak aktif.';
        }else{
            try{
                $targets=mobile_notification_recipients(
                    $category,$scope,$scope==='personal'?$recipient:null
                );
                $targets=array_values(array_filter($targets,static fn($row)=>
                    ($row['audience']??'')==='personal'&&
                    trim((string)($row['recipient']??''))!==''
                ));
                if(!$targets)throw new RuntimeException('Belum ada akun aktif pada kelompok penerima tersebut.');
                if(count($targets)>5000)throw new RuntimeException('Maksimal 5000 akun per pengiriman.');

                $pdo=mobile_db();
                $st=$pdo->prepare('INSERT INTO mobile_events
                  (category,title,message,audience,recipient) VALUES (?, ?, ?, "personal", ?)');
                $pdo->beginTransaction();
                try{
                    foreach($targets as $t){
                        $st->execute([
                            $category,$title,$message,(string)$t['recipient']
                        ]);
                    }
                    $pdo->commit();
                }catch(Throwable $e){
                    if($pdo->inTransaction())$pdo->rollBack();
                    throw $e;
                }
                $totalRecipients=count($targets);
                $_SESSION['cikoko_notice_last_sent']=time();
                $notice='Notifikasi tersimpan untuk '.$totalRecipients.
                    ' akun. Aplikasi akan menampilkannya pada kotak masuk; '.
                    'push Android dikirim jika Firebase dan Cron Jobs aktif.';
            }catch(Throwable $e){
                error_log('[Cikoko website notice] '.$e->getMessage());
                $error='Pengiriman belum berhasil. Periksa koneksi API, database, dan log PHP.';
            }
        }
    }
}

$csrf=csrf();
?><!doctype html>
<html lang="id"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="robots" content="noindex,nofollow">
<title>Pusat Notifikasi — Admin Cikoko Smart</title>
<style>
:root{font-family:system-ui,-apple-system,Segoe UI,sans-serif;color:#0c234a;background:#f5f8ff}
*{box-sizing:border-box}body{margin:0}header{padding:19px 5%;background:#fff;
border-bottom:1px solid #dce7f5;display:flex;gap:15px;align-items:center;
justify-content:space-between;flex-wrap:wrap}
header b{font-size:19px}header small{display:block;color:#61748c;margin-top:5px}
a{color:#0766de;text-decoration:none;font-size:12px;font-weight:700}
main{max-width:960px;margin:25px auto;padding:0 15px 35px}
article{background:#fff;border:1px solid #dce7f5;border-radius:16px;padding:22px;
box-shadow:0 4px 20px #122d530a}
h1{font-size:23px;margin:0 0 5px}p{font-size:13px;line-height:1.6;color:#60728a}
label{display:block;font-size:12px;font-weight:750;margin:15px 0 7px}
input,textarea,select{display:block;width:100%;font:inherit;font-size:13px;
padding:12px;border-radius:10px;border:1px solid #ccdbea;background:#fff;color:#102a4b}
textarea{resize:vertical;min-height:130px}.grid{display:grid;
grid-template-columns:repeat(2,minmax(0,1fr));gap:0 17px}
button{background:#0967e7;color:#fff;border:0;border-radius:10px;
padding:13px 22px;font:inherit;font-size:13px;font-weight:800;cursor:pointer}
.note{background:#eff5fc;border:1px solid #dbe6f1;padding:12px 15px;
border-radius:10px;margin:14px 0;font-size:12px;line-height:1.6}
.alert{padding:13px;border-radius:10px;margin:14px 0;font-size:13px}
.alert.ok{background:#e5f7ef;color:#166b48}
.alert.bad{background:#fff1f1;color:#9d2532}
.confirm{display:flex;gap:9px;align-items:flex-start;margin:17px 0}
.confirm input{width:auto;margin:2px 0}.confirm label{margin:0;line-height:1.5}
footer{font-size:11px;color:#72849b;margin-top:18px}
@media(max-width:680px){.grid{grid-template-columns:1fr}article{padding:15px}}
</style></head><body>
<header>
<div><b>Pusat Notifikasi Cikoko Smart</b>
<small>Kelurahan Cikoko · Website → Mobile API → Android</small></div>
<a href="<?=esc(url('admin.php'))?>">← Kembali ke Dashboard Admin</a>
</header><main>
<article>
<h1>Kirim Notifikasi ke Aplikasi</h1>
<div class="note">
<b>Diagnostik Pengiriman ke HP</b>
<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:10px;margin-top:12px">
<div><b>Token HP</b><div style="font-size:23px;color:#0967e7"><?=esc((string)$pushHealth['devices'])?></div></div>
<div><b>Antrean push</b><div style="font-size:23px;color:#cf8114"><?=esc((string)$pushHealth['pending'])?></div></div>
<div><b>FCM diterima (siklus terakhir)</b><div style="font-size:23px;color:#178750"><?=esc((string)$pushHealth['accepted'])?></div></div>
</div>
<p style="margin:9px 0 0">
Cron: <b><?=esc($pushHealth['cron_active']?'Terdeteksi aktif':'Belum terdeteksi aktif')?></b>
 · Status: <b><?=esc((string)$pushHealth['status'])?></b>
 · Terakhir: <?=esc((string)$pushHealth['last_run'])?>
</p>
<p style="margin:6px 0 0">
<b>Catatan:</b> angka akun penerima hanya menunjukkan penyimpanan notifikasi.
Push ke HP memerlukan token perangkat dan proses Firebase yang berhasil.
Jika token HP = 0, login aplikasi Android dan aktifkan izin notifikasi.
Jika Cron tidak aktif, periksa Cron Jobs di cPanel.</p>
</div>
<p>Notifikasi disampaikan ke akun sesuai kelompok penerima. Tidak perlu
mengubah APK saat admin menerbitkan informasi baru.</p>
<?php if($notice!==''):?><div class="alert ok"><?=esc($notice)?></div><?php endif;?>
<?php if($error!==''):?><div class="alert bad"><?=esc($error)?></div><?php endif;?>
<form method="post" autocomplete="off">
<input type="hidden" name="csrf" value="<?=esc($csrf)?>">
<div class="grid">
<div><label for="category">Jenis Pemberitahuan</label>
<select id="category" name="category">
<option value="info_aplikasi">Informasi Umum</option>
<option value="berita">Berita Terbaru</option>
<option value="pengumuman">Pengumuman</option>
<option value="inovasi">Inovasi Kelurahan</option>
</select></div>
<div><label for="scope">Penerima</label>
<select id="scope" name="scope">
<option value="public">Semua akun aktif</option>
<option value="warga">Warga saja</option>
<option value="staff">Petugas dan admin saja</option>
<option value="personal">Satu akun tertentu</option>
</select></div></div>
<div id="single-recipient" hidden>
<label for="recipient">Pilih Akun</label>
<select id="recipient" name="recipient">
<option value="">— Pilih akun tujuan —</option>
<?php foreach($accountList as $a):?>
<option value="<?=esc($a['id'])?>"><?=esc($a['name'].' · '.$a['role'])?></option>
<?php endforeach;?></select></div>
<label for="title">Judul Notifikasi</label>
<input id="title" name="title" minlength="5" maxlength="180" required
placeholder="Contoh: Pengumuman Pelayanan Kelurahan">
<label for="message">Isi Notifikasi</label>
<textarea id="message" name="message" minlength="10" maxlength="900" required
placeholder="Tulis pengumuman singkat dan jelas. Jangan masukkan NIK atau data pribadi."></textarea>
<div class="note"><b>Pengiriman:</b> Setelah disimpan, notifikasi langsung
tersedia di ikon lonceng akun penerima saat aplikasi memuat data.
Agar muncul di layar Android saat aplikasi ditutup,
pastikan Cron Jobs dan konfigurasi Firebase aktif.</div>
<div class="confirm">
<input type="checkbox" id="confirm_send" name="confirm_send" value="1" required>
<label for="confirm_send">Saya telah memeriksa isi pesan dan penerimanya.
Informasi ini tidak mengandung NIK atau data warga yang tidak boleh disebarkan.</label>
</div>
<button type="submit">Kirim Notifikasi</button>
</form></article>
<footer>Hanya admin website yang sudah login dapat membuka halaman ini.
Tidak ada token Firebase atau kata sandi database yang ditampilkan.</footer>
</main>
<script>
(function(){
const scope=document.getElementById('scope');
const section=document.getElementById('single-recipient');
const select=document.getElementById('recipient');
function sync(){const personal=scope.value==='personal';
section.hidden=!personal;select.required=personal;}
scope.addEventListener('change',sync);sync();
})();
</script></body></html>
