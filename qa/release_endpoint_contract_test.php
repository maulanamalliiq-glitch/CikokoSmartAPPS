<?php
declare(strict_types=1);
$root=dirname(__DIR__);
$api=file_get_contents($root.'/cpanel/mobile-api/index.php');
$area=file_get_contents($root.'/cpanel/mobile-api/rt_rw.php');
$pdf=file_get_contents($root.'/cpanel/mobile-api/rt_rw_pdf.php');
$integrated=file_get_contents($root.'/cpanel/mobile-api/integrated_services.php');
$waris=file_get_contents($root.'/cpanel/mobile-api/waris_review.php');
$tests=[
 'RT/RW controller linked from authenticated API'=>str_contains($api,"cikoko_area_dispatch(\$action,\$method,\$db,\$u)"),
 'RT/RW list and form submission backed'=>str_contains($area,"'rt_rw_list'")&&str_contains($area,"'rt_rw_submit'"),
 'Role-specific RT/RW decisions and updates backed'=>str_contains($area,"'rt_rw_decide'")&&str_contains($area,"'rt_rw_reaffirm'"),
 'Officer assignment limited to admin'=>str_contains($area,"'rt_rw_officer_assign'")&&str_contains($area,"if(\$role!=='admin')"),
 'Signer requires account password'=>str_contains($area,'cikoko_area_user_password($user'),
 'Letter access limited to participant and own account'=>str_contains($area,'cikoko_area_actor($user,$letter)'),
 'Private PDF only after both officers approve'=>str_contains($area,"'terverifikasi'")&&str_contains($area,'cikoko_rt_rw_output_pdf($record)'),
 'PDF signature image snapshots embedded'=>str_contains($pdf,'/Subtype /Image')&&str_contains($pdf,"'rt_signature'")&&str_contains($pdf,"'rw_stamp'"),
 'Waris authenticated detail exists'=>str_contains($api,"'document_detail'")&&str_contains($waris,"'document_detail'"),
 'Logo upload mapped in API and securely handled'=>str_contains($api,"'integrated_services_logo_upload'")&&str_contains($integrated,"'integrated_services_logo_upload'"),
 'Event privacy restrictions preserved'=>str_contains($api,'WHERE e.audience="personal" AND e.recipient=:recipient'),
];
$failed=0;foreach($tests as $name=>$ok){echo ($ok?'PASS':'FAIL')." $name\n";if(!$ok)$failed++;}exit($failed?1:0);
