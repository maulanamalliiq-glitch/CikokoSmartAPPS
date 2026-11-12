<?php
declare(strict_types=1);
function db_read(string $table):array {
    return $table==='portal_users' ? [
        ['id'=>'citizen1','name'=>'Warga A','role'=>'warga','active'=>true],
        ['id'=>'citizen2','name'=>'Warga B','role'=>'warga','active'=>false],
        ['id'=>'staff1','name'=>'Petugas A','role'=>'pegawai','active'=>true],
        ['id'=>'rt1','name'=>'RT A','role'=>'ketua_rt','active'=>true]
    ] : [];
}
function mobile_can(array $u,string $cap):bool {
    return $u['user_id']==='staff1' && $cap==='chat:reply';
}
require __DIR__.'/../cpanel/mobile-api/notification_recipients.php';
function ids(array $targets):array{
    return array_map(static fn($v)=>$v['recipient']??'',$targets);
}
function check(bool $passed,string $label):void {
    if(!$passed){fwrite(STDERR,"FAIL: $label\n");exit(1);}
    echo "PASS: $label\n";
}
$public=ids(mobile_notification_recipients('berita','public',null));
check(count($public)===4 && in_array('admin',$public,true)
    && in_array('citizen1',$public,true)
    && in_array('rt1',$public,true)
    && !in_array('citizen2',$public,true),
    'Only active accounts receive website news');
$citizen=ids(mobile_notification_recipients('info_aplikasi','warga',null));
check($citizen===['citizen1'],'Warga broadcast excludes admin and staff');
$staff=ids(mobile_notification_recipients('info_aplikasi','staff',null));
check(count($staff)===3 && in_array('admin',$staff,true)
    && !in_array('citizen1',$staff,true),'Staff broadcast excludes warga');
$private=mobile_notification_recipients('surat','personal','citizen1');
check(count($private)===1 && $private[0]['recipient']==='citizen1',
    'Personal letter notification stays private');
$unsafe=mobile_notification_recipients('surat','public',null);
check(count($unsafe)===1 && $unsafe[0]['audience']==='public',
    'Sensitive category cannot broadcast to every account');
$reviewers=ids(mobile_notification_recipients('chat','admin',null));
check(count($reviewers)===2 && in_array('admin',$reviewers,true)
    && in_array('staff1',$reviewers,true),
    'Existing reviewer routing preserved');
echo "Notification routing tests passed.\n";
