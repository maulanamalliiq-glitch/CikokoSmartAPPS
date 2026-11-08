<?php
require __DIR__.'/../cpanel/mobile-api/permissions.php';
foreach(['reports:view','reports:verify','waris:view','waris:verify','monitoring:view'] as $key){
 if(!in_array($key,mobile_default_permissions('asn'),true)||!in_array($key,mobile_default_permissions('admin'),true))throw new RuntimeException('Missing permission '.$key);
}
if(in_array('role:manage',mobile_default_permissions('asn'),true))throw new RuntimeException('ASN must not manage accounts or grants');
foreach(['reports:verify','waris:verify','monitoring:view'] as $key)if(in_array($key,mobile_default_permissions('warga'),true))throw new RuntimeException('Citizen privilege escalation');
echo "PASS ASN/admin defaults, protected administration, resident boundary\n";
