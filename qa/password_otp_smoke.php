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
echo "OTP configuration and keyed digest smoke passed\n";
