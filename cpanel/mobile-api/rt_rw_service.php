<?php
declare(strict_types=1);

/**
 * Authenticated RT/RW letter workflow. The caller has already authenticated.
 * This module never accepts client-supplied owner, RT/RW or reviewer identity.
 */
function cikoko_area($value, bool $optional=false):string {
    $v=trim((string)$value);
    if($optional&&$v==='')return '';
    if(!preg_match('/^[0-9]{1,2}$/D',$v)||(int)$v<1||(int)$v>99)
        mobile_error('RT/RW harus angka antara 01 dan 99.',422);
    return str_pad((string)(int)$v,2,'0',STR_PAD_LEFT);
}
function cikoko_optional_area($value):string {
    $raw=trim((string)$value);
    if(!preg_match('/^[0-9]{1,2}$/D',$raw)||(int)$raw<1||(int)$raw>99)return '';
    return str_pad((string)(int)$raw,2,'0',STR_PAD_LEFT);
}
function cikoko_rt_user(string $id):?array {
    foreach(db_read('portal_users') as $row){
        if((string)($row['id']??'')===$id && ($row['active']??false))return $row;
    }
    return null;
}
function cikoko_rt_password(array $row,string $provided):void {
    if($provided===''||!password_verify($provided,(string)($row['password_hash']??''))){
        mobile_error('Konfirmasi password akun tidak sesuai.',403);
    }
}
function cikoko_rt_schema(PDO $db):void {
    static $done=false;
    if($done)return;
    try {
        $db->exec('CREATE TABLE IF NOT EXISTS mobile_rt_rw_letters (
          id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
          user_id VARCHAR(80) NOT NULL,
          applicant_name VARCHAR(180) NOT NULL,
          rt CHAR(2) NOT NULL, rw CHAR(2) NOT NULL,
          subject VARCHAR(240) NOT NULL,
          notes TEXT NOT NULL,
          form_json LONGTEXT NOT NULL,
          status VARCHAR(30) NOT NULL DEFAULT "menunggu_rt",
          rt_approved_by VARCHAR(80) NULL, rw_approved_by VARCHAR(80) NULL,
          rt_approved_at DATETIME NULL, rw_approved_at DATETIME NULL,
          rt_note TEXT NULL, rw_note TEXT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          INDEX idx_owner(user_id,id), INDEX idx_area(rt,rw,status),
          INDEX idx_rw(rw,status)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
        $db->exec('CREATE TABLE IF NOT EXISTS mobile_rt_rw_signers (
          user_id VARCHAR(80) PRIMARY KEY,
          signature_name VARCHAR(90) NOT NULL,
          stamp_name VARCHAR(90) NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
    }catch(Throwable $e){
        error_log('RT/RW schema error '.$e->getMessage());
        mobile_error('Penyimpanan surat RT/RW belum tersedia. Hubungi administrator.',503);
    }
    $done=true;
}
function cikoko_rt_can_view(array $letter,array $user,string $uid,?array $account):bool {
    $role=(string)($user['user_role']??'');
    if($role==='admin'||$role==='admin_kelurahan')return true;
    if($role==='warga')return (string)$letter['user_id']===$uid;
    if(!$account)return false;
    $rw=cikoko_optional_area($account['rw']??'');
    if($rw===''||$rw!==$letter['rw'])return false;
    if($role==='rw')return true;
    return $role==='rt' && cikoko_optional_area($account['rt']??'')===$letter['rt'];
}
function cikoko_rt_row(array $item):array {
    $item['id']=(int)$item['id'];
    $item['form']=json_decode((string)$item['form_json'],true)?:[];
    $item['requires_reaffirm']=false;
    unset($item['form_json']);
    return $item;
}
function cikoko_rt_notify_officers(string $role,string $rt,string $rw,string $title,string $message):void {
    foreach(db_read('portal_users') as $user){
        if(!($user['active']??false)||($user['role']??'')!==$role)continue;
        try {
            $candidateRw=cikoko_optional_area($user['rw']??'');
            $candidateRt=cikoko_optional_area($user['rt']??'');
        }catch(Throwable $e){continue;}
        if($candidateRw===$rw && ($role==='rw'||$candidateRt===$rt))
            mobile_emit('surat',$title,$message,'personal',(string)$user['id']);
    }
}
function cikoko_rt_dispatch(string $action,string $method,PDO $db,array $auth,string $uid):void {
    $role=(string)($auth['user_role']??'');
    $account=cikoko_rt_user($uid);
    cikoko_rt_schema($db);
    if($action==='rt_rw_signer_status'){
        if(!in_array($role,['rt','rw'],true))mobile_error('Akses khusus Ketua RT/RW.',403);
        $q=$db->prepare('SELECT signature_name,stamp_name FROM mobile_rt_rw_signers WHERE user_id=?');
        $q->execute([$uid]);$row=$q->fetch(PDO::FETCH_ASSOC);
        $ready=$row && is_file(__DIR__.'/private/'.basename((string)$row['signature_name']))
           && is_file(__DIR__.'/private/'.basename((string)$row['stamp_name']));
        mobile_json(['ok'=>true,'ready'=>(bool)$ready]);
    }
    if($action==='rt_rw_signer_upload'){
        if($method!=='POST'||!in_array($role,['rt','rw'],true))mobile_error('Akses tidak diizinkan.',403);
        if(!$account)mobile_error('Akun petugas tidak ditemukan.',403);
        cikoko_rt_password($account,(string)($_POST['password']??''));
        $signature=mobile_file('signature',true);
        $stamp=mobile_file('stamp',true);
        try{
            $q=$db->prepare('SELECT signature_name,stamp_name FROM mobile_rt_rw_signers WHERE user_id=?');
            $q->execute([$uid]);$previous=$q->fetch(PDO::FETCH_ASSOC);
            $st=$db->prepare('INSERT INTO mobile_rt_rw_signers(user_id,signature_name,stamp_name)
              VALUES(?,?,?) ON DUPLICATE KEY UPDATE signature_name=VALUES(signature_name),
              stamp_name=VALUES(stamp_name)');
            $st->execute([$uid,$signature,$stamp]);
            if($previous)foreach(['signature_name','stamp_name'] as $field){
                $old=(string)($previous[$field]??'');
                if($old!==''&&basename($old)===$old)@unlink(__DIR__.'/private/'.$old);
            }
            mobile_json(['ok'=>true,'ready'=>true]);
        }catch(Throwable $e){
            @unlink(__DIR__.'/private/'.$signature);@unlink(__DIR__.'/private/'.$stamp);
            error_log('RT/RW signer save error '.$e->getMessage());
            mobile_error('Penyimpanan TTD/stempel gagal.',503);
        }
    }
    if($action==='rt_rw_officers'){
        if($role!=='admin')mobile_error('Hanya Admin Utama dapat mengelola wilayah petugas.',403);
        $items=[];
        foreach(db_read('portal_users') as $row)if(in_array($row['role']??'',['rt','rw'],true)){
            $items[]=['id'=>(string)$row['id'],'name'=>(string)($row['name']??''),
              'role'=>(string)$row['role'],'rt'=>(string)($row['rt']??''),
              'rw'=>(string)($row['rw']??''),'active'=>($row['active']??false)===true];
        }
        mobile_json(['ok'=>true,'items'=>$items]);
    }
    if($action==='rt_rw_officer_assign'){
        if($method!=='POST'||$role!=='admin')mobile_error('Hanya Admin Utama dapat mengatur wilayah.',403);
        $data=mobile_body();
        $officer=mobile_text($data['officer_id']??'',80);
        $users=db_read('portal_users');$found=false;
        foreach($users as &$row){
            if((string)($row['id']??'')!==$officer)continue;
            if(!in_array($row['role']??'',['rt','rw'],true))mobile_error('Akun harus berperan RT atau RW.',422);
            $row['rw']=cikoko_area($data['rw']??'');
            $row['rt']=($row['role']==='rt')?cikoko_area($data['rt']??''):'';
            $found=true;break;
        }
        unset($row);
        if(!$found)mobile_error('Petugas tidak ditemukan.',404);
        if(!db_write('portal_users',$users))mobile_error('Wilayah petugas gagal disimpan.',503);
        mobile_json(['ok'=>true,'message'=>'Wilayah petugas berhasil diperbarui.']);
    }
    if($action==='rt_rw_submit'){
        if($method!=='POST'||$role!=='warga'||!$account)mobile_error('Pengajuan hanya untuk akun warga aktif.',403);
        $rt=cikoko_area($account['rt']??'');$rw=cikoko_area($account['rw']??'');
        $input=mobile_body();$form=$input['form']??null;
        if(!is_array($form))mobile_error('Formulir tidak valid.',422);
        $keys=['nama','tempat_lahir','tanggal_lahir','no_ktp_kk','agama',
          'kewarganegaraan','pendidikan','jenis_kelamin','status','pekerjaan','alamat','maksud_keperluan'];
        $saved=[];
        foreach($keys as $key){
            $raw=$form[$key]??'';
            if(!is_string($raw))mobile_error('Isian surat tidak valid.',422);
            $value=mobile_text($raw,$key==='alamat'||$key==='maksud_keperluan'?900:180);
            if($value==='')mobile_error('Lengkapi semua isian surat.',422);
            $saved[$key]=$value;
        }
        if(!preg_match('/^\d{4}-\d{2}-\d{2}$/D',$saved['tanggal_lahir']))
            mobile_error('Format tanggal lahir harus YYYY-MM-DD.',422);
        $subject='Surat Pengantar RT/RW';
        $q=$db->prepare('INSERT INTO mobile_rt_rw_letters
          (user_id,applicant_name,rt,rw,subject,notes,form_json,status)
          VALUES(?,?,?,?,?,?,?,"menunggu_rt")');
        $q->execute([$uid,$saved['nama'],$rt,$rw,$subject,$saved['maksud_keperluan'],
          json_encode($saved,JSON_UNESCAPED_UNICODE|JSON_THROW_ON_ERROR)]);
        $id=(int)$db->lastInsertId();
        mobile_emit('surat','Pengajuan surat diterima','Surat pengantar Anda menunggu verifikasi Ketua RT.','personal',$uid);
        cikoko_rt_notify_officers('rt',$rt,$rw,'Pengajuan surat RT/RW','Surat pengantar baru menunggu pemeriksaan RT.');
        mobile_json(['ok'=>true,'id'=>$id,'status'=>'menunggu_rt']);
    }
    if($action==='rt_rw_list'){
        if($method!=='GET')mobile_error('Metode tidak diperbolehkan.',405);
        if($role==='warga'){
            $q=$db->prepare('SELECT * FROM mobile_rt_rw_letters WHERE user_id=? ORDER BY id DESC LIMIT 80');
            $q->execute([$uid]);
        }elseif($role==='rt'||$role==='rw'){
            if(!$account)mobile_error('Akun petugas tidak ditemukan.',403);
            $rw=cikoko_optional_area($account['rw']??'');
            $rt=cikoko_optional_area($account['rt']??'');
            if($rw==='')mobile_json(['ok'=>true,'items'=>[]]);
            if($role==='rt'){
                if($rt==='')mobile_json(['ok'=>true,'items'=>[]]);
                $q=$db->prepare('SELECT * FROM mobile_rt_rw_letters WHERE rt=? AND rw=? ORDER BY id DESC LIMIT 100');
                $q->execute([$rt,$rw]);
            }else{
                $q=$db->prepare('SELECT * FROM mobile_rt_rw_letters WHERE rw=? ORDER BY id DESC LIMIT 100');
                $q->execute([$rw]);
            }
        }elseif(in_array($role,['admin','admin_kelurahan'],true)){
            $q=$db->query('SELECT * FROM mobile_rt_rw_letters ORDER BY id DESC LIMIT 100');
        }else{
            mobile_error('Tidak berhak melihat surat RT/RW.',403);
        }
        $items=[];
        foreach($q->fetchAll(PDO::FETCH_ASSOC) as $item)
            if(cikoko_rt_can_view($item,$auth,$uid,$account))$items[]=cikoko_rt_row($item);
        mobile_json(['ok'=>true,'items'=>$items]);
    }
    if($action==='rt_rw_decide'||$action==='rt_rw_reaffirm'){
        if($method!=='POST'||!in_array($role,['rt','rw'],true)||!$account)
            mobile_error('Hanya Ketua RT/RW berwenang memverifikasi.',403);
        $data=mobile_body();$id=(int)($data['id']??0);
        if($id<1)mobile_error('Nomor surat tidak valid.',422);
        cikoko_rt_password($account,(string)($data['current_password']??''));
        $q=$db->prepare('SELECT * FROM mobile_rt_rw_letters WHERE id=?');
        $q->execute([$id]);$letter=$q->fetch(PDO::FETCH_ASSOC);
        if(!$letter||!cikoko_rt_can_view($letter,$auth,$uid,$account))
            mobile_error('Surat tidak tersedia untuk wilayah akun.',404);
        $expected=$role==='rt'?'menunggu_rt':'menunggu_rw';
        if($action==='rt_rw_reaffirm'){
            mobile_error('Surat lama tidak memerlukan penegasan ulang pada alur baru.',409);
        }
        if($letter['status']!==$expected)mobile_error('Tahap surat telah berubah. Muat ulang daftar.',409);
        $decision=(string)($data['decision']??'');
        if(!in_array($decision,['approve','reject'],true))mobile_error('Keputusan tidak valid.',422);
        $note=mobile_text($data['note']??'',1000);
        if($decision==='reject'&&$note==='')mobile_error('Alasan penolakan wajib diisi.',422);
        $q=$db->prepare('SELECT signature_name,stamp_name FROM mobile_rt_rw_signers WHERE user_id=?');
        $q->execute([$uid]);$signer=$q->fetch(PDO::FETCH_ASSOC);
        if($decision==='approve' && (!$signer||
            !is_file(__DIR__.'/private/'.basename((string)$signer['signature_name']))||
            !is_file(__DIR__.'/private/'.basename((string)$signer['stamp_name'])))){
            mobile_error('Unggah TTD dan stempel resmi sebelum menyetujui surat.',422);
        }
        $newStatus=$decision==='reject'?'ditolak':($role==='rt'?'menunggu_rw':'terverifikasi');
        $by=$role==='rt'?'rt_approved_by':'rw_approved_by';
        $at=$role==='rt'?'rt_approved_at':'rw_approved_at';
        $noteCol=$role==='rt'?'rt_note':'rw_note';
        // Optimistic concurrency: two devices cannot advance the same stage.
        $stmt=$db->prepare("UPDATE mobile_rt_rw_letters SET status=?, $by=?, $at=NOW(), $noteCol=?
            WHERE id=? AND status=?");
        $stmt->execute([$newStatus,$uid,$note,$id,$expected]);
        if($stmt->rowCount()!==1)mobile_error('Tahap surat telah diproses oleh perangkat lain.',409);
        $msg=$newStatus==='ditolak'?'Pengajuan surat ditolak. '.$note:
           ($newStatus==='menunggu_rw'?'Ketua RT telah menyetujui surat. Menunggu Ketua RW.':
             'Ketua RT dan RW sudah menyetujui surat.');
        mobile_emit('surat','Status surat pengantar diperbarui',$msg,'personal',(string)$letter['user_id']);
        if($newStatus==='menunggu_rw')cikoko_rt_notify_officers('rw',$letter['rt'],$letter['rw'],
            'Surat menunggu Ketua RW','Surat pengantar telah lolos tahap Ketua RT.');
        mobile_json(['ok'=>true,'status'=>$newStatus]);
    }
    mobile_error('Aksi surat RT/RW tidak tersedia.',404);
}
