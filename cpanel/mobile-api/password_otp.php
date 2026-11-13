<?php
declare(strict_types=1);

/**
 * Email OTP password recovery for existing portal_users (including PPSU).
 * Main administrator account is intentionally excluded.
 *
 * Mail configuration must be placed OUTSIDE public_html:
 * dirname(__DIR__, 2) . '/cikoko_otp_mail.php'
 * or provided through CIKOKO_OTP_FROM_EMAIL and CIKOKO_OTP_SECRET env vars.
 * No email address, OTP, password or SMTP credential is committed to GitHub.
 */
function cikoko_otp_settings():?array {
 $settings=[];
 $file=dirname(__DIR__,2).'/cikoko_otp_mail.php';
 if(is_file($file)){
  $loaded=require $file;
  if(is_array($loaded))$settings=$loaded;
 }
 $sender=trim((string)($settings['from']??getenv('CIKOKO_OTP_FROM_EMAIL')?:''));
 $secret=trim((string)($settings['secret']??getenv('CIKOKO_OTP_SECRET')?:''));
 if(!filter_var($sender,FILTER_VALIDATE_EMAIL)||!preg_match('/^[a-f0-9]{64}$/iD',$secret))return null;
 $smtpUser=trim((string)($settings['smtp_username']??getenv('CIKOKO_OTP_SMTP_USERNAME')?:''));
 $smtpPassword=preg_replace('/\s+/', '',(string)($settings['smtp_app_password']??getenv('CIKOKO_OTP_SMTP_APP_PASSWORD')?:''));
 if(str_ends_with(strtolower($sender),'@gmail.com')){
  // Gmail sender must be authenticated; never spoof a Gmail From via cPanel mail().
  if(strcasecmp($smtpUser,$sender)!==0||strlen($smtpPassword)<16)return null;
 }
 return ['from'=>$sender,'secret'=>$secret,
  'smtp_username'=>$smtpUser,'smtp_app_password'=>$smtpPassword];
}
function cikoko_otp_send(string $email,string $subject,string $body,string $sender):bool {
 if(str_ends_with(strtolower($sender),'@gmail.com')){
  $config=cikoko_otp_settings();
  if($config===null)return false;
  require_once __DIR__.'/password_otp_smtp.php';
  return cikoko_otp_smtp_send($config,$email,$subject,$body);
 }
 // Domain mailbox senders may use cPanel's local mail transport (Exim).
 $headers=[
  'From: Kelurahan Cikoko <'.$sender.'>',
  'Reply-To: '.$sender,
  'MIME-Version: 1.0',
  'Content-Type: text/plain; charset=UTF-8',
  'Content-Transfer-Encoding: 8bit',
  'X-Auto-Response-Suppress: All',
 ];
 try{
  return @mail($email,$subject,$body,implode("\r\n",$headers),'-f'.$sender);
 }catch(Throwable $e){
  error_log('[Cikoko OTP] Email transport unavailable: '.$e->getMessage());
  return false;
 }
}
function cikoko_otp_identity(string $username,string $email):string {
 return hash('sha256',strtolower(trim($username)).'|'.strtolower(trim($email)));
}
function cikoko_otp_account(string $username,string $email):?array {
 foreach(db_read('portal_users') as $user){
  if(!($user['active']??false)||($user['role']??'')==='admin')continue;
  if(!hash_equals(strtolower((string)($user['username']??'')),strtolower($username)))continue;
  $registered=trim((string)($user['email']??''));
  if($registered!==''&&filter_var($registered,FILTER_VALIDATE_EMAIL)
    &&hash_equals(strtolower($registered),strtolower($email)))return $user;
 }
 return null;
}
function cikoko_otp_reply():void {
 mobile_json(['ok'=>true,'message'=>'Jika username dan email sesuai dengan akun aktif, kode OTP akan dikirim ke email terdaftar. Periksa juga folder Spam.']);
}
function cikoko_password_otp_dispatch(string $action,string $method):void {
 if($method!=='POST')mobile_error('Metode tidak diperbolehkan.',405);
 $db=mobile_db();
 $body=mobile_body();
 $username=mobile_text($body['username']??'',100);
 $email=strtolower(mobile_text($body['email']??'',160));
 if($username===''||!filter_var($email,FILTER_VALIDATE_EMAIL)){
  mobile_error('Isi username dan email yang terdaftar.',422);
 }
 $ip=(string)($_SERVER['REMOTE_ADDR']??'unknown');
 $identity=cikoko_otp_identity($username,$email);
 $settings=cikoko_otp_settings();
 if($settings===null)mobile_error('Pengiriman OTP belum dikonfigurasi oleh pengelola. Hubungi admin Kelurahan.',503);
 if($action==='password_otp_request'){
  cikoko_rate_limit($db,'otp_request_ip',$ip,12,3600);
  cikoko_rate_limit($db,'otp_request_identity',$identity,4,3600);
  $account=cikoko_otp_account($username,$email);
  if($account===null){cikoko_otp_reply();}
  $id=(string)$account['id'];
  $s=$db->prepare('SELECT UNIX_TIMESTAMP(sent_at) FROM mobile_password_otps WHERE user_id=?');
  $s->execute([$id]);$last=$s->fetchColumn();
  if($last!==false&&time()-(int)$last<60){cikoko_otp_reply();}
  $code=(string)random_int(100000,999999);
  $hash=hash_hmac('sha256',$id.'|'.$code,$settings['secret']);
  $s=$db->prepare('INSERT INTO mobile_password_otps(user_id,code_hash,attempts,expires_at,sent_at) VALUES(?,?,0,DATE_ADD(NOW(),INTERVAL 10 MINUTE),NOW()) ON DUPLICATE KEY UPDATE code_hash=VALUES(code_hash),attempts=0,expires_at=VALUES(expires_at),sent_at=VALUES(sent_at)');
  $s->execute([$id,$hash]);
  $message="Kode OTP untuk mengatur ulang kata sandi Cikoko Smart:\n\n"
    .$code."\n\nKode berlaku 10 menit dan hanya dapat digunakan sekali.\n"
    ."Jika Anda tidak meminta pengaturan ulang, abaikan email ini.\n"
    ."Jangan bagikan kode OTP kepada siapa pun, termasuk petugas Kelurahan.\n\n"
    ."Kelurahan Cikoko - Kecamatan Pancoran";
  if(!cikoko_otp_send($email,'Kode OTP Cikoko Smart',$message,$settings['from'])){
   $db->prepare('DELETE FROM mobile_password_otps WHERE user_id=? AND code_hash=?')->execute([$id,$hash]);
   error_log('[Cikoko OTP] OTP email transport rejected password reset message.');
  }
  cikoko_otp_reply();
 }
 if($action!=='password_otp_reset')mobile_error('Aksi tidak dikenal.',404);
 cikoko_rate_limit($db,'otp_reset_ip',$ip,25,3600);
 cikoko_rate_limit($db,'otp_reset_identity',$identity,12,3600);
 $code=trim((string)($body['otp']??''));
 $password=(string)($body['new_password']??'');
 $confirmation=(string)($body['confirm_password']??'');
 if(!preg_match('/^[0-9]{6}$/D',$code))mobile_error('Kode OTP harus berisi 6 angka.',422);
 if(!cikoko_password_valid($password))mobile_error('Kata sandi minimal 10 karakter, memuat huruf dan angka, maksimal 128 karakter.',422);
 if(!hash_equals($password,$confirmation))mobile_error('Konfirmasi kata sandi tidak sesuai.',422);
 $path=data_path('portal_users');
 $fp=@fopen($path,'c+');
 if(!$fp||!flock($fp,LOCK_EX)){if($fp)fclose($fp);mobile_error('Layanan akun sedang digunakan. Coba lagi.',503);}
 $original='';
 $updated=false;
 $success=false;
 try{
  $original=stream_get_contents($fp);
  $users=json_decode($original?:'[]',true,512,JSON_THROW_ON_ERROR);
  if(!is_array($users))throw new RuntimeException('Invalid portal_users data');
  $accountIndex=null;$accountId='';
  foreach($users as $i=>$u){
   if(!($u['active']??false)||($u['role']??'')==='admin')continue;
   if(strcasecmp((string)($u['username']??''),$username)!==0)continue;
   if(strcasecmp(trim((string)($u['email']??'')),$email)!==0)continue;
   $accountIndex=$i;$accountId=(string)($u['id']??'');break;
  }
  if($accountIndex!==null&&$accountId!==''){
   $db->beginTransaction();
   $s=$db->prepare('SELECT code_hash,attempts FROM mobile_password_otps WHERE user_id=? AND expires_at>NOW() FOR UPDATE');
   $s->execute([$accountId]);$record=$s->fetch(PDO::FETCH_ASSOC);
   if($record&&((int)$record['attempts'])<5){
    $expected=hash_hmac('sha256',$accountId.'|'.$code,$settings['secret']);
    if(hash_equals((string)$record['code_hash'],$expected)){
     $users[$accountIndex]['password_hash']=password_hash($password,PASSWORD_DEFAULT);
     $payload=json_encode($users,JSON_UNESCAPED_UNICODE|JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES|JSON_THROW_ON_ERROR);
     rewind($fp);$updated=true;
     if(!ftruncate($fp,0)||fwrite($fp,$payload)!==strlen($payload)||!fflush($fp)){
      throw new RuntimeException('Failed to persist password reset');
     }
     $db->prepare('DELETE FROM mobile_password_otps WHERE user_id=?')->execute([$accountId]);
     $db->prepare('DELETE FROM mobile_tokens WHERE user_id=?')->execute([$accountId]);
     $db->prepare('DELETE FROM mobile_devices WHERE user_id=?')->execute([$accountId]);
     $db->commit();
     $success=true;
    }else{
     $db->prepare('UPDATE mobile_password_otps SET attempts=attempts+1 WHERE user_id=?')->execute([$accountId]);
     $db->commit();
    }
   }else{
    if($record)$db->prepare('DELETE FROM mobile_password_otps WHERE user_id=?')->execute([$accountId]);
    $db->commit();
   }
  }
 }catch(Throwable $e){
  if($db->inTransaction())$db->rollBack();
  if($updated){rewind($fp);ftruncate($fp,0);fwrite($fp,$original);fflush($fp);}
  error_log('[Cikoko OTP] Reset failure: '.$e->getMessage());
  flock($fp,LOCK_UN);fclose($fp);
  mobile_error('Kata sandi belum dapat diperbarui. Silakan coba kembali.',503);
 }
 flock($fp,LOCK_UN);fclose($fp);
 if(!$success)mobile_error('Kode OTP tidak sesuai, kedaluwarsa, atau batas percobaan habis. Minta kode baru jika perlu.',422);
 cikoko_otp_send($email,'Kata sandi Cikoko Smart diperbarui',
  "Kata sandi akun Cikoko Smart Anda baru saja diperbarui.\n"
  ."Semua sesi login sebelumnya telah dicabut.\n"
  ."Jika ini bukan tindakan Anda, segera hubungi Admin Kelurahan Cikoko.\n",$settings['from']);
 mobile_json(['ok'=>true,'message'=>'Kata sandi berhasil diperbarui. Silakan masuk kembali menggunakan kata sandi baru.']);
}
