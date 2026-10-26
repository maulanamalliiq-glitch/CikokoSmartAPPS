<?php
declare(strict_types=1);
require __DIR__.'/../cpanel/mobile-api/surat_identity_v2525.php';
function ck(bool $value,string $label):void{
 if(!$value){fwrite(STDERR,'FAIL '.$label."\n");exit(1);}
 echo 'OK '.$label."\n";
}
$aw=cikoko_v2525_identity_row(['id'=>'19','reference'=>'AW-20261026-E4C39D56'],'waris');
ck($aw['id']===19 && $aw['application_id']===19 && $aw['request_id']===19,'canonical AW numeric id');
ck($aw['document_key']==='waris:AW-20261026-E4C39D56','AW document key');
$report=cikoko_v2525_identity_row(['id'=>'5','title'=>'jumantik'],'report');
ck($report['id']===5 && $report['document_key']==='report:5','report numeric id');
$missing=cikoko_v2525_identity_row(['id'=>null],'report');
ck($missing['id_valid']===false && $missing['id']===0,'missing report key must not be guessed');
ck(cikoko_v2525_reference_from_input(['title'=>'AW-20261027-6EAD7D63'])==='AW-20261027-6EAD7D63','AW legacy title');
ck(cikoko_v2525_reference_from_input(['document_key'=>'waris:AW-20261026-E4C39D56'])==='AW-20261026-E4C39D56','AW document key lookup');
ck(cikoko_v2525_reference_from_input(['title'=>'jumantik'])==='','report not misclassified as AW');
echo "V2525 ID contract passed.\n";
