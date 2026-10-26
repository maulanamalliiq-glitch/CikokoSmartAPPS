<?php
declare(strict_types=1);
// Test mapping fields without production data or an external database.
require dirname(__DIR__).'/cpanel/mobile-api/waris_review.php';
function check(bool $pass,string $message):void {
    if(!$pass)throw new RuntimeException('FAIL: '.$message);
    echo "OK: ".$message."\n";
}
$expected=['r1','r2','r3','r4_ktp','r4_kk','r4_akta','r5','r6'];
check(waris_required_upload_codes(0,true)===$expected,'3 separate heir photos are mandatory alongside the other required documents');
$withChild=waris_required_upload_codes(1,true);
check(count($withChild)===11,'one child adds exactly 3 required photos');
check(array_slice($withChild,-3)===['child_1_ktp','child_1_kk','child_1_akta'],'each child has independent KTP, KK, birth certificate photo codes');
check(count(waris_required_upload_codes(10,true))===38,'10 children add 30 independent photos');
check(count(waris_required_upload_codes(15,true))===38,'children bounded to 10');
check(waris_required_upload_codes(1,false)===['r1','r2','r3','r4','r5','r6','child_1'],'old Android uploads remain recognized');
$labels=waris_codes(1);
foreach(['r4_ktp'=>'KTP Ahli Waris','r4_kk'=>'KK Ahli Waris','r4_akta'=>'Akta Lahir Ahli Waris','child_1_ktp'=>'KTP Anak ke-1','child_1_kk'=>'KK Anak ke-1','child_1_akta'=>'Akta Lahir Anak ke-1'] as $key=>$label)
 check(($labels[$key]??null)===$label,'label '.$key);
check(isset($labels['r4'],$labels['child_1'],$labels['r7'],$labels['r8']),'historical and conditional documents kept');
$dart=file_get_contents(dirname(__DIR__).'/flutter/lib/main.dart');
check(str_contains($dart,"'document_format':'split_v1'"),'Flutter requests split document format');
check(str_contains($dart,'child_${i}_${e.key}'),'Flutter child photos keyed independently');
echo "V2516 waris individual-document tests passed.\n";
