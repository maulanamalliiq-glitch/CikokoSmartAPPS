<?php
declare(strict_types=1);
require __DIR__.'/../cpanel/mobile-api/password_otp.php';
putenv('CIKOKO_OTP_FROM_EMAIL=no-reply@example.com');
putenv('CIKOKO_OTP_SECRET='.str_repeat('a',64));
$settings=cikoko_otp_settings();
if(!$settings||$settings['from']!=='no-reply@example.com'||strlen($settings['secret'])!==64){
 fwrite(STDERR,"OTP mail configuration smoke failed\n");exit(1);
}
if(cikoko_otp_identity('PPSU01','User@Example.com')!==cikoko_otp_identity('ppsu01','user@example.com')){
 fwrite(STDERR,"OTP account identity normalization failed\n");exit(1);
}
$first=hash_hmac('sha256','employee-123|123456',$settings['secret']);
$second=hash_hmac('sha256','employee-123|123457',$settings['secret']);
if(hash_equals($first,$second)||strlen($first)!==64){
 fwrite(STDERR,"OTP hash isolation failed\n");exit(1);
}
// Gmail sender must never fall back to spoofable local mail().
putenv('CIKOKO_OTP_FROM_EMAIL=cikokosmarthome@gmail.com');
putenv('CIKOKO_OTP_SMTP_USERNAME=cikokosmarthome@gmail.com');
putenv('CIKOKO_OTP_SMTP_APP_PASSWORD');
if(cikoko_otp_settings()!==null){
 fwrite(STDERR,"Gmail without SMTP credentials should not be enabled\n");exit(1);
}
putenv('CIKOKO_OTP_SMTP_APP_PASSWORD='.str_repeat('x',16));
$gmail=cikoko_otp_settings();
if(!$gmail||$gmail['from']!=='cikokosmarthome@gmail.com'
  ||$gmail['smtp_username']!==$gmail['from']){
 fwrite(STDERR,"Gmail SMTP configuration validation failed\n");exit(1);
}
echo "OTP configuration, Gmail SMTP guard and keyed digest smoke passed\n";
