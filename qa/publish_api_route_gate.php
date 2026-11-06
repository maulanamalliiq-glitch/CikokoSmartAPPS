<?php
declare(strict_types=1);

/**
 * Release gate for Flutter actions required by user-facing screens.
 * This is deliberately strict: missing routes block a production release.
 * It does not replace a staging test with authenticated test accounts.
 */
$dir=dirname(__DIR__).'/cpanel/mobile-api';
$source='';
foreach (glob($dir.'/*.php') ?: [] as $file) {
    $source .= "\n".file_get_contents($file);
}
$required=[
    'login','me','events','event_read','device_unregister',
    'v211_profile','v211_profile_update',
    'integrated_services','integrated_services_save','integrated_services_logo_upload',
    'document_detail','waris_request_correction',
    'rt_rw_list','rt_rw_submit','rt_rw_decide',
    'rt_rw_reaffirm','rt_rw_officers','rt_rw_officer_assign',
    'rt_rw_signer_status','rt_rw_signer_upload','rt_rw_pdf',
    'civic_catalog','civic_list','civic_submit','civic_detail',
    'civic_pin_set','civic_review','civic_pdf',
    'waris_format','waris_stage',
];
$failed=[];
foreach($required as $action) {
    $present=(bool)preg_match('/[\x27\x22]'.preg_quote($action,'/').'[\x27\x22]/',$source);
    echo ($present?'PASS':'BLOCK')." API action {$action}\n";
    if(!$present)$failed[]=$action;
}
if($failed){
    fwrite(STDERR,"PUBLISH BLOCKED: missing server actions: ".implode(', ',$failed)."\n");
    exit(1);
}
echo "Static API action presence PASS. Still requires staging/auth/permission tests.\n";
