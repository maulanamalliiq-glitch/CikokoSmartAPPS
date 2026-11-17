<?php
declare(strict_types=1);

function cikoko_boarding_schema(PDO $db): void {
    static $ready = false;
    if ($ready) return;
    $db->exec('CREATE TABLE IF NOT EXISTS mobile_boarding_houses (
        id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(160) NOT NULL,
        address VARCHAR(420) NOT NULL,
        rt CHAR(2) NOT NULL,
        rw CHAR(2) NOT NULL,
        manager_name VARCHAR(120) NOT NULL,
        manager_phone VARCHAR(30) NOT NULL DEFAULT "",
        total_rooms SMALLINT UNSIGNED NOT NULL,
        occupied_rooms SMALLINT UNSIGNED NOT NULL,
        facilities_json TEXT NOT NULL,
        photo_name VARCHAR(80) NULL,
        public_listing TINYINT(1) NOT NULL DEFAULT 1,
        public_address TINYINT(1) NOT NULL DEFAULT 0,
        public_contact TINYINT(1) NOT NULL DEFAULT 0,
        record_status VARCHAR(16) NOT NULL DEFAULT "active",
        review_status VARCHAR(16) NOT NULL DEFAULT "pending",
        review_note VARCHAR(500) NOT NULL DEFAULT "",
        created_by VARCHAR(80) NOT NULL,
        updated_by VARCHAR(80) NOT NULL,
        verified_by VARCHAR(80) NULL,
        verified_at DATETIME NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_area_status(rw,rt,record_status,review_status),
        INDEX idx_public(review_status,record_status,public_listing)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
    $columns = $db->query("SHOW COLUMNS FROM mobile_boarding_houses LIKE 'photo_name'")->fetch(PDO::FETCH_ASSOC);
    if (!$columns) $db->exec('ALTER TABLE mobile_boarding_houses ADD COLUMN photo_name VARCHAR(80) NULL AFTER facilities_json');
    $ready = true;
}

function cikoko_boarding_area($value): string {
    $raw = trim((string)$value);
    if (!preg_match('/^[0-9]{1,2}$/D', $raw) || (int)$raw < 1 || (int)$raw > 99) {
        mobile_error('RT/RW harus angka antara 01 dan 99.', 422);
    }
    return str_pad((string)(int)$raw, 2, '0', STR_PAD_LEFT);
}

function cikoko_boarding_account(string $uid, string $role): ?array {
    foreach (db_read('portal_users') as $row) {
        if ((string)($row['id'] ?? '') === $uid && ($row['active'] ?? false) === true && ($row['role'] ?? '') === $role) {
            return $row;
        }
    }
    return null;
}

function cikoko_boarding_photo_url(int $id, $photo): string {
    if ($id < 1 || !is_string($photo) || !preg_match('/^[a-f0-9]{40}\.(jpg|png|webp)$/D', $photo)) return '';
    return 'https://datawebs.my.id/mobile-api/index.php?action=boarding_photo&id='.$id;
}

function cikoko_boarding_photo(PDO $db): void {
    cikoko_boarding_schema($db);
    $id = (int)($_GET['id'] ?? 0);
    if ($id < 1) mobile_error('Foto tidak ditemukan.', 404);
    $q = $db->prepare('SELECT id,photo_name,rt,rw,record_status,review_status,public_listing FROM mobile_boarding_houses WHERE id=?');
    $q->execute([$id]); $row = $q->fetch(PDO::FETCH_ASSOC);
    if (!$row || !preg_match('/^[a-f0-9]{40}\.(jpg|png|webp)$/D', (string)($row['photo_name'] ?? ''))) mobile_error('Foto tidak ditemukan.', 404);
    $isPublic = $row['record_status'] === 'active' && $row['review_status'] === 'verified' && (int)$row['public_listing'] === 1;
    if (!$isPublic) {
        $auth = mobile_auth(false);
        if (!$auth) mobile_error('Foto tidak ditemukan.', 404);
        $role = (string)$auth['user_role'];
        if (!in_array($role, ['rt','rw','admin','admin_kelurahan'], true)) mobile_error('Foto tidak ditemukan.', 404);
        if (in_array($role, ['rt','rw'], true)) {
            $account = cikoko_boarding_account((string)$auth['user_id'], $role);
            if (!$account || (string)($account['rw'] ?? '') !== (string)$row['rw'] || ($role === 'rt' && (string)($account['rt'] ?? '') !== (string)$row['rt'])) mobile_error('Foto tidak ditemukan.', 404);
        }
    }
    $path = __DIR__.'/private/'.basename((string)$row['photo_name']);
    if (!is_file($path)) mobile_error('Foto tidak ditemukan.', 404);
    $mime = (new finfo(FILEINFO_MIME_TYPE))->file($path);
    if (!in_array($mime, ['image/jpeg','image/png','image/webp'], true)) mobile_error('Foto tidak ditemukan.', 404);
    header_remove('Content-Type'); header('Content-Type: '.$mime); header('Cache-Control: '.($isPublic ? 'public, max-age=300' : 'private, no-store'));
    header('Content-Length: '.(string)filesize($path)); readfile($path); exit;
}

function cikoko_boarding_public(PDO $db): void {
    cikoko_boarding_schema($db);
    $summary = $db->query('SELECT COUNT(*) AS houses, COALESCE(SUM(total_rooms),0) AS rooms,
        COALESCE(SUM(GREATEST(total_rooms-occupied_rooms,0)),0) AS available_rooms
        FROM mobile_boarding_houses
        WHERE record_status="active" AND review_status="verified" AND public_listing=1')->fetch(PDO::FETCH_ASSOC) ?: [];
    $query = $db->query('SELECT id,name,rt,rw,address,public_address,manager_phone,public_contact,
        total_rooms,occupied_rooms,facilities_json,photo_name,updated_at
        FROM mobile_boarding_houses
        WHERE record_status="active" AND review_status="verified" AND public_listing=1
        ORDER BY rw,rt,name LIMIT 300');
    $items = [];
    foreach ($query->fetchAll(PDO::FETCH_ASSOC) as $row) {
        $items[] = [
            'id' => (int)$row['id'],
            'name' => (string)$row['name'],
            'rt' => (string)$row['rt'],
            'rw' => (string)$row['rw'],
            'address' => (int)$row['public_address'] === 1 ? (string)$row['address'] : '',
            'total_rooms' => (int)$row['total_rooms'],
            'available_rooms' => max(0, (int)$row['total_rooms'] - (int)$row['occupied_rooms']),
            'facilities' => json_decode((string)$row['facilities_json'], true) ?: [],
            'photo_url' => cikoko_boarding_photo_url((int)$row['id'], $row['photo_name'] ?? null),
            'public_phone' => (int)$row['public_contact'] === 1 ? (string)$row['manager_phone'] : '',
            'updated_at' => (string)$row['updated_at'],
        ];
    }
    mobile_json(['ok'=>true,'summary'=>[
        'houses'=>(int)($summary['houses']??0),
        'rooms'=>(int)($summary['rooms']??0),
        'available_rooms'=>(int)($summary['available_rooms']??0),
    ],'items'=>$items]);
}

function cikoko_boarding_dispatch(string $action, string $method, PDO $db, array $auth, string $uid): void {
    cikoko_boarding_schema($db);
    $role = (string)($auth['user_role'] ?? '');
    if (!in_array($role, ['rt','rw','admin','admin_kelurahan'], true)) {
        mobile_error('Menu pendataan kos khusus petugas RT/RW.', 403);
    }
    $account = in_array($role, ['rt','rw'], true) ? cikoko_boarding_account($uid, $role) : null;
    if (in_array($role, ['rt','rw'], true) && !$account) mobile_error('Akun petugas tidak aktif.', 403);
    $homeRw = $account ? cikoko_boarding_area($account['rw'] ?? '') : '';
    $homeRt = ($role === 'rt' && $account) ? cikoko_boarding_area($account['rt'] ?? '') : '';

    if ($action === 'boarding_list' && $method === 'GET') {
        if ($role === 'rt') {
            $q = $db->prepare('SELECT * FROM mobile_boarding_houses WHERE rt=? AND rw=? ORDER BY updated_at DESC LIMIT 200');
            $q->execute([$homeRt, $homeRw]);
        } elseif ($role === 'rw') {
            $q = $db->prepare('SELECT * FROM mobile_boarding_houses WHERE rw=? ORDER BY updated_at DESC LIMIT 300');
            $q->execute([$homeRw]);
        } else {
            $q = $db->query('SELECT * FROM mobile_boarding_houses ORDER BY updated_at DESC LIMIT 500');
        }
        $items = [];
        foreach ($q->fetchAll(PDO::FETCH_ASSOC) as $row) {
            $items[] = [
                'id'=>(int)$row['id'],'name'=>(string)$row['name'],'address'=>(string)$row['address'],
                'rt'=>(string)$row['rt'],'rw'=>(string)$row['rw'],
                'manager_name'=>(string)$row['manager_name'],'manager_phone'=>(string)$row['manager_phone'],
                'total_rooms'=>(int)$row['total_rooms'],'occupied_rooms'=>(int)$row['occupied_rooms'],
                'facilities'=>json_decode((string)$row['facilities_json'],true)?:[],
                'photo_url'=>cikoko_boarding_photo_url((int)$row['id'],$row['photo_name']??null),
                'public_listing'=>(bool)$row['public_listing'],'public_address'=>(bool)$row['public_address'],
                'public_contact'=>(bool)$row['public_contact'],'record_status'=>(string)$row['record_status'],
                'review_status'=>(string)$row['review_status'],'review_note'=>(string)$row['review_note'],
                'updated_at'=>(string)$row['updated_at'],
            ];
        }
        mobile_json(['ok'=>true,'items'=>$items,'rt'=>$homeRt,'rw'=>$homeRw,'role'=>$role]);
    }

    if ($action === 'boarding_save' && $method === 'POST') {
        if ($role === 'rw') mobile_error('Ketua RW memverifikasi data. Pengisian dilakukan oleh RT.', 403);
        $body = mobile_body();
        if (!$body && $_POST) $body = $_POST;
        if (isset($body['facilities']) && is_string($body['facilities'])) { $decoded = json_decode($body['facilities'], true); $body['facilities'] = is_array($decoded) ? $decoded : []; }
        $id = (int)($body['id'] ?? 0);
        $name = mobile_text($body['name'] ?? '',160);
        $address = mobile_text($body['address'] ?? '',420);
        $manager = mobile_text($body['manager_name'] ?? '',120);
        $phone = mobile_text($body['manager_phone'] ?? '',30);
        $total = filter_var($body['total_rooms'] ?? null,FILTER_VALIDATE_INT);
        $occupied = filter_var($body['occupied_rooms'] ?? null,FILTER_VALIDATE_INT);
        $status = (string)($body['record_status'] ?? 'active');
        if (mobile_strlen($name)<3 || $address==='' || mobile_strlen($manager)<2 || $total===false || $occupied===false || $total<1 || $total>500 || $occupied<0 || $occupied>$total) {
            mobile_error('Periksa nama kos, alamat, pengelola, dan jumlah kamar.',422);
        }
        if ($phone!=='' && !preg_match('/^[0-9+ ()-]{8,30}$/D',$phone)) mobile_error('Nomor kontak pengelola tidak valid.',422);
        if (!in_array($status,['active','closed'],true)) mobile_error('Status kos tidak valid.',422);
        $allowedFacilities=['Wi-Fi','AC','Kamar mandi dalam','Parkir','Furnitur','Dapur','Keamanan'];
        $facilities=$body['facilities']??[];
        if (!is_array($facilities) || count($facilities)>7) mobile_error('Daftar fasilitas tidak valid.',422);
        $facilities=array_values(array_unique(array_filter(array_map('strval',$facilities),static fn($v)=>in_array($v,$allowedFacilities,true))));
        $rt=$role==='rt'?$homeRt:cikoko_boarding_area($body['rt']??'');
        $rw=in_array($role,['rt','rw'],true)?$homeRw:cikoko_boarding_area($body['rw']??'');
        if ($role==='rt' && $homeRt==='') mobile_error('Akun RT belum diberi wilayah.',403);
        $asBool = static fn($value, bool $default=false): bool => $value === null ? $default : in_array($value, [true, 1, '1', 'true', 'on'], true);
        $publicListing=$asBool($body['public_listing']??null, true);
        $publicAddress=$publicListing && $asBool($body['public_address']??null);
        $publicContact=$publicListing && $phone!=='' && $asBool($body['public_contact']??null);
        $uploadedPhoto = mobile_file('photo', $id === 0);
        if ($id>0) {
            $check=$db->prepare('SELECT id,rt,rw,created_by,photo_name FROM mobile_boarding_houses WHERE id=?');
            $check->execute([$id]);$old=$check->fetch(PDO::FETCH_ASSOC);
            if(!$old)mobile_error('Data kos tidak ditemukan.',404);
            if($role==='rt'&&((string)$old['rt']!==$homeRt||(string)$old['rw']!==$homeRw))mobile_error('Kos ini di luar wilayah RT Anda.',403);
            if($role==='rw'&&(string)$old['rw']!==$homeRw)mobile_error('Kos ini di luar wilayah RW Anda.',403);
            $photoName = $uploadedPhoto ?? ($old['photo_name'] ?? null);
            $stmt=$db->prepare('UPDATE mobile_boarding_houses SET name=?,address=?,manager_name=?,manager_phone=?,total_rooms=?,occupied_rooms=?,facilities_json=?,photo_name=?,public_listing=?,public_address=?,public_contact=?,record_status=?,review_status="pending",review_note="",verified_by=NULL,verified_at=NULL,updated_by=? WHERE id=?');
            $stmt->execute([$name,$address,$manager,$phone,$total,$occupied,json_encode($facilities,JSON_UNESCAPED_UNICODE|JSON_THROW_ON_ERROR),$photoName,(int)$publicListing,(int)$publicAddress,(int)$publicContact,$status,$uid,$id]);
            if ($uploadedPhoto && !empty($old['photo_name']) && $old['photo_name'] !== $uploadedPhoto) { $oldPath=__DIR__.'/private/'.basename((string)$old['photo_name']); if (is_file($oldPath)) @unlink($oldPath); }
        } else {
            $stmt=$db->prepare('INSERT INTO mobile_boarding_houses(name,address,rt,rw,manager_name,manager_phone,total_rooms,occupied_rooms,facilities_json,photo_name,public_listing,public_address,public_contact,record_status,created_by,updated_by) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)');
            $stmt->execute([$name,$address,$rt,$rw,$manager,$phone,$total,$occupied,json_encode($facilities,JSON_UNESCAPED_UNICODE|JSON_THROW_ON_ERROR),$uploadedPhoto,(int)$publicListing,(int)$publicAddress,(int)$publicContact,$status,$uid,$uid]);
            $id=(int)$db->lastInsertId();
        }
        mobile_json(['ok'=>true,'id'=>$id,'review_status'=>'pending','message'=>'Data kos tersimpan dan menunggu verifikasi Ketua RW.']);
    }

    if ($action === 'boarding_verify' && $method === 'POST') {
        if (!in_array($role,['rw','admin','admin_kelurahan'],true)) mobile_error('Verifikasi data kos dilakukan Ketua RW.',403);
        $body=mobile_body();$id=(int)($body['id']??0);$decision=(string)($body['decision']??'');
        $note=mobile_text($body['note']??'',500);
        if($id<1||!in_array($decision,['verified','rejected'],true))mobile_error('Keputusan verifikasi tidak valid.',422);
        if($decision==='rejected'&&$note==='')mobile_error('Catatan penolakan wajib diisi.',422);
        $q=$db->prepare('SELECT rw,review_status FROM mobile_boarding_houses WHERE id=?');$q->execute([$id]);$row=$q->fetch(PDO::FETCH_ASSOC);
        if(!$row)mobile_error('Data kos tidak ditemukan.',404);
        if($role==='rw'&&(string)$row['rw']!==$homeRw)mobile_error('Data ini di luar wilayah RW Anda.',403);
        if((string)$row['review_status']!=='pending')mobile_error('Data ini sudah diproses. Muat ulang daftar.',409);
        $st=$db->prepare('UPDATE mobile_boarding_houses SET review_status=?,review_note=?,verified_by=?,verified_at=NOW(),updated_by=? WHERE id=? AND review_status="pending"');
        $st->execute([$decision,$note,$uid,$uid,$id]);
        if($st->rowCount()!==1)mobile_error('Data telah diverifikasi oleh petugas lain.',409);
        mobile_json(['ok'=>true,'review_status'=>$decision,'message'=>$decision==='verified'?'Data kos disetujui untuk ditampilkan sesuai pilihan publikasi.':'Data kos dikembalikan untuk diperbaiki.']);
    }
    mobile_error('Aksi pendataan kos tidak tersedia.',404);
}
