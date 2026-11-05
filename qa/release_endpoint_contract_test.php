<?php
declare(strict_types=1);
$root=dirname(__DIR__);
$api=file_get_contents($root.'/cpanel/mobile-api/index.php');
$area=file_get_contents($root.'/cpanel/mobile-api/rt_rw.php');
$pdf=file_get_contents($root.'/cpanel/mobile-api/rt_rw_pdf.php');
$integrated=file_get_contents($root.'/cpanel/mobile-api/integrated_services.php');
$waris=file_get_contents($root.'/cpanel/mobile-api/waris_review.php');
$civic=file_get_contents($root.'/cpanel/mobile-api/civic_api.php');
$civicPdf=file_get_contents($root.'/cpanel/mobile-api/civic_pdf.php');
$warisStage=file_get_contents($root.'/cpanel/mobile-api/waris_stage.php');
$roles=file_get_contents($root.'/cpanel/roles-lib.php');
$permission=file_get_contents($root.'/cpanel/mobile-api/permissions.php');
$tests=[
 'All LPJ civic_* routes mapped behind authenticated controller'=>
  str_contains($api,"str_starts_with(\$action,'civic_')")&&
  str_contains($api,'cikoko_civic_dispatch($action,$method,$db,$u)'),
 'LPJ catalog, list, submit, detail, status and PDF handlers available'=>
  count(array_filter(['civic_catalog','civic_list','civic_submit','civic_detail','civic_pin_set','civic_review','civic_pdf'],
    static fn($a)=>str_contains($civic,"'".$a."'"))===7,
 'LPJ finances validated on PHP server'=>
  str_contains($civic,'cikoko_civic_money(')&&
  str_contains($civic,'$total>$opening+$income'),
 'LPJ owner and area-based authorization enforced'=>
  str_contains($civic,'cikoko_civic_can_read($user,$row,$scope)')&&
  str_contains($civic,'$scope[\'rw\']'),
 'LPJ PIN hash, password verification, and lockout'=>
  str_contains($civic,'password_hash($pin,PASSWORD_DEFAULT)')&&
  str_contains($civic,'password_verify($pin,')&&
  str_contains($civic,'INTERVAL 15 MINUTE'),
 'LPJ PDF renderer linked with status and approval history'=>
  str_contains($civic,'cikoko_civic_output_pdf(')&&
  str_contains($civicPdf,'/Type /Pages')&&
  str_contains($civicPdf,'RIWAYAT PERSETUJUAN INTERNAL'),
 'LPJ Bendahara roles recognized in portal and mobile APIs'=>
  str_contains($roles,'"bendahara_rt"')&&
  str_contains($permission,"'bendahara_rt'")&&
  str_contains($permission,"'bendahara_rw'"),
 'Waris format capability + authenticated staging wired to API'=>
  str_contains($api,"'waris_format','waris_stage'")&&
  str_contains($warisStage,"'upload_format'=>'split_v1'"),
 'Waris photos staged in private, access denied directory'=>
  str_contains($warisStage,"__DIR__.'/private/waris-stage'")&&
  is_file($root.'/cpanel/mobile-api/private/.htaccess'),
 'Waris draft restricted by current account, key and photo type'=>
  str_contains($warisStage,'$uid,$draft,$code')&&
  str_contains($warisStage,'cikoko_waris_code_valid')&&
  str_contains($warisStage,'$uid,$draft'),
 'Waris finalization requires separate KTP, KK and Akta photos'=>
  str_contains($warisStage,"'r4_ktp','r4_kk','r4_akta'")&&
  str_contains($warisStage,'cikoko_waris_finalize('),
 'Waris witnesses remain separate and supported'=>
  str_contains($api,"'waris_witness_capabilities','waris_add_witnesses'"),
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
