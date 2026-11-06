<?php
declare(strict_types=1);

/**
 * LPJ / civic workflow for RT, RW and LMK.
 * Server controls all role, area, owner and approval decisions.
 * No client-provided status, signer or scope is trusted.
 */
function cikoko_civic_schema(PDO $db):void {
    static $ready=false;
    if($ready)return;
    try{
        $db->exec('CREATE TABLE IF NOT EXISTS mobile_civic_lpj (
          id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
          user_id VARCHAR(80) NOT NULL, owner_name VARCHAR(180) NOT NULL,
          kind VARCHAR(25) NOT NULL, period CHAR(7) NOT NULL,
          rt CHAR(2) NOT NULL DEFAULT "", rw CHAR(2) NOT NULL,
          payload_json LONGTEXT NOT NULL, status VARCHAR(30) NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          INDEX idx_owner(user_id,id), INDEX idx_scope(kind,rw,rt,status)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
        $db->exec('CREATE TABLE IF NOT EXISTS mobile_civic_approvals (
          id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
          lpj_id BIGINT UNSIGNED NOT NULL, user_id VARCHAR(80) NOT NULL,
          duty VARCHAR(40) NOT NULL, action VARCHAR(20) NOT NULL,
          notes VARCHAR(900) NOT NULL DEFAULT "",
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          INDEX idx_lpj(lpj_id,id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
        $db->exec('CREATE TABLE IF NOT EXISTS mobile_civic_pins (
          user_id VARCHAR(80) PRIMARY KEY,
          pin_hash VARCHAR(255) NOT NULL,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
    }catch(Throwable $e){
        error_log('LPJ schema: '.$e->getMessage());
        mobile_error('Tabel LPJ belum tersedia. Hubungi pengelola sistem.',503);
    }
    $ready=true;
}
function cikoko_civic_scope(array $auth,string $uid):array {
    $role=(string)($auth['user_role']??'');
    $user=cikoko_rt_user($uid);
    $duty=in_array($role,['admin','bendahara_rt','bendahara_rw','rt','rw','lmk'],true)
      ? $role : '';
    return [
      'duty'=>$duty,
      'rt'=>cikoko_optional_area($user['rt']??''),
      'rw'=>cikoko_optional_area($user['rw']??''),
    ];
}
function cikoko_civic_allowed(array $item,array $scope,string $uid):bool {
    if($scope['duty']==='admin')return true;
    if($item['user_id']===$uid)return true;
    if($scope['rw']===''||$scope['rw']!==$item['rw'])return false;
    $duty=$scope['duty'];
    if(in_array($duty,['rt','bendahara_rt'],true)){
        return $item['kind']==='lpj_rt'&&$scope['rt']!==''&&$scope['rt']===$item['rt'];
    }
    if(in_array($duty,['rw','bendahara_rw'],true))return $item['kind']==='lpj_rw';
    return $duty==='lmk'&&in_array($item['kind'],['lpj_lmk_a','lpj_lmk_b'],true);
}
function cikoko_civic_item(PDO $db,array $row):array {
    $row['id']=(int)$row['id'];
    $row['payload']=json_decode((string)($row['payload_json']??''),true)?:[];
    unset($row['payload_json']);
    $q=$db->prepare('SELECT duty,action,notes,created_at FROM mobile_civic_approvals WHERE lpj_id=? ORDER BY id');
    $q->execute([$row['id']]);$row['approvals']=$q->fetchAll(PDO::FETCH_ASSOC);
    return $row;
}
function cikoko_civic_required_duty(array $row):string {
    $kind=(string)$row['kind'];$status=(string)$row['status'];
    if($status==='menunggu_ketua')return $kind==='lpj_rt'?'rt':($kind==='lpj_rw'?'rw':'');
    if($status==='menunggu_bendahara')return $kind==='lpj_rt'?'bendahara_rt':($kind==='lpj_rw'?'bendahara_rw':'');
    if($status==='menunggu_lmk')return 'lmk';
    return '';
}
function cikoko_civic_dispatch(string $action,string $method,PDO $db,array $auth,string $uid):void {
    cikoko_civic_schema($db);
    $scope=cikoko_civic_scope($auth,$uid);$duty=$scope['duty'];
    if($action==='civic_catalog'){
        if($method!=='GET')mobile_error('Metode tidak diizinkan.',405);
        mobile_json(['ok'=>true,'scope'=>$scope,'kinds'=>['lpj_rt','lpj_rw','lpj_lmk_a','lpj_lmk_b']]);
    }
    if($action==='civic_list'){
        if($method!=='GET')mobile_error('Metode tidak diizinkan.',405);
        if($duty==='admin')$q=$db->query('SELECT * FROM mobile_civic_lpj ORDER BY id DESC LIMIT 100');
        elseif($scope['rw']===''){
            $q=$db->prepare('SELECT * FROM mobile_civic_lpj WHERE user_id=? ORDER BY id DESC LIMIT 80');
            $q->execute([$uid]);
        }else{
            // Bound by RW then a second role/RT + owner check.
            $q=$db->prepare('SELECT * FROM mobile_civic_lpj WHERE rw=? OR user_id=? ORDER BY id DESC LIMIT 150');
            $q->execute([$scope['rw'],$uid]);
        }
        $rows=[];
        foreach($q->fetchAll(PDO::FETCH_ASSOC) as $item){
            if(cikoko_civic_allowed($item,$scope,$uid)){
                $rows[]=['id'=>(int)$item['id'],'kind'=>$item['kind'],'period'=>$item['period'],
                  'status'=>$item['status'],'owner_name'=>$item['owner_name'],
                  'rt'=>$item['rt'],'rw'=>$item['rw'],'created_at'=>$item['created_at']];
            }
        }
        mobile_json(['ok'=>true,'items'=>$rows]);
    }
    if($action==='civic_submit'){
        if($method!=='POST')mobile_error('Metode tidak diizinkan.',405);
        $body=mobile_body();
        $kind=(string)($body['kind']??'');
        $duties=['lpj_rt'=>'bendahara_rt','lpj_rw'=>'bendahara_rw',
          'lpj_lmk_a'=>'lmk','lpj_lmk_b'=>'lmk'];
        if(!isset($duties[$kind])||$duties[$kind]!==$duty)
            mobile_error('Jabatan akun tidak berwenang mengirim jenis LPJ ini.',403);
        $rw=$scope['rw'];$rt=$scope['rt'];
        if($rw===''||($kind==='lpj_rt'&&$rt===''))
            mobile_error('Wilayah akun belum ditetapkan oleh Admin Utama.',422);
        $period=(string)($body['period']??'');
        if(!preg_match('/^20[0-9]{2}-(0[1-9]|1[0-2])$/D',$period))
            mobile_error('Periode harus YYYY-MM.',422);
        $fields=$body['fields']??null;
        if(!is_array($fields))mobile_error('Data keuangan LPJ tidak valid.',422);
        $opening=$fields['opening']??null;$income=$fields['income']??null;
        if(!is_int($opening)||!is_int($income)||$opening<0||$income<0
            ||$opening>999999999999||$income>999999999999)
            mobile_error('Nominal saldo dan penerimaan tidak valid.',422);
        $entries=$fields['entries']??null;
        if(!is_array($entries)||count($entries)>60)mobile_error('Daftar pengeluaran maksimal 60 kegiatan.',422);
        $safe=[];$spent=0;
        foreach($entries as $entry){
            if(!is_array($entry)||!is_int($entry['amount']??null))
                mobile_error('Rincian pengeluaran tidak valid.',422);
            $name=mobile_text($entry['activity']??'',180);
            $amount=$entry['amount'];$note=mobile_text($entry['notes']??'',500);
            if(mobile_strlen($name)<3||$amount<0||$amount>999999999999)
                mobile_error('Nama kegiatan atau jumlah pengeluaran tidak valid.',422);
            $spent+=$amount;
            if($spent>($opening+$income))mobile_error('Pengeluaran melebihi penerimaan.',422);
            $safe[]=['activity'=>$name,'amount'=>$amount,'notes'=>$note];
        }
        $payload=['opening'=>$opening,'income'=>$income,'entries'=>$safe,
          'total_expenses'=>$spent,'closing'=>$opening+$income-$spent];
        $owner=cikoko_rt_user($uid);
        if(!$owner)mobile_error('Akun pemohon tidak aktif.',403);
        $status=str_starts_with($kind,'lpj_lmk')?'menunggu_lmk':'menunggu_ketua';
        $stmt=$db->prepare('INSERT INTO mobile_civic_lpj(user_id,owner_name,kind,period,rt,rw,payload_json,status)
           VALUES(?,?,?,?,?,?,?,?)');
        $stmt->execute([$uid,mobile_text($owner['name']??'',180),$kind,$period,
          $kind==='lpj_rt'?$rt:'',$rw,
          json_encode($payload,JSON_UNESCAPED_UNICODE|JSON_THROW_ON_ERROR),$status]);
        $id=(int)$db->lastInsertId();
        mobile_emit('laporan','LPJ diterima','LPJ '.$period.' masuk tahap pemeriksaan.','personal',$uid);
        mobile_json(['ok'=>true,'id'=>$id,'status'=>$status]);
    }
    if($action==='civic_pin_set'){
        if($method!=='POST'||!in_array($duty,['rt','rw','bendahara_rt','bendahara_rw','lmk'],true))
            mobile_error('Akun tidak berwenang mengatur PIN LPJ.',403);
        $body=mobile_body();
        $pin=(string)($body['pin']??'');
        if(!preg_match('/^[0-9]{6}$/D',$pin))mobile_error('PIN harus enam angka.',422);
        $owner=cikoko_rt_user($uid);
        if(!$owner)mobile_error('Akun tidak ditemukan.',403);
        cikoko_rt_password($owner,(string)($body['current_password']??''));
        $hash=password_hash($pin,PASSWORD_DEFAULT);
        $q=$db->prepare('INSERT INTO mobile_civic_pins(user_id,pin_hash) VALUES(?,?)
          ON DUPLICATE KEY UPDATE pin_hash=VALUES(pin_hash)');
        $q->execute([$uid,$hash]);
        mobile_json(['ok'=>true,'message'=>'PIN persetujuan telah disimpan.']);
    }
    if($action==='civic_detail'||$action==='civic_review'||$action==='civic_pdf'){
        if($action==='civic_detail'||$action==='civic_pdf') {
            if($method!=='GET')mobile_error('Metode tidak diperbolehkan.',405);
            $id=(int)($_GET['id']??0);
        }else{
            if($method!=='POST')mobile_error('Metode tidak diperbolehkan.',405);
            $body=mobile_body();$id=(int)($body['id']??0);
        }
        if($id<=0)mobile_error('Nomor LPJ tidak valid.',422);
        $q=$db->prepare('SELECT * FROM mobile_civic_lpj WHERE id=?');
        $q->execute([$id]);$row=$q->fetch(PDO::FETCH_ASSOC);
        if(!$row||!cikoko_civic_allowed($row,$scope,$uid))
            mobile_error('LPJ tidak tersedia untuk akun atau wilayah ini.',404);
        if($action==='civic_detail'){
            mobile_json(['ok'=>true,'item'=>cikoko_civic_item($db,$row)]);
        }
        if($action==='civic_pdf'){
            $doc=cikoko_civic_item($db,$row);
            $payload=$doc['payload'];
            $status=$doc['status']==='selesai'?'SELESAI / DIPERIKSA':'BELUM DISETUJUI / DRAF';
            $lines=[
              'LAPORAN PERTANGGUNGJAWABAN (LPJ) — KELURAHAN CIKOKO',
              'REG LPJ: '.$id.'   JENIS: '.$row['kind'].'   PERIODE: '.$row['period'],
              'Status: '.$status,
              'Petugas penyusun: '.$row['owner_name'],
              'Wilayah: RT '.($row['rt']?:'-').' / RW '.$row['rw'],
              '',
              'RINGKASAN KEUANGAN',
              'Saldo awal: Rp '.($payload['opening']??0),
              'Penerimaan: Rp '.($payload['income']??0),
              'Pengeluaran: Rp '.($payload['total_expenses']??0),
              'Saldo akhir: Rp '.($payload['closing']??0),
              '',
              'RINCIAN KEGIATAN / PENGELUARAN',
            ];
            foreach(($payload['entries']??[]) as $i=>$entry)if(is_array($entry)){
                $lines[]=($i+1).'. '.($entry['activity']??'').' — Rp '.($entry['amount']??0);
                if(!empty($entry['notes']))$lines[]='     Keterangan: '.$entry['notes'];
            }
            $lines[]='';$lines[]='RIWAYAT PEMERIKSAAN';
            foreach($doc['approvals'] as $approval){
                $lines[]=$approval['duty'].' | '.$approval['action'].' | '.$approval['created_at'];
                if($approval['notes']!=='')$lines[]='Catatan: '.$approval['notes'];
            }
            $lines[]='';
            $lines[]='Kolom tanda tangan basah petugas berwenang: ______________________________';
            $lines[]='Dokumen cetak ini bukan tanda tangan elektronik (TTE) tersertifikasi.';
            require_once __DIR__.'/pdf_native.php';
            cikoko_pdf_render('Cikoko-LPJ-'.$id.'.pdf',$lines);
        }
        $required=cikoko_civic_required_duty($row);
        if($required===''||$duty!==$required||$row['user_id']===$uid)
            mobile_error('Tidak berwenang menyetujui LPJ pada tahap ini.',403);
        $decision=(string)($body['decision']??'');
        if(!in_array($decision,['approve','return'],true))
            mobile_error('Keputusan LPJ tidak dikenal.',422);
        $notes=mobile_text($body['notes']??'',900);
        if($decision==='return'&&mobile_strlen($notes)<5)
            mobile_error('Alasan pengembalian minimal lima karakter.',422);
        if($decision==='approve'){
            $pin=(string)($body['pin']??'');
            $q=$db->prepare('SELECT pin_hash FROM mobile_civic_pins WHERE user_id=?');
            $q->execute([$uid]);$hash=$q->fetchColumn();
            if(!is_string($hash)||!preg_match('/^[0-9]{6}$/D',$pin)||!password_verify($pin,$hash))
                mobile_error('PIN persetujuan tidak sesuai.',403);
        }
        $status=$decision==='return'?'dikembalikan':
            ($row['status']==='menunggu_ketua'?'menunggu_bendahara':'selesai');
        $q=$db->prepare('UPDATE mobile_civic_lpj SET status=? WHERE id=? AND status=?');
        $q->execute([$status,$id,$row['status']]);
        if($q->rowCount()!==1)mobile_error('Status LPJ telah berubah, muat ulang halaman.',409);
        $q=$db->prepare('INSERT INTO mobile_civic_approvals(lpj_id,user_id,duty,action,notes)
           VALUES(?,?,?,?,?)');
        $q->execute([$id,$uid,$duty,$decision,$notes]);
        mobile_emit('laporan','Status LPJ diperbarui','LPJ '.$row['period'].' sekarang '.$status.'.',
          'personal',(string)$row['user_id']);
        mobile_json(['ok'=>true,'status'=>$status]);
    }
    mobile_error('Aksi LPJ tidak tersedia.',404);
}
