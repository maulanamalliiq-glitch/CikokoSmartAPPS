<?php
declare(strict_types=1);
/**
 * Pengelolaan akun petugas Cikoko; hanya Admin Utama.
 * Password hanya disimpan dalam bentuk hash. Tidak ada endpoint membuat admin baru.
 * portal_users adalah sumber akun web dan Android yang sama.
 */
function cikoko_admin_accounts(string $action,string $method,PDO $db,array $actor):void {
    if(($actor['user_role']??'')!=='admin')mobile_error('Hanya Admin Utama yang dapat mengelola akun.',403);

    $roles=mobile_role_names();
    // Kompatibilitas dengan permissions.php lama di cPanel. Jika daftar
    // role server belum diperbarui, tetap tampilkan kedua jabatan LPJ resmi.
    // Tambahan ini hanya berlaku di endpoint Admin Utama; tidak mengubah
    // login, izin akun lain, atau pemetaan role global.
    $roles['bendahara_rt']='Bendahara RT';
    $roles['bendahara_rw']='Bendahara RW';
    unset($roles['admin']);
    if($action==='accounts_list' && $method==='GET') {
        $items=[];
        foreach(array_reverse(db_read('portal_users')) as $p) {
            if(!is_array($p))continue;
            $items[]=[
                'id'=>(string)($p['id']??''),
                'name'=>(string)($p['name']??''),
                'username'=>(string)($p['username']??''),
                'role'=>(string)($p['role']??''),
                'rt'=>(string)($p['rt']??''),
                'rw'=>(string)($p['rw']??''),
                'active'=>!empty($p['active']),
            ];
            if(count($items)>=300)break;
        }
        mobile_json(['ok'=>true,'roles'=>$roles,'items'=>$items]);
    }
    if($action!=='accounts_create' || $method!=='POST')
        mobile_error('Operasi pengelolaan akun tidak tersedia.',405);

    $body=mobile_body();
    $name=mobile_text($body['name']??'',120);
    $username=mobile_text($body['username']??'',80);
    $password=(string)($body['password']??'');
    $role=mobile_text($body['role']??'',50);
    $phone=mobile_text($body['phone']??'',40);
    $email=mobile_text($body['email']??'',160);
    if(!isset($roles[$role]) || $role==='warga')
        mobile_error('Pilih salah satu peran petugas yang tersedia.',422);
    if(mobile_strlen($name)<3 || !preg_match('/^[a-zA-Z0-9_.-]{4,40}$/D',$username))
        mobile_error('Nama minimal 3 karakter dan username 4–40 karakter (huruf, angka, titik, garis).',422);
    if(strlen($password)<8 || strlen($password)>72)
        mobile_error('Password awal harus 8–72 karakter.',422);
    if($phone!=='' && !preg_match('/^[0-9+ ()-]{8,25}$/D',$phone))
        mobile_error('Nomor telepon tidak sesuai.',422);
    if($email!=='' && !filter_var($email,FILTER_VALIDATE_EMAIL))
        mobile_error('Alamat email tidak sesuai.',422);

    $official=in_array($role,['rt','rw','bendahara_rt','bendahara_rw'],true);
    $areaRole=$official || $role==='lmk';
    $needsRt=in_array($role,['rt','bendahara_rt'],true);
    $rt=$needsRt?cikoko_area($body['rt']??'','RT'):'';
    $rw=$areaRole?cikoko_area($body['rw']??'','RW'):'';
    $newId=bin2hex(random_bytes(12));
    $entry=[
        'id'=>$newId,'name'=>$name,'username'=>$username,
        'password_hash'=>password_hash($password,PASSWORD_DEFAULT),
        'role'=>$role,'department'=>$roles[$role],
        'address'=>'','rt'=>$rt,'rw'=>$rw,'phone'=>$phone,'email'=>$email,
        'active'=>true,'created_at'=>date('c'),
    ];

    // Kunci pembacaan + penulisan sekaligus agar dua permintaan admin
    // tidak dapat membuat username yang sama atau saling menimpa.
    $file=data_path('portal_users');
    $fp=@fopen($file,'c+');
    if(!$fp)mobile_error('Penyimpanan akun tidak tersedia.',503);
    if(!flock($fp,LOCK_EX)){fclose($fp);mobile_error('Penyimpanan akun sedang digunakan.',503);}
    $createdOfficer=false;
    $error=null;$http=503;
    try {
        rewind($fp);
        $original=stream_get_contents($fp);
        $users=json_decode($original?:'[]',true);
        if(!is_array($users) || ($original!=='' && json_last_error()!==JSON_ERROR_NONE))
            throw new RuntimeException('Berkas akun tidak dapat dibaca dengan aman.');
        $adminCfg=db_read('admin');
        if(strcasecmp((string)($adminCfg['username']??''),$username)===0)
            throw new DomainException('Username sudah digunakan.');
        foreach($users as $p) {
            if(strcasecmp((string)($p['username']??''),$username)===0)
                throw new DomainException('Username sudah digunakan.');
            if($official && !empty($p['active']) && ($p['role']??'')===$role
                && (int)($p['rw']??0)===(int)$rw
                && (!$needsRt || (int)($p['rt']??0)===(int)$rt))
                throw new DomainException('Jabatan tersebut sudah memiliki akun aktif di wilayah ini.');
        }

        if($official) {
            // Bendahara/Ketua harus resmi tercatat pada civic_officers
            // sebelum dapat memakai LPJ / tanda persetujuan.
            $st=$db->prepare('SELECT duty,rt,rw FROM civic_officers WHERE duty=? AND active=1');
            $st->execute([$role]);
            foreach($st->fetchAll() as $o) {
                if((int)($o['rw']??0)===(int)$rw
                    && (!$needsRt || (int)($o['rt']??0)===(int)$rt))
                    throw new DomainException('Jabatan LPJ sudah ditugaskan pada wilayah tersebut.');
            }
            $st=$db->prepare('INSERT INTO civic_officers(user_id,duty,rt,rw,display_name,active) VALUES(?,?,?,?,?,1)');
            $st->execute([
                $newId,$role,$needsRt?str_pad($rt,3,'0',STR_PAD_LEFT):null,
                str_pad($rw,3,'0',STR_PAD_LEFT),$name,
            ]);
            $createdOfficer=true;
        }

        $users[]=$entry;
        $payload=json_encode($users,JSON_PRETTY_PRINT|JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES|JSON_THROW_ON_ERROR);
        rewind($fp);
        if(!ftruncate($fp,0))throw new RuntimeException('Berkas akun tidak dapat diperbarui.');
        $written=0;
        while($written<strlen($payload)) {
            $n=fwrite($fp,substr($payload,$written));
            if($n===false || $n===0)throw new RuntimeException('Gagal menyimpan seluruh data akun.');
            $written+=$n;
        }
        if(!fflush($fp))throw new RuntimeException('Gagal menyelesaikan penyimpanan akun.');
    }catch(DomainException $e) {
        $error=$e->getMessage();$http=409;
    }catch(Throwable $e) {
        error_log('[admin_accounts] '.$e->getMessage());
        $error='Pembuatan akun gagal. Periksa izin file dan penugasan civic_officers.';
    }
    if($error!==null) {
        // Pulihkan isi semula bila write parsial terjadi.
        if(isset($original) && is_string($original)) {
            rewind($fp);ftruncate($fp,0);fwrite($fp,$original);fflush($fp);
        }
        if($createdOfficer) {
            try {$db->prepare('DELETE FROM civic_officers WHERE user_id=? AND duty=?')
                    ->execute([$newId,$role]);}
            catch(Throwable $e){error_log('[admin_accounts rollback] '.$e->getMessage());}
        }
    }
    flock($fp,LOCK_UN);
    fclose($fp);
    if($error!==null)mobile_error($error,$http);
    mobile_json(['ok'=>true,'message'=>'Akun petugas berhasil dibuat.','item'=>[
        'id'=>$newId,'name'=>$name,'username'=>$username,
        'role'=>$role,'rt'=>$rt,'rw'=>$rw,'active'=>true,
    ]],201);
}
