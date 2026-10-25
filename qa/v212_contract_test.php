<?php
declare(strict_types=1);
// Static contract tests; production MySQL and push delivery require separately configured tests.
$root=dirname(__DIR__);
$api=file_get_contents($root.'/cpanel/mobile-api/index.php');
$push=file_get_contents($root.'/flutter/lib/push.dart');
$cron=file_get_contents($root.'/cpanel/mobile-api/cron_dispatch.php');
$ppsu=file_get_contents($root.'/cpanel/mobile-api/v211.php');
$tests=[
 'FCM Android sound channel agrees with server'=>str_contains($push,'cikoko_updates_v2')&&str_contains($cron,"'channel_id'=>'cikoko_updates_v2'"),
 'Chat category directs to conversation'=>str_contains($push,"category=='chat'")&&str_contains($push,"'Pesan Masuk':'Hubungi Kami'"),
 'No duplicate content_created event'=>!str_contains($api,"mobile_emit(\$type,\$type==='berita'"),
 'PPSU needs three photos'=>str_contains($ppsu,"['photo1','photo2','photo3']"),
 'PPSU report identity comes from session'=>str_contains($ppsu,"v211_userrow(\$uid)['name']"),
];
$failed=0;foreach($tests as $name=>$ok){echo ($ok?'PASS':'FAIL')." $name\n";if(!$ok)$failed++;}exit($failed?1:0);
