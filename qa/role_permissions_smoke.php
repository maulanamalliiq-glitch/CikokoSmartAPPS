<?php
// Smoke test ini tidak mengakses data warga maupun MySQL.
require __DIR__.'/../cpanel/mobile-api/permissions.php';
$roles=mobile_role_names();
$required=['admin','admin_kelurahan','lurah','asn','pppk','pjlp','ptsp','dukcapil','rt','rw','fkdm','lmk','jumantik_rt','jumantik_rw','dasawisma','posyandu','ppsu','warga'];
foreach($required as $role)if(!isset($roles[$role]))throw new RuntimeException('Role tidak ada: '.$role);
if(!in_array('waris:create',mobile_default_permissions('warga'),true))throw new RuntimeException('Warga harus bisa mengajukan Ahli Waris');
if(in_array('reports:verify',mobile_default_permissions('warga'),true))throw new RuntimeException('Warga tidak boleh verifikasi');
if(in_array('role:manage',mobile_default_permissions('admin_kelurahan'),true))throw new RuntimeException('Admin Kelurahan tidak boleh kelola role');
if(!in_array('content:create',mobile_default_permissions('admin_kelurahan'),true))throw new RuntimeException('Admin Kelurahan harus bisa input konten');
if(!in_array('role:manage',mobile_default_permissions('admin'),true))throw new RuntimeException('Admin Utama harus bisa atur hak akses');
echo "ROLE PERMISSION SMOKE TEST: PASS (".count($roles)." codes)\n";
