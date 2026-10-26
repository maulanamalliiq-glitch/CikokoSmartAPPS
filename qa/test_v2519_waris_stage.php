<?php
declare(strict_types=1);
$api=file_get_contents(dirname(__DIR__).'/cpanel/mobile-api/index.php');
$stage=file_get_contents(dirname(__DIR__).'/cpanel/mobile-api/waris_stage.php');
$dart=file_get_contents(dirname(__DIR__).'/flutter/lib/main.dart');
function check_v2519(bool $pass,string $detail):void {
 if(!$pass)throw new RuntimeException("FAIL: ".$detail);
 echo "OK: ".$detail."\n";
}
check_v2519(str_contains($api,"'staged_uploads'=>true"),"Server advertises staged feature");
check_v2519(str_contains($api,"if(\$action==='waris_stage'"),"Staged endpoint");
check_v2519(str_contains($api,"DELETE FROM mobile_waris_staging WHERE user_id=? AND draft_key=?"),"Finalize cleanup scoped to owner");
check_v2519(str_contains($stage,"if(count(\$_FILES)<1||count(\$_FILES)>8)"),"Server caps a request to 8 photos");
check_v2519(str_contains($stage,"'user_id'") || str_contains($stage,"user_id VARCHAR(80)"),"Account-scoped database rows");
check_v2519(str_contains($stage,"is_uploaded_file"),"Upload is verified by PHP");
check_v2519(str_contains($stage,"DATE_SUB(NOW(), INTERVAL 1 DAY)"),"Stale drafts have expiry");
check_v2519(str_contains($stage,"mobile_json(['ok'=>true,'saved'"),"Stage acknowledges saved photos");
check_v2519(str_contains($dart,"const batchSize=8"),"App sends batches of 8");
check_v2519(str_contains($dart,"draftKey"),"App reuses key for staged upload and finalize");
check_v2519(str_contains($dart,"response=await api.upload('waris',data,{},progress:"),"Finalization submits no photo files");
echo "V2519 staged upload checks passed.\n";
