<?php
declare(strict_types=1);
require __DIR__.'/bootstrap.php';
$action=(string)($_GET['action']??'');
$method=(string)($_SERVER['REQUEST_METHOD']??'GET');
if(!in_array($action,['admin_push_diagnostics','admin_push_accounts','admin_push_send'],true)){
    mobile_error('Menu tidak tersedia',404);
}
$viewer=mobile_auth();
mobile_admin($viewer);
require_once __DIR__.'/admin_push_center.php';
cikoko_admin_push_route($action,$method,mobile_db(),$viewer);
