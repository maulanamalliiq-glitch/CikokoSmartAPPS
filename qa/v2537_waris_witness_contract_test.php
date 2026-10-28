<?php
declare(strict_types=1);
$root=dirname(__DIR__);
$module=file_get_contents($root.'/cpanel/mobile-api/waris_witnesses.php');
$routes=file_get_contents($root.'/cpanel/mobile-api/index.php');
$review=file_get_contents($root.'/cpanel/mobile-api/waris_review.php');
$form=file_get_contents($root.'/flutter/lib/main.dart');
$details=file_get_contents($root.'/flutter/lib/document_detail.dart');
$checks=[
    'witness endpoint route'=>strpos($routes,"'waris_add_witnesses'")!==false,
    'capabilities endpoint route'=>strpos($routes,"'waris_witness_capabilities'")!==false,
    'existing attachments storage'=>strpos($module,'INSERT INTO aw_attachments')!==false,
    'existing history audit'=>strpos($module,'INSERT INTO aw_history')!==false,
    'no schema modifications'=>!preg_match('/\\b(?:CREATE|ALTER|DROP)\\s+TABLE\\b/i',$module),
    'no existing application updates'=>strpos($module,'UPDATE aw_applications')===false,
    'owner authorization'=>strpos($module,'account_id')!==false&&strpos($module,'hash_equals')!==false,
    'first witness code'=>strpos($review,"'saksi_1'=>'KTP Saksi Pertama'")!==false,
    'second witness code'=>strpos($review,"'saksi_2'=>'KTP Saksi Kedua'")!==false,
    'form photo fields'=>strpos($form,"'saksi_1':'KTP Saksi Pertama'")!==false&&strpos($form,"'saksi_2':'KTP Saksi Kedua'")!==false,
    'legacy case support'=>strpos($details,"section('Lengkapi Dua Orang Saksi')")!==false,
    'idempotent upload retry'=>strpos($module,'array_diff($codes,$previous)')!==false,
];
foreach($checks as $name=>$pass){
    echo ($pass?'OK':'FAIL').' '.$name.PHP_EOL;
    if(!$pass)exit(1);
}
echo 'All witness compatibility contracts passed.'.PHP_EOL;
