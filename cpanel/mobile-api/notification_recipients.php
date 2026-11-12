<?php
declare(strict_types=1);

/**
 * Map trusted website events to one personal notification per active account.
 * Existing app inbox and FCM cron intentionally deliver personal events only.
 *
 * Public publishing broadcasts are limited to known non-sensitive categories.
 * Private letter/report/chat messages must NEVER become public broadcasts.
 */
function mobile_notification_recipients(string $category,string $audience,?string $recipient):array {
    if($audience==='personal'){
        $id=trim((string)$recipient);
        return $id===''?[]:[['audience'=>'personal','recipient'=>$id]];
    }

    // Preserve existing notification routing for reviewers and authorized staff.
    if($audience==='admin'){
        $ids=['admin'=>true];
        $capability=$category==='chat'?'chat:reply':
            (in_array($category,['surat','progres_surat'],true)?'waris:view':'reports:view');
        if(function_exists('mobile_can')){
            foreach(db_read('portal_users') as $account){
                if(!is_array($account)||empty($account['active'])||empty($account['id']))continue;
                $viewer=[
                    'user_id'=>(string)$account['id'],
                    'user_role'=>(string)($account['role']??'')
                ];
                if(mobile_can($viewer,$capability))$ids[(string)$account['id']]=true;
            }
        }
        return array_map(
            static fn($id)=>['audience'=>'personal','recipient'=>(string)$id],
            array_keys($ids)
        );
    }

    // Only the safe publication categories may be distributed publicly.
    $publicCategories=['berita','pengumuman','inovasi','info_aplikasi'];
    if(!in_array($audience,['public','warga','staff'],true)
       ||!in_array($category,$publicCategories,true)){
        return [['audience'=>$audience,'recipient'=>$recipient]];
    }

    $ids=[];
    // Public/admin-origin announcements may also reach the administrator device.
    if($audience==='public'||$audience==='staff')$ids['admin']=true;

    foreach(db_read('portal_users') as $account){
        if(!is_array($account)||empty($account['active'])||empty($account['id']))continue;
        $role=(string)($account['role']??'');
        if($role==='')continue;
        if($audience==='warga'&&$role!=='warga')continue;
        if($audience==='staff'&&$role==='warga')continue;
        $ids[(string)$account['id']]=true;
    }

    // Avoid unbounded writes to a small cPanel database from a single request.
    // Fail visibly for the manual administrator form; automatic writers log it.
    if(count($ids)>5000)throw new RuntimeException(
        'Penerima notifikasi melebihi batas 5000 akun. Kirim per kelompok.'
    );

    return array_map(
        static fn($id)=>['audience'=>'personal','recipient'=>(string)$id],
        array_keys($ids)
    );
}
