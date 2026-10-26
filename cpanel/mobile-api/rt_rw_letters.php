<?php
declare(strict_types=1);
require_once __DIR__.'/territory.php';

/**
 * V2513: pengalihan dan verifikasi berjenjang, BUKAN tanda tangan elektronik.
 * Penerbitan PDF, stempel dan sertifikat resmi dilaksanakan dalam modul terpisah.
 */
function cikoko_letters_schema(PDO $db):void {
    static $done=false;if($done)return;
    try {
        $db->exec('CREATE TABLE IF NOT EXISTS mobile_rt_rw_letters (
            id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            applicant_id VARCHAR(80) NOT NULL,
            applicant_name VARCHAR(160) NOT NULL,
            applicant_address VARCHAR(600) NOT NULL,
            rt CHAR(3) NOT NULL,
            rw CHAR(3) NOT NULL,
            rt_officer_id VARCHAR(80) NOT NULL,
            rw_officer_id VARCHAR(80) NOT NULL,
            subject VARCHAR(180) NOT NULL,
            notes TEXT NOT NULL,
            status VARCHAR(25) NOT NULL DEFAULT "menunggu_rt",
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_applicant(applicant_id,id),
            INDEX idx_rt_officer(rt_officer_id,status),
            INDEX idx_rw_officer(rw_officer_id,status)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
        $db->exec('CREATE TABLE IF NOT EXISTS mobile_rt_rw_letter_history (
            id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            letter_id BIGINT UNSIGNED NOT NULL,
            actor_id VARCHAR(80) NOT NULL,
            actor_role VARCHAR(30) NOT NULL,
            decision VARCHAR(25) NOT NULL,
            note VARCHAR(1200) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_letter(letter_id,id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
        $db->exec('CREATE TABLE IF NOT EXISTS mobile_rt_rw_officer_audit (
            id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            actor_id VARCHAR(80) NOT NULL,
            officer_id VARCHAR(80) NOT NULL,
            previous_area VARCHAR(20) NOT NULL,
            new_area VARCHAR(20) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
    }catch(Throwable $e){
        error_log('V2513 database schema: '.$e->getMessage());
        mobile_error('Struktur data surat RT/RW belum terpasang.',503);
    }
    $done=true;
}
function cikoko_rt_rw_dispatch(string $action,string $method,PDO $db,array $auth):void {
    $role=(string)$auth['user_role'];
    $uid=(string)$auth['user_id'];
    if($action==='rt_rw_officers'){
        if($role!=='admin')mobile_error('Hanya Admin Utama mengelola wilayah petugas.',403);
        if($method!=='GET')mobile_error('Metode tidak diperbolehkan.',405);
        $items=[];
        foreach(db_read('portal_users') as $officer){
            if(!in_array(($officer['role']??''),['rt','rw'],true))continue;
            $items[]=['id'=>(string)($officer['id']??''),'name'=>(string)($officer['name']??''),
                'username'=>(string)($officer['username']??''),'role'=>(string)$officer['role'],
                'rt'=>(string)($officer['rt']??''),'rw'=>(string)($officer['rw']??''),
                'active'=>!empty($officer['active'])];
        }
        mobile_json(['ok'=>true,'items'=>$items]);
    }
    if($action==='rt_rw_officer_assign'){
        if($role!=='admin')mobile_error('Hanya Admin Utama mengelola wilayah petugas.',403);
        if($method!=='POST')mobile_error('Metode tidak diperbolehkan.',405);
        $b=mobile_body();$target=mobile_text($b['officer_id']??'',80);
        $users=db_read('portal_users');$index=null;
        foreach($users as $i=>$p)if((string)($p['id']??'')===$target){$index=$i;break;}
        if($index===null || !in_array(($users[$index]['role']??''),['rt','rw'],true))
            mobile_error('Akun Ketua RT/RW tidak ditemukan.',404);
        $officerRole=(string)$users[$index]['role'];
        $rw=cikoko_area($b['rw']??'','RW');
        $rt=$officerRole==='rt'?cikoko_area($b['rt']??'','RT'):'';
        foreach($users as $i=>$p){
            if($i===$index||empty($p['active'])||($p['role']??'')!==$officerRole)continue;
            if(cikoko_area($p['rw']??'','RW',false)!==$rw)continue;
            if($officerRole==='rw'||cikoko_area($p['rt']??'','RT',false)===$rt)
                mobile_error('Wilayah tersebut sudah memiliki Ketua '.strtoupper($officerRole).' aktif.',409);
        }
        $previous=(string)($users[$index]['rt']??'').'/'.(string)($users[$index]['rw']??'');
        $users[$index]['rt']=$rt;$users[$index]['rw']=$rw;
        if(!db_write('portal_users',$users))mobile_error('Wilayah petugas belum tersimpan.',503);
        cikoko_letters_schema($db);
        $db->prepare('INSERT INTO mobile_rt_rw_officer_audit(actor_id,officer_id,previous_area,new_area) VALUES(?,?,?,?)')
            ->execute([$uid,$target,$previous,$rt.'/'.$rw]);
        mobile_json(['ok'=>true,'message'=>'Wilayah petugas berhasil disimpan.']);
    }

    cikoko_letters_schema($db);
    if($action==='rt_rw_submit'){
        if($method!=='POST')mobile_error('Metode tidak diperbolehkan.',405);
        if($role!=='warga')mobile_error('Permohonan diajukan melalui akun warga.',403);
        $profile=cikoko_user_by_id($uid);
        if(!$profile||empty($profile['active']))mobile_error('Profil warga tidak ditemukan.',404);
        $rt=cikoko_area($profile['rt']??'','RT');
        $rw=cikoko_area($profile['rw']??'','RW');
        $address=mobile_text($profile['address']??'',600);
        if(mobile_strlen($address)<4)mobile_error('Lengkapi alamat pada Profil terlebih dahulu.',422);
        // Nomor wilayah dari profil tersimpan, tidak menerima RT/RW buatan klien.
        $officerRt=cikoko_officer_for('rt',$rt,$rw);
        $officerRw=cikoko_officer_for('rw',$rt,$rw);
        $b=mobile_body();$subject=mobile_text($b['subject']??'',180);
        $notes=mobile_text($b['notes']??'',1200);
        if(mobile_strlen($subject)<5||mobile_strlen($notes)<10)
            mobile_error('Isi keperluan (minimal 5 karakter) dan uraian (minimal 10 karakter).',422);
        $last=$db->prepare('SELECT created_at FROM mobile_rt_rw_letters WHERE applicant_id=? ORDER BY id DESC LIMIT 1');
        $last->execute([$uid]);$at=$last->fetchColumn();
        if($at!==false && strtotime((string)$at)>time()-120)mobile_error('Mohon beri jeda sebelum mengirim permohonan baru.',429);
        $st=$db->prepare('INSERT INTO mobile_rt_rw_letters(applicant_id,applicant_name,applicant_address,rt,rw,rt_officer_id,rw_officer_id,subject,notes,status)
             VALUES(?,?,?,?,?,?,?,?,?,"menunggu_rt")');
        $st->execute([$uid,mobile_text($profile['name']??'',160),$address,$rt,$rw,
            (string)$officerRt['id'],(string)$officerRw['id'],$subject,$notes]);
        $id=(int)$db->lastInsertId();
        mobile_emit('rt_rw_surat','Permohonan pengantar baru','Ada permohonan pengantar RT/RW untuk wilayah tugas Anda.','personal',(string)$officerRt['id']);
        mobile_json(['ok'=>true,'id'=>$id,'status'=>'menunggu_rt','rt'=>$rt,'rw'=>$rw]);
    }
    if($action==='rt_rw_list'){
        if($method!=='GET')mobile_error('Metode tidak diperbolehkan.',405);
        $sql='SELECT id,applicant_name,applicant_address,rt,rw,subject,notes,status,created_at,updated_at FROM mobile_rt_rw_letters';
        $args=[];
        if($role==='warga'){$sql.=' WHERE applicant_id=?';$args=[$uid];}
        elseif($role==='rt'){$sql.=' WHERE rt_officer_id=?';$args=[$uid];}
        elseif($role==='rw'){$sql.=' WHERE rw_officer_id=?';$args=[$uid];}
        elseif(!in_array($role,['admin','admin_kelurahan'],true))mobile_error('Anda tidak memiliki akses ke daftar surat.',403);
        $sql.=' ORDER BY id DESC LIMIT 100';
        $st=$db->prepare($sql);$st->execute($args);
        mobile_json(['ok'=>true,'items'=>$st->fetchAll()]);
    }
    if($action==='rt_rw_decide'){
        if($method!=='POST')mobile_error('Metode tidak diperbolehkan.',405);
        if(!in_array($role,['rt','rw'],true))mobile_error('Hanya Ketua RT/RW wilayah yang dapat memverifikasi.',403);
        $b=mobile_body();$id=filter_var($b['id']??null,FILTER_VALIDATE_INT,['options'=>['min_range'=>1]]);
        $decision=(string)($b['decision']??'');$note=mobile_text($b['note']??'',1200);
        if(!$id||!in_array($decision,['approve','reject'],true))mobile_error('Keputusan tidak valid.',422);
        if($decision==='reject'&&mobile_strlen($note)<5)mobile_error('Alasan penolakan wajib diisi.',422);
        $officer=cikoko_user_by_id($uid);
        if(!$officer || ($officer['role']??'')!==$role || empty($officer['active'])
          || !password_verify((string)($b['current_password']??''),(string)($officer['password_hash']??'')))
            mobile_error('Konfirmasi password Ketua RT/RW diperlukan.',403);
        $db->beginTransaction();
        try {
            $st=$db->prepare('SELECT * FROM mobile_rt_rw_letters WHERE id=? FOR UPDATE');
            $st->execute([$id]);$letter=$st->fetch();
            if(!$letter)mobile_error('Permohonan tidak ditemukan.',404);
            $expected=$role==='rt'?'menunggu_rt':'menunggu_rw';
            $key=$role==='rt'?'rt_officer_id':'rw_officer_id';
            if(cikoko_area($officer['rw']??'','RW',false)!==(string)$letter['rw']
                || ($role==='rt' && cikoko_area($officer['rt']??'','RT',false)!==(string)$letter['rt']))
                mobile_error('Wilayah tugas Anda telah berubah. Hubungi Admin Kelurahan untuk tindak lanjut.',403);
            if((string)$letter[$key]!==$uid || $letter['status']!==$expected)
                mobile_error('Permohonan bukan pada tahap atau wilayah tugas Anda.',403);
            $next=$decision==='reject'?'ditolak':($role==='rt'?'menunggu_rw':'terverifikasi');
            $db->prepare('UPDATE mobile_rt_rw_letters SET status=? WHERE id=? AND status=?')
                ->execute([$next,$id,$expected]);
            $db->prepare('INSERT INTO mobile_rt_rw_letter_history(letter_id,actor_id,actor_role,decision,note) VALUES(?,?,?,?,?)')
                ->execute([$id,$uid,$role,$decision,$note]);
            $db->commit();
            mobile_emit('rt_rw_status','Status Surat Pengantar RT/RW','Status permohonan Anda: '.$next.'.','personal',(string)$letter['applicant_id']);
            if($next==='menunggu_rw')
                mobile_emit('rt_rw_surat','Verifikasi RW menunggu','Ada surat pengantar dari RT untuk ditinjau.','personal',(string)$letter['rw_officer_id']);
            mobile_json(['ok'=>true,'status'=>$next]);
        }catch(Throwable $e){
            if($db->inTransaction())$db->rollBack();
            throw $e;
        }
    }
    mobile_error('Aksi RT/RW tidak dikenal.',404);
}
