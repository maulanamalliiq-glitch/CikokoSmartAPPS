<?php
declare(strict_types=1);
/**
 * Cikoko SmartApp LPJ API v2513, staged backend.
 * Source of authority: authenticated portal account + active civic_officers appointment.
 * This module does NOT create a certified electronic signature or apply image stamps.
 */
require_once __DIR__.'/territory.php';

function lpj_fail(string $message,int $http=422):void { mobile_error($message,$http); }
function lpj_num($value):int {
    if (!(is_int($value) || (is_string($value) && preg_match('/^[0-9]{1,12}$/D',$value))))
        lpj_fail('Nominal wajib berupa rupiah bulat tanpa tanda baca.');
    $text=(string)$value;
    if(!preg_match('/^[0-9]{1,12}$/D',$text))lpj_fail('Nominal maksimal 12 digit.');
    return (int)$text;
}
function lpj_area($value,bool $required=true):string {
    $s=trim((string)$value);
    if($s==='') { if($required)lpj_fail('Wilayah petugas belum diatur.',403);return ''; }
    if(!preg_match('/^[0-9]{1,3}$/D',$s)||(int)$s<1)lpj_fail('Wilayah petugas tidak valid.',403);
    return str_pad((string)(int)$s,3,'0',STR_PAD_LEFT);
}
function lpj_schema_check(PDO $db):void {
    static $done=false;if($done)return;
    try {
        foreach(['cikoko_lpj_docs','cikoko_lpj_approvals','cikoko_lpj_pins','cikoko_lpj_audit'] as $t) {
            $db->query('SELECT 1 FROM '.$t.' LIMIT 0');
        }
    } catch(Throwable $e) {
        error_log('[lpj_v2513 schema] '.$e->getMessage());
        lpj_fail('Backend LPJ belum disiapkan. Admin perlu mengimpor migrasi LPJ terlebih dahulu.',503);
    }
    $done=true;
}
function lpj_scope(PDO $db,array $u):?array {
    $role=(string)$u['user_role'];$uid=(string)$u['user_id'];
    if(in_array($role,['admin','admin_kelurahan','lurah'],true))
        return ['duty'=>'admin','rt'=>'','rw'=>'','user_id'=>$uid];
    // Khusus Bendahara: mobile_auth() sudah memverifikasi token, status
    // aktif, dan role di portal_users. Ambil penugasan aktif sesuai ID dan
    // jabatan token; jangan bergantung pada pencarian akun kedua.
    // Ketentuan ini tidak mengubah otorisasi RT, RW, LMK atau admin.
    if(in_array($role,['bendahara_rt','bendahara_rw'],true)) {
        $q=$db->prepare('SELECT user_id,duty,rt,rw FROM civic_officers WHERE user_id=? AND duty=? AND active=1 LIMIT 1');
        $q->execute([$uid,$role]);
        $r=$q->fetch();
        if(!$r)return null;
        $rw=lpj_area($r['rw']??null);
        $rt=$role==='bendahara_rt'?lpj_area($r['rt']??null):'';
        return ['duty'=>$role,'rt'=>$rt,'rw'=>$rw,'user_id'=>$uid];
    }
    $p=cikoko_user_by_id($uid);
    if(!$p || empty($p['active']))return null;
    $q=$db->prepare('SELECT user_id,duty,rt,rw FROM civic_officers WHERE user_id=? AND active=1 LIMIT 1');
    $q->execute([$uid]);$r=$q->fetch();
    if($r) {
        $d=(string)$r['duty'];
        if(!in_array($d,['rt','rw','bendahara_rt','bendahara_rw','lmk'],true))return null;
        if($d==='lmk' && $role!=='lmk')return null;
        if($d==='rt' && $role!=='rt')return null;
        if($d==='bendahara_rt' && !in_array($role,['rt','bendahara_rt'],true))return null;
        if($d==='rw' && $role!=='rw')return null;
        if($d==='bendahara_rw' && !in_array($role,['rw','bendahara_rw'],true))return null;
        $rw=lpj_area($r['rw']??null);
        $rt=in_array($d,['rt','bendahara_rt'],true)?lpj_area($r['rt']??null):'';
        return ['duty'=>$d,'rt'=>$rt,'rw'=>$rw,'user_id'=>$uid];
    }
    // LMK role is assigned by admin in portal_users; no self-declared civic office.
    if($role==='lmk') return ['duty'=>'lmk','rt'=>'','rw'=>lpj_area($p['rw']??null),'user_id'=>$uid];
    return null;
}
function lpj_allowed(array $doc,?array $scope,array $u):bool {
    if(!$scope)return false;
    $d=$scope['duty'];$kind=(string)$doc['kind'];
    if($d==='admin')return true;
    if($kind==='lpj_rt')
        return in_array($d,['rt','bendahara_rt'],true)
            && lpj_area($doc['rt'])===$scope['rt'] && lpj_area($doc['rw'])===$scope['rw'];
    if($kind==='lpj_rw')
        return in_array($d,['rw','bendahara_rw'],true) && lpj_area($doc['rw'])===$scope['rw'];
    return in_array($kind,['lpj_lmk_a','lpj_lmk_b'],true)
        && $d==='lmk' && (string)$doc['owner_id']===(string)$u['user_id'];
}
function lpj_doc(PDO $db,int $id):array {
    if($id<1)lpj_fail('ID LPJ tidak valid.');
    $q=$db->prepare('SELECT * FROM cikoko_lpj_docs WHERE id=?');
    $q->execute([$id]);$d=$q->fetch();
    if(!$d)lpj_fail('LPJ tidak ditemukan.',404);
    return $d;
}
function lpj_payload(array $f):array {
    $opening=lpj_num($f['opening']??null);
    $income=lpj_num($f['income']??null);
    $items=$f['entries']??null;
    if(!is_array($items) || count($items)>60)lpj_fail('Maksimal 60 rincian pengeluaran.');
    $clean=[];$spent=0;
    foreach($items as $i=>$e) {
        if(!is_array($e))lpj_fail('Rincian pengeluaran tidak valid.');
        $activity=trim((string)($e['activity']??''));
        $notes=trim((string)($e['notes']??''));
        if(mobile_strlen($activity)<3||mobile_strlen($activity)>180||mobile_strlen($notes)>500)
            lpj_fail('Nama kegiatan 3–180 karakter dan keterangan maksimal 500 karakter.');
        $amount=lpj_num($e['amount']??null);
        $spent+=$amount;$clean[]=['activity'=>$activity,'amount'=>$amount,'notes'=>$notes];
    }
    if($spent>$opening+$income)lpj_fail('Pengeluaran melebihi saldo awal ditambah penerimaan.');
    return ['opening'=>$opening,'income'=>$income,'entries'=>$clean,
        'total_expenses'=>$spent,'closing'=>$opening+$income-$spent];
}
function lpj_send_next(PDO $db,array $doc,string $duty):void {
    try {
        $sql='SELECT user_id,rt,rw FROM civic_officers WHERE duty=? AND active=1';
        $q=$db->prepare($sql);$q->execute([$duty]);
        foreach($q->fetchAll() as $o) {
            if(lpj_area($o['rw']??'',false)!==$doc['rw'])continue;
            if(in_array($duty,['rt','bendahara_rt'],true) && lpj_area($o['rt']??'',false)!==$doc['rt'])continue;
            mobile_emit('lpj','LPJ perlu diperiksa','LPJ '.strtoupper((string)$doc['kind']).' periode '.$doc['period'].' memerlukan pemeriksaan.','personal',(string)$o['user_id']);
        }
    } catch(Throwable $e) {error_log('[lpj notify] '.$e->getMessage());}
}
function lpj_json_doc(array $d):array {
    return ['id'=>(int)$d['id'],'kind'=>$d['kind'],'period'=>$d['period'],
      'rt'=>$d['rt'],'rw'=>$d['rw'],'owner_name'=>$d['owner_name'],
      'status'=>$d['status'],'revision'=>(int)$d['revision'],
      'submitted_at'=>$d['submitted_at'],'finalized_at'=>$d['finalized_at'],
      'payload'=>json_decode((string)$d['payload_json'],true)?:[]];
}
function lpj_api(string $action,string $method,PDO $db,array $u):void {
    lpj_schema_check($db);
    $scope=lpj_scope($db,$u);$uid=(string)$u['user_id'];
    if($action==='civic_catalog' && $method==='GET') {
        $q=$db->prepare('SELECT 1 FROM cikoko_lpj_pins WHERE user_id=? LIMIT 1');$q->execute([$uid]);
        mobile_json(['ok'=>true,'scope'=>$scope,'pin_registered'=>(bool)$q->fetchColumn(),
          'kinds'=>['lpj_rt','lpj_rw','lpj_lmk_a','lpj_lmk_b']]);
    }
    if($action==='civic_list' && $method==='GET') {
        if(!$scope)mobile_json(['ok'=>true,'items'=>[]]);
        if($scope['duty']==='admin') {
            $q=$db->query('SELECT * FROM cikoko_lpj_docs ORDER BY id DESC LIMIT 150');
        } elseif($scope['duty']==='lmk') {
            $q=$db->prepare('SELECT * FROM cikoko_lpj_docs WHERE owner_id=? ORDER BY id DESC LIMIT 150');
            $q->execute([$uid]);
        } elseif(in_array($scope['duty'],['rt','bendahara_rt'],true)){
            $q=$db->prepare("SELECT * FROM cikoko_lpj_docs WHERE kind='lpj_rt' AND rt=? AND rw=? ORDER BY id DESC LIMIT 150");
            $q->execute([$scope['rt'],$scope['rw']]);
        } else {
            $q=$db->prepare("SELECT * FROM cikoko_lpj_docs WHERE kind='lpj_rw' AND rw=? ORDER BY id DESC LIMIT 150");
            $q->execute([$scope['rw']]);
        }
        $items=[];
        foreach($q->fetchAll() as $d)if(lpj_allowed($d,$scope,$u)){
            $v=lpj_json_doc($d);unset($v['payload']);$items[]=$v;
        }
        mobile_json(['ok'=>true,'items'=>$items]);
    }
    if($action==='civic_pin_set' && $method==='POST') {
        if(!$scope || $scope['duty']==='admin')lpj_fail('Hanya petugas penandatangan yang dapat mengatur PIN.',403);
        $b=mobile_body();$pin=(string)($b['pin']??'');$password=(string)($b['current_password']??'');
        if(!preg_match('/^[0-9]{6}$/D',$pin))lpj_fail('PIN harus terdiri dari 6 angka.');
        $person=cikoko_user_by_id($uid);
        if(!$person || $password==='' || !password_verify($password,(string)($person['password_hash']??'')))
            lpj_fail('Password akun tidak sesuai.',403);
        $hash=password_hash($pin,PASSWORD_DEFAULT);
        $q=$db->prepare('INSERT INTO cikoko_lpj_pins(user_id,pin_hash,failed_attempts,locked_until) VALUES(?,?,0,NULL) ON DUPLICATE KEY UPDATE pin_hash=VALUES(pin_hash),failed_attempts=0,locked_until=NULL');
        $q->execute([$uid,$hash]);mobile_json(['ok'=>true]);
    }
    if($action==='civic_submit' && $method==='POST') {
        $b=mobile_body();$kind=(string)($b['kind']??'');$period=(string)($b['period']??'');
        $required=['lpj_rt'=>'bendahara_rt','lpj_rw'=>'bendahara_rw','lpj_lmk_a'=>'lmk','lpj_lmk_b'=>'lmk'];
        if(!$scope || ($required[$kind]??null)!==$scope['duty'])lpj_fail('Jabatan Anda tidak berwenang mengirim jenis LPJ ini.',403);
        if(!preg_match('/^20[0-9]{2}-(0[1-9]|1[0-2])$/D',$period))lpj_fail('Periode harus YYYY-MM.');
        $fields=$b['fields']??null;if(!is_array($fields))lpj_fail('Rincian LPJ wajib diisi.');
        $payload=lpj_payload($fields);$json=json_encode($payload,JSON_UNESCAPED_UNICODE|JSON_THROW_ON_ERROR);
        $digest=hash('sha256',$json);$rt=$kind==='lpj_rt'?$scope['rt']:'';$rw=$scope['rw'];
        $person=cikoko_user_by_id($uid);$owner=mobile_text($person['name']??$u['username'],160);
        $status=str_starts_with($kind,'lpj_lmk')?'menunggu_lmk':'menunggu_bendahara';
        $db->beginTransaction();
        try {
            $q=$db->prepare('SELECT * FROM cikoko_lpj_docs WHERE kind=? AND period=? AND rt=? AND rw=? AND owner_id=? FOR UPDATE');
            $q->execute([$kind,$period,$rt,$rw,$uid]);$old=$q->fetch();
            if($old) {
                if($old['status']!=='dikembalikan')lpj_fail('LPJ periode ini sudah ada dan tidak dalam status perbaikan.',409);
                $revision=(int)$old['revision']+1;
                $db->prepare('UPDATE cikoko_lpj_docs SET payload_json=?,payload_hash=?,revision=?,status=?,updated_at=NOW(),submitted_at=NOW(),finalized_at=NULL WHERE id=?')
                    ->execute([$json,$digest,$revision,$status,$old['id']]);
                $id=(int)$old['id'];
            } else {
                $revision=1;
                $db->prepare('INSERT INTO cikoko_lpj_docs(kind,period,rt,rw,owner_id,owner_name,status,revision,payload_json,payload_hash) VALUES(?,?,?,?,?,?,?,?,?,?)')
                  ->execute([$kind,$period,$rt,$rw,$uid,$owner,$status,$revision,$json,$digest]);
                $id=(int)$db->lastInsertId();
            }
            $db->prepare('INSERT INTO cikoko_lpj_audit(document_id,revision,actor_id,action,status_after,payload_hash) VALUES(?,?,?,?,?,?)')
               ->execute([$id,$revision,$uid,'submit',$status,$digest]);
            $db->commit();
        } catch(Throwable $e) {
            if($db->inTransaction())$db->rollBack();
            if($e instanceof PDOException) {error_log('[lpj submit] '.$e->getMessage());lpj_fail('Gagal menyimpan LPJ. Periksa data atau coba kembali.',503);}
            throw $e;
        }
        if($status==='menunggu_bendahara') {
            $doc=['kind'=>$kind,'period'=>$period,'rt'=>$rt,'rw'=>$rw];
            lpj_send_next($db,$doc,'bendahara_'.($kind==='lpj_rt'?'rt':'rw'));
        }
        mobile_json(['ok'=>true,'id'=>$id,'revision'=>$revision,'status'=>$status],201);
    }
    if(in_array($action,['civic_detail','civic_pdf'],true) && $method==='GET') {
        $id=(int)($_GET['id']??0);$doc=lpj_doc($db,$id);
        if(!lpj_allowed($doc,$scope,$u))lpj_fail('Tidak berwenang melihat dokumen wilayah ini.',403);
        $q=$db->prepare('SELECT duty,officer_name,action,notes,recorded_at AS created_at FROM cikoko_lpj_approvals WHERE document_id=? AND revision=? ORDER BY id ASC');
        $q->execute([$id,$doc['revision']]);$approvals=$q->fetchAll();
        if($action==='civic_detail')mobile_json(['ok'=>true,'item'=>lpj_json_doc($doc)+['approvals'=>$approvals]]);
        lpj_pdf(lpj_json_doc($doc),$approvals);
    }
    if($action==='civic_review' && $method==='POST') {
        $b=mobile_body();$id=(int)($b['id']??0);$decision=(string)($b['decision']??'');
        $notes=trim((string)($b['notes']??''));$pin=(string)($b['pin']??'');
        if(!in_array($decision,['approve','return'],true))lpj_fail('Keputusan tidak dikenal.');
        if($decision==='return' && (mobile_strlen($notes)<5||mobile_strlen($notes)>500))
            lpj_fail('Alasan pengembalian 5–500 karakter.');
        $db->beginTransaction();
        try {
            $q=$db->prepare('SELECT * FROM cikoko_lpj_docs WHERE id=? FOR UPDATE');$q->execute([$id]);$doc=$q->fetch();
            if(!$doc)lpj_fail('Dokumen tidak ditemukan.',404);
            if(!lpj_allowed($doc,$scope,$u))lpj_fail('Tidak berwenang memeriksa dokumen ini.',403);
            $expected=match($doc['status']) {
               'menunggu_bendahara'=>$doc['kind']==='lpj_rt'?'bendahara_rt':'bendahara_rw',
               'menunggu_ketua'=>$doc['kind']==='lpj_rt'?'rt':'rw',
               'menunggu_lmk'=>'lmk',
               default=>'',
            };
            if(!$scope || $expected==='' || $scope['duty']!==$expected)
                lpj_fail('Tahap persetujuan bukan kewenangan akun ini.',403);
            if($decision==='approve') {
                if(!preg_match('/^[0-9]{6}$/D',$pin))lpj_fail('PIN persetujuan harus 6 digit.');
                $q=$db->prepare('SELECT pin_hash,failed_attempts,locked_until FROM cikoko_lpj_pins WHERE user_id=? FOR UPDATE');
                $q->execute([$uid]);$pr=$q->fetch();
                if(!$pr)lpj_fail('Atur PIN LPJ terlebih dahulu.',403);
                if($pr['locked_until']!==null && strtotime($pr['locked_until'])>time())
                    lpj_fail('PIN terkunci sementara. Coba setelah 15 menit.',429);
                if(!password_verify($pin,$pr['pin_hash'])) {
                    $failures=(int)$pr['failed_attempts']+1;
                    $until=$failures>=5?date('Y-m-d H:i:s',time()+900):null;
                    $db->prepare('UPDATE cikoko_lpj_pins SET failed_attempts=?,locked_until=? WHERE user_id=?')
                       ->execute([$failures,$until,$uid]);
                    $db->commit();lpj_fail('PIN tidak sesuai.',403);
                }
                $db->prepare('UPDATE cikoko_lpj_pins SET failed_attempts=0,locked_until=NULL WHERE user_id=?')->execute([$uid]);
            }
            $next=$decision==='return'?'dikembalikan':
                ($doc['status']==='menunggu_bendahara'?'menunggu_ketua':'disahkan');
            $person=cikoko_user_by_id($uid);$name=mobile_text($person['name']??$u['username'],160);
            $db->prepare('INSERT INTO cikoko_lpj_approvals(document_id,revision,duty,officer_user_id,officer_name,action,notes,payload_hash) VALUES(?,?,?,?,?,?,?,?)')
               ->execute([$id,$doc['revision'],$expected,$uid,$name,$decision,$notes,$doc['payload_hash']]);
            $db->prepare("UPDATE cikoko_lpj_docs SET status=?,updated_at=NOW(),finalized_at=IF(?='disahkan',NOW(),NULL) WHERE id=?")
               ->execute([$next,$next,$id]);
            $db->prepare('INSERT INTO cikoko_lpj_audit(document_id,revision,actor_id,action,status_after,notes,payload_hash) VALUES(?,?,?,?,?,?,?)')
               ->execute([$id,$doc['revision'],$uid,$decision,$next,$notes,$doc['payload_hash']]);
            $db->commit();
        } catch(Throwable $e) {
            if($db->inTransaction())$db->rollBack();
            if($e instanceof PDOException){error_log('[lpj review] '.$e->getMessage());lpj_fail('Persetujuan tidak dapat disimpan.',503);}
            throw $e;
        }
        if($next==='menunggu_ketua')
            lpj_send_next($db,['kind'=>$doc['kind'],'period'=>$doc['period'],'rt'=>$doc['rt'],'rw'=>$doc['rw']],$doc['kind']==='lpj_rt'?'rt':'rw');
        if($next==='dikembalikan')mobile_emit('lpj','LPJ perlu diperbaiki','LPJ periode '.$doc['period'].' dikembalikan untuk perbaikan.','personal',(string)$doc['owner_id']);
        mobile_json(['ok'=>true,'id'=>$id,'status'=>$next]);
    }
    lpj_fail('Aksi LPJ tidak tersedia.',404);
}
/** Minimal A4 PDF without vendor dependencies. Approval is an audit entry, NOT a certified TTE. */
function lpj_pdf(array $d,array $approvals):void {
    $p=$d['payload'];$kind=$d['kind'];$period=$d['period'];
    $title=match($kind) {
        'lpj_rt','lpj_rw'=>'LAPORAN PENGGUNAAN UANG PENYELENGGARAAN TUGAS DAN FUNGSI RUKUN TETANGGA DAN RUKUN WARGA',
        'lpj_lmk_a'=>'LAPORAN PENGGUNAAN BIAYA OPERASIONAL LMK',
        default=>'LAPORAN PENGGUNAAN BIAYA KEGIATAN SESUAI TUGAS LMK',
    };
    $type=match($kind) {'lpj_rt'=>'RT '.$d['rt'].' / RW '.$d['rw'],'lpj_rw'=>'RW '.$d['rw'],default=>'LMK Kelurahan Cikoko'};
    $money=static fn($n):string=>'Rp '.number_format((int)$n,0,',','.');
    $lines=[
        $title,'',
        'BULAN & TAHUN : '.$period,
        'WILAYAH      : '.$type,
        'KELURAHAN    : CIKOKO',
        'KECAMATAN    : PANCORAN',
        'KOTA ADM     : JAKARTA SELATAN','',
        'NO     KEGIATAN                                                  JUMLAH',
        'I.     SALDO BULAN LALU                                  '.$money($p['opening']),
        'II.    PENERIMAAN BULAN INI                               '.$money($p['income']),
        '       JUMLAH PENERIMAAN                                 '.$money($p['opening']+$p['income']),
        'III.   PENGELUARAN',
    ];
    foreach($p['entries'] as $i=>$e) {
        $parts=explode("\n",wordwrap(($i+1).'. '.$e['activity'],55,"\n",true));
        foreach($parts as $j=>$part)$lines[]='       '.$part.($j===0?'    '.$money($e['amount']):'');
        if($e['notes']!=='')foreach(explode("\n",wordwrap('Ket: '.$e['notes'],72,"\n",true)) as $note)$lines[]='          '.$note;
    }
    array_push($lines,'',
        'JUMLAH PENGELUARAN: '.$money($p['total_expenses']),
        'SISA UANG / SALDO BULAN BERIKUTNYA: '.$money($p['closing']),'');
    $approved=$d['status']==='disahkan';
    $lines[]=$approved?'STATUS: DISETUJUI SISTEM':'DRAF - BELUM DISAHKAN';
    foreach($approvals as $a)if($a['action']==='approve')
        $lines[]='Persetujuan '.$a['duty'].': '.$a['officer_name'].' ('.$a['created_at'].')';
    if(!$approvals)$lines[]='Belum ada persetujuan petugas.';
    $lines[]='Dokumen ID '.$d['id'].' | Revisi '.$d['revision'].' | Kelurahan Cikoko';
    $lines[]='Verifikasi PIN internal; BUKAN tanda tangan elektronik tersertifikasi.';
    $pages=array_chunk($lines,43);
    $objects=[];
    $objects[1]='<< /Type /Catalog /Pages 2 0 R >>';
    $objects[3]='<< /Type /Font /Subtype /Type1 /BaseFont /Courier /Encoding /WinAnsiEncoding >>';
    $pageIds=[];$next=4;
    foreach($pages as $pageNo=>$pageLines) {
        $pid=$next++;$cid=$next++;$pageIds[]=$pid;
        $stream="";$y=797;
        foreach($pageLines as $line) {
            $encoded=iconv('UTF-8','Windows-1252//TRANSLIT',(string)$line);
            if($encoded===false)$encoded='';
            $escaped=str_replace(['\\','(',')',"\r","\n"],['\\\\','\\(','\\)','',''],(string)$encoded);
            $stream.="BT /F1 8.5 Tf 37 ".$y." Td (".$escaped.") Tj ET\n";
            $y-=17;
        }
        $stream.='BT /F1 8 Tf 37 35 Td (Halaman '.($pageNo+1).' / '.count($pages).') Tj ET'."\n";
        $objects[$pid]='<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 3 0 R >> >> /Contents '.$cid.' 0 R >>';
        $objects[$cid]='<< /Length '.strlen($stream)." >>\nstream\n".$stream."endstream";
    }
    $objects[2]='<< /Type /Pages /Count '.count($pageIds).' /Kids ['.implode(' ',array_map(static fn($i)=>$i.' 0 R',$pageIds)).'] >>';
    ksort($objects);
    $out="%PDF-1.4\n";$offset=[0];$max=max(array_keys($objects));
    for($i=1;$i<=$max;$i++){$offset[$i]=strlen($out);$out.=$i." 0 obj\n".$objects[$i]."\nendobj\n";}
    $xref=strlen($out);$out.="xref\n0 ".($max+1)."\n0000000000 65535 f \n";
    for($i=1;$i<=$max;$i++)$out.=sprintf('%010d 00000 n ',$offset[$i])."\n";
    $out.="trailer\n<< /Size ".($max+1)." /Root 1 0 R >>\nstartxref\n".$xref."\n%%EOF";
    header('Content-Type: application/pdf');
    header('Content-Disposition: inline; filename="Cikoko-LPJ-'.$d['id'].'.pdf"');
    header('Content-Length: '.strlen($out));
    echo $out;exit;
}
