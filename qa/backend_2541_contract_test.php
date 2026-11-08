<?php
declare(strict_types=1);
$dir=dirname(__DIR__).'/cpanel/mobile-api/';
$files=['index.php','bootstrap.php','release_core.php','account_support.php','governance_review.php','waris_review.php'];
foreach($files as $file){if(!is_file($dir.$file))throw new RuntimeException('Missing required backend 2541 module '.$file);}
$index=file_get_contents($dir.'index.php');
$bootstrap=file_get_contents($dir.'bootstrap.php');
$routes=['account_help','account_request','account_requests','account_request_resolve','chat_send','chat_threads','chat_reply','rt_rw_list','rt_rw_submit','rt_rw_decide','civic_catalog','civic_submit','civic_review','waris_stage','waris_format','document_detail','territory_monitoring','officer_reports','officer_waris'];
foreach($routes as $route)if(!str_contains($index,"'".$route."'"))throw new RuntimeException('Missing route '.$route);
if(!str_contains($index,"'version'=>'2546.rc1'"))throw new RuntimeException('Public health version mismatch');
foreach(['cikoko_release_schema','mobile_event_deletes','cikoko_capture_area','release_core.php'] as $function)if(!str_contains($bootstrap,$function))throw new RuntimeException('Missing bootstrap integration '.$function);
if(!str_contains(file_get_contents($dir.'governance_review.php'),'cikoko_area_snapshots'))throw new RuntimeException('Territory monitoring missing immutable submission areas');
if(!str_contains(file_get_contents($dir.'waris_review.php'),'cikoko_waris_review_application_id'))throw new RuntimeException('Legacy waris reference resolution missing');
echo "PASS: 2541 modules, old service routes, account help, privacy, territory and reference contracts\n";
