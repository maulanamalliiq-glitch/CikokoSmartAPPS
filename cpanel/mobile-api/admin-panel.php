<?php
/** Include inside admin.php, or open standalone with existing PHP admin session */
require_once __DIR__.'/bootstrap.php';
$allowed=is_admin() || (($_SESSION['portal_role']??'')==='admin_kelurahan' && !empty($_SESSION['portal_uid']));
if(!$allowed){http_response_code(403);exit('Hanya Admin Kelurahan.');}
$db=mobile_db();$error='';$notice='';
if($_SERVER['REQUEST_METHOD']==='POST'){
 csrf_check();$id=mobile_text($_POST['user_id']??'',80);$reply=mobile_text($_POST['message']??'',2000);
 if($id===''||$reply==='')$error='Penerima dan balasan wajib diisi.';
 else {$chk=$db->prepare('SELECT name FROM mobile_chat WHERE user_id=? LIMIT 1');$chk->execute([$id]);$name=$chk->fetchColumn();if(!$name)$error='Percakapan tidak ditemukan';else{$s=$db->prepare('INSERT INTO mobile_chat(user_id,name,sender,message) VALUES(?,"Admin Kelurahan","admin",?)');$s->execute([$id,$reply]);mobile_emit('chat','Pesan dari Admin','Buka Hubungi Kami untuk membaca balasan','personal',$id);$notice='Balasan berhasil dikirim.';}}
}
$threads=$db->query('SELECT m.user_id,m.name,m.message,m.created_at FROM mobile_chat m INNER JOIN (SELECT user_id,MAX(id) last_id FROM mobile_chat GROUP BY user_id) t ON m.id=t.last_id ORDER BY m.id DESC LIMIT 100')->fetchAll();
?><div class="cikoko-chat-admin" style="font:13px system-ui;color:#17385d"><h2>Hubungi Kami · Pesan Warga</h2><p>Pesan masuk di luar jam kerja tetap tersimpan. Jadwal Senin–Kamis 07.30–16.00, Jumat 07.30–16.30 WIB.</p><?php if($error):?><p role="alert" style="color:#a11"><?=esc($error)?></p><?php endif;?><?php if($notice):?><p style="color:green"><?=esc($notice)?></p><?php endif;?><div style="display:grid;gap:12px"><?php foreach($threads as $t):?><div style="background:white;border:1px solid #dbe5ef;border-radius:12px;padding:12px"><b><?=esc($t['name'])?></b><small style="float:right"><?=esc($t['created_at'])?></small><p><?=esc($t['message'])?></p><form method="post"><input type="hidden" name="csrf" value="<?=esc(csrf())?>"><input type="hidden" name="user_id" value="<?=esc($t['user_id'])?>"><div style="display:flex;gap:8px"><input name="message" required maxlength="2000" placeholder="Tulis balasan petugas..." style="flex:1;padding:9px;border:1px solid #ddd;border-radius:8px"><button style="background:#216fdb;color:#fff;border:0;border-radius:8px;padding:9px 16px">Balas</button></div></form></div><?php endforeach;?><?php if(!$threads):?><p>Belum ada pesan warga.</p><?php endif;?></div></div>
