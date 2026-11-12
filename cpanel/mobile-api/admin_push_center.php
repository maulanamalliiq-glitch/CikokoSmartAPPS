<?php
declare(strict_types=1);

/**
 * Admin-only notification API. Auth is always supplied by mobile_auth()
 * in index.php. Never permit arbitrary broadcast from public requests.
 */
function cikoko_push_health_schema(PDO $db):void {
    $db->exec('CREATE TABLE IF NOT EXISTS mobile_push_dispatch_health (
        id TINYINT UNSIGNED NOT NULL PRIMARY KEY,
        last_run_at DATETIME NULL,
        status VARCHAR(32) NOT NULL DEFAULT "not_run",
        processed INT UNSIGNED NOT NULL DEFAULT 0,
        fcm_accepted INT UNSIGNED NOT NULL DEFAULT 0,
        failed INT UNSIGNED NOT NULL DEFAULT 0,
        no_device INT UNSIGNED NOT NULL DEFAULT 0,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
}
function cikoko_push_health_mark(PDO $db,string $status,int $processed=0,int $accepted=0,int $failed=0,int $noDevice=0):void {
    cikoko_push_health_schema($db);
    $q=$db->prepare('INSERT INTO mobile_push_dispatch_health
        (id,last_run_at,status,processed,fcm_accepted,failed,no_device)
        VALUES(1,NOW(),?,?,?,?,?)
        ON DUPLICATE KEY UPDATE last_run_at=NOW(),status=VALUES(status),
        processed=VALUES(processed),fcm_accepted=VALUES(fcm_accepted),
        failed=VALUES(failed),no_device=VALUES(no_device)');
    $q->execute([$status,max(0,$processed),max(0,$accepted),max(0,$failed),max(0,$noDevice)]);
}
function cikoko_admin_push_route(string $action,string $method,PDO $db,array $user):void{
    mobile_admin($user);
    if($action==='admin_push_diagnostics'){
        if($method!=='GET')mobile_error('Metode tidak diizinkan',405);
        cikoko_push_health_schema($db);
        $devices=(int)$db->query('SELECT COUNT(*) FROM mobile_devices WHERE fcm_token<>""')->fetchColumn();
        $accounts=(int)$db->query('SELECT COUNT(DISTINCT user_id) FROM mobile_devices WHERE fcm_token<>""')->fetchColumn();
        $pending=(int)$db->query('SELECT COUNT(*) FROM mobile_events
           WHERE audience="personal" AND dispatched_at IS NULL')->fetchColumn();
        $last=$db->query('SELECT last_run_at,status,processed,fcm_accepted,failed,no_device
            FROM mobile_push_dispatch_health WHERE id=1')->fetch(PDO::FETCH_ASSOC);
        $recent=0;
        $recentTime=null;
        if($last){
            $recentTime=(string)$last['last_run_at'];
            $stamp=strtotime($recentTime);
            $recent=$stamp!==false?time()-$stamp:0;
        }
        $cronActive=$last&&$recent>=0&&$recent<=300;
        // FCM acceptance is recorded only after a successful Google API response.
        mobile_json(['ok'=>true,'devices'=>$devices,'device_accounts'=>$accounts,
           'pending_events'=>$pending,'cron_active'=>(bool)$cronActive,
           'last_run_at'=>$recentTime,
           'status'=>(string)($last['status']??'not_run'),
           'last_processed'=>(int)($last['processed']??0),
           'last_fcm_accepted'=>(int)($last['fcm_accepted']??0),
           'last_failed'=>(int)($last['failed']??0),
           'last_no_device'=>(int)($last['no_device']??0),
           'hint'=>$devices===0
              ?'Belum ada token perangkat. Masuk ke aplikasi, beri izin notifikasi, lalu ulangi.'
              :(!$cronActive
                 ?'Cron pengiriman tidak terdeteksi aktif dalam 5 menit terakhir.'
                 :(((string)($last['status']??''))==='fcm_key_missing'
                    ?'Berkas layanan Firebase di server belum ditemukan.'
                    :'Lihat status percobaan pengiriman di bawah.'))]);
    }

    if($action==='admin_push_accounts'){
        if($method!=='GET')mobile_error('Metode tidak diizinkan',405);
        $all=[['id'=>'admin','name'=>'Administrator Utama','role'=>'admin']];
        foreach(db_read('portal_users') as $account){
            if(!is_array($account)||empty($account['active'])||empty($account['id']))continue;
            $all[]=['id'=>(string)$account['id'],
              'name'=>mobile_text($account['name']??$account['username']??'Akun',120),
              'role'=>(string)($account['role']??'')];
        }
        mobile_json(['ok'=>true,'items'=>$all]);
    }

    if($action!=='admin_push_send')mobile_error('Menu tidak tersedia',404);
    if($method!=='POST')mobile_error('Metode tidak diizinkan',405);

    $body=mobile_body();
    $scope=(string)($body['scope']??'');
    $category=(string)($body['category']??'info_aplikasi');
    $recipient=(string)($body['recipient']??'');
    $title=trim((string)($body['title']??''));
    $message=trim((string)($body['message']??''));
    $requestId=trim((string)($body['request_id']??''));
    $confirmed=($body['confirmed']??false)===true;
    if(!in_array($scope,['public','warga','staff','personal'],true)||
       !in_array($category,['info_aplikasi','berita','pengumuman','inovasi'],true))
       mobile_error('Kategori atau kelompok penerima tidak sesuai',422);
    if(!$confirmed)mobile_error('Konfirmasikan pengiriman dahulu',422);
    if(strlen($title)<5||strlen($title)>180||strlen($message)<10||strlen($message)>900)
       mobile_error('Judul 5–180 karakter dan isi 10–900 karakter',422);
    if(!preg_match('/^[a-f0-9]{24,48}$/D',$requestId))
       mobile_error('Kode permintaan tidak valid',422);

    // Never use freeform IDs for a private message; resolve against active accounts.
    if($scope==='personal'){
        $found=$recipient==='admin';
        foreach(db_read('portal_users') as $account){
            if(($account['active']??false)&&
               (string)($account['id']??'')===$recipient)$found=true;
        }
        if(!$found)mobile_error('Akun penerima tidak ditemukan atau tidak aktif',422);
    }

    $db->exec('CREATE TABLE IF NOT EXISTS mobile_admin_push_audit (
       request_id VARCHAR(48) NOT NULL PRIMARY KEY,
       sender VARCHAR(80) NOT NULL,
       category VARCHAR(40) NOT NULL,
       scope VARCHAR(16) NOT NULL,
       recipient_count INT UNSIGNED NOT NULL,
       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
       INDEX idx_sender_time(sender,created_at)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
    $sender=(string)$user['user_id'];
    $check=$db->prepare('SELECT recipient_count FROM mobile_admin_push_audit
        WHERE request_id=? AND sender=? LIMIT 1');
    $check->execute([$requestId,$sender]);
    $already=$check->fetchColumn();
    if($already!==false)mobile_json(['ok'=>true,
       'already_sent'=>true,'recipient_count'=>(int)$already,
       'message'=>'Permintaan ini sudah tersimpan, tidak dikirim dua kali.']);

    cikoko_rate_limit($db,'admin_push',$sender,10,3600);
    $targets=mobile_notification_recipients(
       $category,$scope,$scope==='personal'?$recipient:null);
    $targets=array_values(array_filter($targets,static function($row){
        return ($row['audience']??'')==='personal'&&
            trim((string)($row['recipient']??''))!=='';
    }));
    if(!$targets)mobile_error('Tidak ada akun aktif dalam kelompok penerima',422);
    if(count($targets)>5000)mobile_error('Penerima melebihi batas 5000 akun',422);

    try{
        $db->beginTransaction();
        $audit=$db->prepare('INSERT INTO mobile_admin_push_audit
           (request_id,sender,category,scope,recipient_count) VALUES(?,?,?,?,?)');
        $audit->execute([$requestId,$sender,$category,$scope,count($targets)]);
        $insert=$db->prepare('INSERT INTO mobile_events
           (category,title,message,audience,recipient) VALUES(?,?,?,"personal",?)');
        foreach($targets as $target){
            $insert->execute([$category,$title,$message,(string)$target['recipient']]);
        }
        $db->commit();
        mobile_json(['ok'=>true,'already_sent'=>false,
          'recipient_count'=>count($targets),
          'message'=>'Notifikasi masuk antrean akun penerima. Push ke layar HP memerlukan Firebase dan Cron aktif.']);
    }catch(Throwable $e){
        if($db->inTransaction())$db->rollBack();
        error_log('[Cikoko admin push] '.$e->getMessage());
        mobile_error('Notifikasi gagal tersimpan. Periksa log server.',503);
    }
}
