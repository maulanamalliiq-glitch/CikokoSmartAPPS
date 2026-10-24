<?php
require __DIR__.'/bootstrap.php';
header('Content-Type: application/json; charset=utf-8');
if(empty($_SESSION['mobile_web_csrf']))$_SESSION['mobile_web_csrf']=bin2hex(random_bytes(20));
$uid=(string)($_SESSION['portal_uid']??'');
if($uid===''){$uid=$_SESSION['web_guest_id']??='guest-'.bin2hex(random_bytes(14));}
if($_SERVER['REQUEST_METHOD']==='GET'){
 $q=mobile_db()->prepare('SELECT sender,message,created_at FROM mobile_chat WHERE user_id=? ORDER BY id DESC LIMIT 40');$q->execute([$uid]);mobile_json(['ok'=>true,'csrf'=>$_SESSION['mobile_web_csrf'],'messages'=>array_reverse($q->fetchAll())]);
}
if($_SERVER['REQUEST_METHOD']==='POST'){
 $b=mobile_body();if(!hash_equals($_SESSION['mobile_web_csrf'],(string)($b['csrf']??'')))mobile_error('Sesi formulir tidak sesuai',419);
 if(!empty($b['website']))mobile_error('Pesan ditolak',400);
 $name=mobile_text($b['name']??$_SESSION['portal_name']??'Warga',120);$contact=mobile_text($b['contact']??'',120);$msg=mobile_text($b['message']??'',2500);
 if(mb_strlen($name)<2||mb_strlen($msg)<5)mobile_error('Isi nama dan pesan minimal 5 karakter',422);
 $q=mobile_db()->prepare('SELECT created_at FROM mobile_chat WHERE user_id=? AND sender="warga" ORDER BY id DESC LIMIT 1');$q->execute([$uid]);$last=$q->fetchColumn();if($last&&strtotime($last)>time()-20)mobile_error('Tunggu 20 detik sebelum mengirim pesan lagi',429);
 $q=mobile_db()->prepare('INSERT INTO mobile_chat(user_id,name,sender,message) VALUES (?,? ,"warga",?)');$q->execute([$uid,$name.($contact?' ('.$contact.')':''),$msg]);mobile_emit('chat','Pesan Hubungi Kami masuk','Silakan balas melalui Admin Kelurahan','admin');mobile_json(['ok'=>true]);
}
mobile_error('Method not allowed',405);
