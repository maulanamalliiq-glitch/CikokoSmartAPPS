<?php
function db_read(string $key):array{return [
 ['id'=>'asn1','role'=>'asn','active'=>true],
 ['id'=>'support1','role'=>'admin_kelurahan','active'=>true],
 ['id'=>'citizen1','role'=>'warga','active'=>true],
 ['id'=>'off','role'=>'admin_kelurahan','active'=>false],
 ['id'=>'admin','role'=>'admin','active'=>true],
];}
function mobile_can(array $u,string $key):bool{
 if($u['user_role']==='admin')return true;
 return $u['user_id']==='asn1'?in_array($key,['reports:view','waris:view'],true):($u['user_id']==='support1'&&$key==='chat:reply');
}
require __DIR__.'/../cpanel/mobile-api/notification_recipients.php';
function check(bool $ok,string $name):void{if(!$ok)throw new RuntimeException($name);echo "PASS $name\n";}
$chat=mobile_notification_recipients('chat','admin',null);
check(array_column($chat,'recipient')===['admin','support1'],'chat goes privately only to support-authorized accounts');
$reports=mobile_notification_recipients('laporan_masuk','admin',null);
check(array_column($reports,'recipient')===['admin','asn1'],'reports go to authorized reviewers');
$waris=mobile_notification_recipients('surat','admin',null);
check(array_column($waris,'recipient')===['admin','asn1'],'waris goes to authorized reviewers');
check(array_unique(array_column($chat,'audience'))===['personal'],'staff inbox events have personal audience');
check(mobile_notification_recipients('chat','personal','citizen1')===[['audience'=>'personal','recipient'=>'citizen1']],'admin reply remains private to that citizen');
check(mobile_notification_recipients('chat','personal',null)===[],'no unaddressed private events');
check(mobile_notification_recipients('news','public',null)===[['audience'=>'public','recipient'=>null]],'public news not inserted into private inboxes');
