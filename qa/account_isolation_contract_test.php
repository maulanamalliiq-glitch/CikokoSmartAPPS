<?php
declare(strict_types=1);
/** Offline contract checks. Live hosting/database tests are separate. */
$root=dirname(__DIR__);
$api=file_get_contents($root.'/cpanel/mobile-api/index.php');
$profile=file_get_contents($root.'/cpanel/mobile-api/v211.php');
$cron=file_get_contents($root.'/cpanel/mobile-api/cron_dispatch.php');
$checks=[
 'event inbox is limited to authenticated personal recipient'=>
  str_contains($api,'WHERE e.audience="personal" AND e.recipient=:recipient'),
 'read-status cannot target another applicant'=>
  str_contains($api,'WHERE id=? AND audience="personal" AND recipient=?'),
 'event response includes audience and recipient for client filtering'=>
  str_contains($api,'e.audience,e.recipient'),
 'device unlink checks both owner and FCM token'=>
  str_contains($api,'DELETE FROM mobile_devices WHERE user_id=? AND fcm_token=?'),
 'FCM never sends broadcast to every device'=>
  str_contains($cron,"WHERE user_id=?")&&
  str_contains($cron,"!==\'personal\'"),
 'FCM includes account ID for old-account push guard'=>
  str_contains($cron,"'account_id'=>(string)\$event['recipient']"),
 'registration persists RT and RW'=>
  str_contains($api,"'rt'=>\$rt,'rw'=>\$rw"),
 'profile API returns actual saved RT/RW'=>
  str_contains($profile,"'rt'=>(string)(\$row['rt']??'')")&&
  str_contains($profile,"'rw'=>(string)(\$row['rw']??'')"),
 'RT/RW changes require current password'=>
  str_contains($profile,'password_verify($password,'),
 'profile persistence goes through portal_users writer'=>
  str_contains($profile,'v211_saveuser($uid,$changes)'),
];
$failed=0;
foreach($checks as $name=>$ok){
 echo ($ok?'PASS':'FAIL')." {$name}\n";
 if(!$ok)$failed++;
}
exit($failed?1:0);
