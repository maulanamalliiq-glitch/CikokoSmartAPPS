<?php
declare(strict_types=1);

/**
 * Gmail SMTP transport for OTP messages.
 * Uses authenticated TLS on port 465 and verifies Google's certificate.
 * Gmail app password is read only from a private cPanel file/environment.
 * Do not log SMTP authentication commands, OTP content or credentials.
 */
function cikoko_smtp_expect($stream,array $expected):bool {
 $count=0;
 do {
  $line=@fgets($stream,2048);
  if(!is_string($line)||strlen($line)<4)return false;
  $code=(int)substr($line,0,3);
  $continuation=substr($line,3,1)==='-';
  $count++;
  if($count>40)return false;
 }while($continuation);
 return in_array($code,$expected,true);
}
function cikoko_smtp_command($stream,string $command,array $expected):bool {
 $line=$command."\r\n";
 $written=@fwrite($stream,$line);
 if($written!==strlen($line))return false;
 return cikoko_smtp_expect($stream,$expected);
}
function cikoko_otp_smtp_send(array $config,string $recipient,string $subject,string $body):bool {
 $sender=(string)($config['from']??'');
 $user=(string)($config['smtp_username']??'');
 $password=(string)($config['smtp_app_password']??'');
 if(!filter_var($sender,FILTER_VALIDATE_EMAIL)||!filter_var($recipient,FILTER_VALIDATE_EMAIL)
  ||!filter_var($user,FILTER_VALIDATE_EMAIL)||$password==='')return false;
 // Gmail only: do not allow a request to choose an arbitrary SMTP destination.
 if(!str_ends_with(strtolower($sender),'@gmail.com')
  ||strcasecmp($sender,$user)!==0)return false;
 if(preg_match('/[\r\n]/',$subject)||preg_match('/[\r\n]/',$recipient))return false;
 $context=stream_context_create(['ssl'=>[
  'verify_peer'=>true,'verify_peer_name'=>true,
  'peer_name'=>'smtp.gmail.com','SNI_enabled'=>true,
 ]]);
 $errno=0;$errstr='';
 $socket=@stream_socket_client('ssl://smtp.gmail.com:465',$errno,$errstr,20,STREAM_CLIENT_CONNECT,$context);
 if($socket===false){
  error_log('[Cikoko OTP] Gmail SMTP connection unavailable (check outbound port 465).');
  return false;
 }
 stream_set_timeout($socket,20);
 $success=false;
 try{
  $headers=[
   'From: Kelurahan Cikoko <'.$sender.'>',
   'To: <'.$recipient.'>',
   'Subject: '.$subject,
   'Date: '.gmdate('D, d M Y H:i:s').' +0000',
   'MIME-Version: 1.0',
   'Content-Type: text/plain; charset=UTF-8',
   'Content-Transfer-Encoding: 8bit',
   'Auto-Submitted: auto-generated',
  ];
  // SMTP DATA lines beginning with "." must be dot-stuffed.
  $normalized=str_replace(["\r\n","\r"],"\n",$body);
  $lines=explode("\n",$normalized);
  foreach($lines as &$line){if(str_starts_with($line,'.'))$line='.'. $line;}
  unset($line);
  $message=implode("\r\n",$headers)."\r\n\r\n".implode("\r\n",$lines)."\r\n.\r\n";
  if(!cikoko_smtp_expect($socket,[220]))return false;
  if(!cikoko_smtp_command($socket,'EHLO cikoko-smart',[250]))return false;
  if(!cikoko_smtp_command($socket,'AUTH LOGIN',[334]))return false;
  if(!cikoko_smtp_command($socket,base64_encode($user),[334]))return false;
  if(!cikoko_smtp_command($socket,base64_encode($password),[235]))return false;
  if(!cikoko_smtp_command($socket,'MAIL FROM:<'.$sender.'>',[250]))return false;
  if(!cikoko_smtp_command($socket,'RCPT TO:<'.$recipient.'>',[250,251]))return false;
  if(!cikoko_smtp_command($socket,'DATA',[354]))return false;
  if(@fwrite($socket,$message)!==strlen($message))return false;
  if(!cikoko_smtp_expect($socket,[250]))return false;
  $success=true;
  cikoko_smtp_command($socket,'QUIT',[221]);
  return true;
 }catch(Throwable $e){
  error_log('[Cikoko OTP] Gmail SMTP transaction failed.');
  return false;
 }finally{
  @fclose($socket);
  if(!$success)error_log('[Cikoko OTP] Gmail SMTP delivery rejected or timed out.');
 }
}
