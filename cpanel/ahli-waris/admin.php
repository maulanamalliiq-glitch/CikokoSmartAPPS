<?php
declare(strict_types=1);
require __DIR__.'/bootstrap.php';
$user=aw_need_user(true);
$err='';$ok='';$allowed=['masuk','proses','revisi','selesai','ditolak'];
$labels=[];foreach(aw_requirements() as $r)$labels[$r[0]]=$r[1];
function waris_admin_length(string $s):int {return function_exists('mb_strlen')?mb_strlen($s):strlen($s);}
function waris_admin_table_exists(PDO $db,string $name):bool {
    $stmt=$db->prepare('SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=?');
    $stmt->execute([$name]);return (int)$stmt->fetchColumn()>0;
}
function waris_admin_delete(PDO $db,int $id,string $confirm,string $reason,array $actor):array {
    if($id<1)throw new RuntimeException('ID permohonan tidak valid.');
    $reason=trim($reason);
    if(waris_admin_length($reason)<5 || waris_admin_length($reason)>300)throw new RuntimeException('Alasan penghapusan wajib 5–300 karakter.');
    // Prepare audit metadata before the transaction: MySQL DDL performs implicit commits.
    $db->exec('CREATE TABLE IF NOT EXISTS aw_deletion_audit (
      id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
      deleted_application_id BIGINT UNSIGNED NOT NULL,
      reference_sha256 CHAR(64) NOT NULL,
      deleted_by VARCHAR(100) NOT NULL,
      reason VARCHAR(300) NOT NULL,
      files_count INT UNSIGNED NOT NULL DEFAULT 0,
      deleted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      INDEX idx_deleted_at(deleted_at)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
    $hasCorrections=waris_admin_table_exists($db,'mobile_waris_corrections');
    $hasEventLinks=waris_admin_table_exists($db,'mobile_event_links');
    $db->beginTransaction();
    try {
        $q=$db->prepare('SELECT id,reference_no FROM aw_applications WHERE id=? FOR UPDATE');
        $q->execute([$id]);$app=$q->fetch(PDO::FETCH_ASSOC);
        if(!$app)throw new RuntimeException('Surat sudah tidak ditemukan. Muat ulang halaman.');
        if($confirm==='' || !hash_equals((string)$app['reference_no'],$confirm))
            throw new RuntimeException('Konfirmasi gagal: nomor surat yang diketik tidak sama persis.');
        $q=$db->prepare('SELECT storage_name FROM aw_attachments WHERE application_id=?');
        $q->execute([$id]);$names=$q->fetchAll(PDO::FETCH_COLUMN);
        $eventIds=[];
        if($hasEventLinks){
            $q=$db->prepare('SELECT event_id FROM mobile_event_links WHERE object_type=? AND object_id=?');
            $q->execute(['waris',$id]);$eventIds=array_map('intval',$q->fetchAll(PDO::FETCH_COLUMN));
            $db->prepare('DELETE FROM mobile_event_links WHERE object_type=? AND object_id=?')->execute(['waris',$id]);
        }
        if($eventIds && waris_admin_table_exists($db,'mobile_events')){
            $placeholders=implode(',',array_fill(0,count($eventIds),'?'));
            $db->prepare('DELETE FROM mobile_events WHERE id IN ('.$placeholders.')')->execute($eventIds);
        }
        if($hasCorrections)$db->prepare('DELETE FROM mobile_waris_corrections WHERE application_id=?')->execute([$id]);
        // Explicitly remove child records, including databases without ON DELETE CASCADE.
        $db->prepare('DELETE FROM aw_history WHERE application_id=?')->execute([$id]);
        $db->prepare('DELETE FROM aw_attachments WHERE application_id=?')->execute([$id]);
        $del=$db->prepare('DELETE FROM aw_applications WHERE id=?');$del->execute([$id]);
        if($del->rowCount()!==1)throw new RuntimeException('Surat tidak dapat dihapus.');
        $db->prepare('INSERT INTO aw_deletion_audit(deleted_application_id,reference_sha256,deleted_by,reason,files_count) VALUES(?,?,?,?,?)')
            ->execute([$id,hash('sha256',(string)$app['reference_no']),(string)$actor['id'],$reason,count($names)]);
        $db->commit();
    }catch(Throwable $e){if($db->inTransaction())$db->rollBack();throw $e;}
    // Physical files are deleted ONLY after the database transaction succeeds.
    $dir=realpath(__DIR__.'/private/uploads');$failed=0;$removed=0;$failedNames=[];
    foreach($names as $filename){
        $filename=(string)$filename;
        if(!$dir || !preg_match('/^[a-f0-9]{40}\.(?:jpg|jpeg|png|webp)$/i',$filename)){$failed++;$failedNames[]=$filename;continue;}
        $real=realpath($dir.DIRECTORY_SEPARATOR.$filename);
        if($real===false)continue; // Already removed or moved: no stray private file remains at its expected path.
        if(dirname($real)!==$dir || !is_file($real) || !@unlink($real)){$failed++;$failedNames[]=$filename;continue;}
        $removed++;
    }
    if($failed>0)error_log('Cikoko Waris deletion: orphaned attachment files for application #'.$id.' count='.$failed.' storage_names='.implode(',', $failedNames));
    return [$removed,$failed];
}

if(($_SERVER['REQUEST_METHOD']??'GET')==='POST'){
    $db=null;
    try{
        aw_check();$id=(int)($_POST['id']??0);
        if($id<1)throw new RuntimeException('ID permohonan tidak valid.');
        $action=(string)($_POST['action']??'status');
        $db=aw_db();
        if($action==='delete'){
            if(($_POST['delete_ack']??'')!=='yes')throw new RuntimeException('Centang pernyataan hapus permanen terlebih dahulu.');
            [$removed,$failed]=waris_admin_delete($db,$id,trim((string)($_POST['reference_confirm']??'')),(string)($_POST['delete_reason']??''),$user);
            $ok='Pengajuan dan data terkait berhasil dihapus permanen. '.($failed?'Perhatian: '.$failed.' file lampiran perlu dibersihkan manual melalui cPanel.':'File lampiran juga telah dibersihkan.');
        }else{
            $db->exec('CREATE TABLE IF NOT EXISTS mobile_waris_corrections (id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,application_id BIGINT UNSIGNED NOT NULL,requirement_code VARCHAR(40) NOT NULL,reason VARCHAR(1000) NOT NULL,requested_by VARCHAR(100) NOT NULL,requested_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,resolved_at DATETIME NULL,UNIQUE KEY uq_application_code(application_id,requirement_code),INDEX idx_pending(application_id,resolved_at)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
            $db->beginTransaction();
            $s=$db->prepare('SELECT id,account_id,status,children_json,reference_no FROM aw_applications WHERE id=? FOR UPDATE');
            $s->execute([$id]);$app=$s->fetch();if(!$app)throw new RuntimeException('Pengajuan tidak ditemukan.');
            $note=trim((string)($_POST['notes']??''));
            if(waris_admin_length($note)>1000)throw new RuntimeException('Catatan terlalu panjang.');
            if($action==='correction'){
                $children=json_decode((string)$app['children_json'],true);
                $number=min(10,count(is_array($children)?$children:[]));
                $choices=$labels;for($n=1;$n<=$number;$n++)$choices['child_'.$n]='Dokumen anak ke-'.$n;
                $codes=$_POST['missing']??[];
                if(!is_array($codes)||!$codes||count($codes)>18||waris_admin_length($note)<5)throw new RuntimeException('Pilih dokumen yang kurang dan isi catatan minimal 5 karakter.');
                foreach($codes as $code)if(!is_string($code)||!isset($choices[$code]))throw new RuntimeException('Kode dokumen tidak dikenal.');
                if(in_array($app['status'],['selesai','ditolak'],true))throw new RuntimeException('Permohonan telah ditutup.');
                $q=$db->prepare('INSERT INTO mobile_waris_corrections(application_id,requirement_code,reason,requested_by,requested_at,resolved_at) VALUES(?,?,?,?,NOW(),NULL) ON DUPLICATE KEY UPDATE reason=VALUES(reason),requested_by=VALUES(requested_by),requested_at=NOW(),resolved_at=NULL');
                foreach(array_unique($codes) as $code)$q->execute([$id,$code,$note,(string)$user['id']]);
                $status='revisi';
            }elseif($action==='status'){
                $status=(string)($_POST['status']??'');if(!in_array($status,$allowed,true))throw new RuntimeException('Status tidak valid.');
            }else throw new RuntimeException('Tindakan tidak dikenal.');
            $db->prepare('UPDATE aw_applications SET status=?,staff_notes=? WHERE id=?')->execute([$status,$note,$id]);
            $db->prepare('INSERT INTO aw_history(application_id,previous_status,new_status,actor_id,notes) VALUES(?,?,?,?,?)')->execute([$id,$app['status'],$status,(string)$user['id'],$note]);
            $db->commit();
            try{
                require_once dirname(__DIR__).'/mobile-api/bootstrap.php';
                require_once dirname(__DIR__).'/mobile-api/waris_review.php';
                waris_review_schema($db);
                waris_emit_link($db,'waris',$id,'progres_surat',$action==='correction'?'Dokumen Ahli Waris perlu diperbaiki':'Progres Ahli Waris: '.ucfirst($status),$note?:'Periksa perkembangan surat di aplikasi','personal',(string)$app['account_id']);
            }catch(Throwable $e){error_log('Cikoko waris event: '.$e->getMessage());}
            $ok=$action==='correction'?'Permintaan perbaikan berhasil dikirim.':'Status berhasil diperbarui.';
        }
    }catch(Throwable $e){if($db instanceof PDO && $db->inTransaction())$db->rollBack();$err=$e->getMessage();}
}
$db=aw_db();
$q=$db->query('SELECT id,reference_no,applicant_name,applicant_phone,deceased_name,status,created_at,staff_notes,children_json FROM aw_applications ORDER BY created_at DESC LIMIT 200');
$rows=$q->fetchAll();
$statusLabels=['masuk'=>'Masuk','proses'=>'Diproses','revisi'=>'Perlu Perbaikan','selesai'=>'Selesai','ditolak'=>'Ditolak'];
?><!doctype html><html lang="id"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Verifikasi Ahli Waris</title><link rel="stylesheet" href="style.css"><style>
:root{color-scheme:light}body{background:#f1f6fb;color:#173653;font:13px/1.45 system-ui,-apple-system,Segoe UI,Arial,sans-serif}.wrap{width:100%;max-width:none;margin:0;padding:13px}.hero{padding:13px 16px;border-radius:12px;background:#115e4d;display:flex;align-items:center;justify-content:space-between;gap:12px}.hero h1{font:700 19px/1.2 system-ui,sans-serif;margin:0 0 3px}.hero p{font-size:11px;opacity:.9}.hero .count{background:#ffffff22;color:#fff;font-size:12px;padding:5px 10px;border-radius:999px;white-space:nowrap}.panel{padding:8px 11px;border-radius:12px;margin-top:10px;box-shadow:none}.table-search{display:flex;align-items:center;gap:8px;justify-content:flex-end;padding:3px 2px 9px}.table-search input{border:1px solid #d0ddea;border-radius:8px;padding:7px 10px;font:inherit;max-width:310px;width:100%}.table-wrap{overflow-x:auto}table{width:100%;min-width:720px;border-collapse:collapse}th,td{text-align:left;vertical-align:top;padding:10px 8px;border-bottom:1px solid #e8eef5;font-size:12px}th{background:#eaf2f0;color:#204a4a;font-weight:750;font-size:11px}td:nth-child(2){width:auto}td:nth-child(4){width:220px}.ref{font-size:11px;font-weight:750;line-height:1.4;overflow-wrap:anywhere;color:#143954}.muted{color:#637b90;font-size:11px}.primary-text{font-weight:700;color:#183c59}.tag{display:inline-block;border-radius:999px;padding:4px 8px;font-size:10px;font-weight:700;background:#e6f0fd;color:#155aa1}.tag.proses{background:#fff3d9;color:#8a5500}.tag.selesai{background:#e0f7e8;color:#137342}.tag.revisi{background:#fff0d4;color:#995200}.tag.ditolak{background:#ffe9e9;color:#b72727}.tools{display:flex;gap:5px;flex-wrap:wrap;align-items:center}.btn{border:1px solid #226bd0;color:#fff;background:#216fd5;font-size:11px;font-weight:700;padding:7px 10px;border-radius:8px;text-decoration:none;display:inline-flex;align-items:center;justify-content:center;cursor:pointer;white-space:nowrap;min-height:30px}.btn.alt{background:#fff;color:#175cab;border-color:#c9dbef}.btn.danger{background:#b92b35;border-color:#b92b35}.btn:focus-visible,summary:focus-visible,input:focus-visible{outline:3px solid #7bb4ff;outline-offset:2px}.action-panel{border:1px solid #dae5f0;border-radius:9px;margin-top:6px;padding:0;background:#fafcff}.action-panel summary{font-size:11px;font-weight:700;color:#19578e;cursor:pointer;padding:7px 9px}.action-panel[open] summary{border-bottom:1px solid #e5edf8}.action-body{padding:9px;display:grid;gap:7px}.action-body .grid2{display:grid;grid-template-columns:1fr auto;gap:6px}.action-body input:not([type=checkbox]),.action-body textarea,.action-body select{border:1px solid #d0ddea;background:#fff;width:100%;min-width:0;min-height:31px;border-radius:7px;padding:6px 8px;font:inherit}.action-body textarea{resize:vertical;min-height:58px}.checks{display:grid;grid-template-columns:repeat(auto-fit,minmax(130px,1fr));gap:5px}.checks label{display:flex;gap:6px;align-items:flex-start;font-size:11px;line-height:1.25}.delete-panel{border-color:#f3b9bd;background:#fffafa}.delete-panel summary{color:#a72731}.warning{color:#9e292d;font-size:11px}.alert{margin:6px 0 10px}.alert.error{background:#fff0f0;color:#ae2424}.alert.ok{background:#e2f8e8;color:#145d38}html{scrollbar-gutter:stable}@media(max-width:680px){.wrap{padding:8px}.hero h1{font-size:17px}.hero{padding:12px}.panel{padding:5px}.tools{align-items:stretch}}
</style></head><body><main class="wrap">
<header class="hero"><div><h1>Verifikasi Ahli Waris</h1><p>Pengajuan, status, dokumen, dan perbaikan warga.</p></div><span class="count"><?=count($rows)?> pengajuan terbaru</span></header>
<?php if($err):?><div class="alert error"><?=aw_e($err)?></div><?php endif;?><?php if($ok):?><div class="alert ok"><?=aw_e($ok)?></div><?php endif;?>
<section class="panel"><div class="table-search"><label for="warisSearch" class="muted">Cari surat / nama:</label><input type="search" id="warisSearch" placeholder="Nomor surat, pemohon, pewaris" autocomplete="off"></div><div class="table-wrap"><table><thead><tr><th style="width:22%">Nomor Surat</th><th>Pemohon / Pewaris</th><th style="width:112px">Status</th><th style="width:230px">Tindakan</th></tr></thead><tbody>
<?php foreach($rows as $r):$rid=(int)$r['id'];$status=(string)$r['status'];?>
<tr><td><div class="ref" title="<?=aw_e($r['reference_no'])?>"><?=aw_e($r['reference_no'])?></div><div class="muted"><?=aw_e(date('d/m/Y H:i',strtotime((string)$r['created_at'])))?></div></td>
<td><div class="primary-text"><?=aw_e($r['applicant_name'])?></div><div class="muted"><?=aw_e($r['applicant_phone'])?></div><div class="muted">Pewaris: <?=aw_e($r['deceased_name'])?></div></td>
<td><span class="tag <?=aw_e($status)?>"><?=aw_e($statusLabels[$status]??ucfirst($status))?></span></td>
<td>
 <div class="tools"><a class="btn" href="detail.php?id=<?=$rid?>">Lihat Detail &amp; Cetak</a></div>
 <details class="action-panel"><summary>Ubah Status / Catatan</summary><form class="action-body" method="post"><input type="hidden" name="action" value="status"><input type="hidden" name="id" value="<?=$rid?>"><input type="hidden" name="csrf" value="<?=aw_e(aw_csrf())?>"><select aria-label="Status" name="status"><?php foreach($allowed as $s):?><option value="<?=aw_e($s)?>" <?=$s===$status?'selected':''?>><?=aw_e($statusLabels[$s]??ucfirst($s))?></option><?php endforeach;?></select><textarea name="notes" maxlength="1000" placeholder="Catatan petugas"><?=aw_e($r['staff_notes'])?></textarea><button class="btn" type="submit">Simpan Status</button></form></details>
 <?php if(!in_array($status,['selesai','ditolak'],true)):?>
 <details class="action-panel"><summary>Minta Perbaikan Dokumen</summary><form class="action-body" method="post"><input type="hidden" name="action" value="correction"><input type="hidden" name="id" value="<?=$rid?>"><input type="hidden" name="csrf" value="<?=aw_e(aw_csrf())?>"><div class="checks">
 <?php $choices=$labels;$kids=json_decode((string)$r['children_json'],true);for($n=1;$n<=min(10,count(is_array($kids)?$kids:[]));$n++)$choices['child_'.$n]='Dokumen anak ke-'.$n;foreach($choices as $key=>$label):?><label><input type="checkbox" name="missing[]" value="<?=aw_e($key)?>"><?=aw_e($label)?></label><?php endforeach;?></div><textarea name="notes" required minlength="5" maxlength="1000" placeholder="Jelaskan yang harus diperbaiki"></textarea><button class="btn" type="submit">Kirim Permintaan</button></form></details>
 <?php endif;?>
 <details class="action-panel delete-panel"><summary>Hapus Permanen</summary><form class="action-body delete-form" method="post"><input type="hidden" name="action" value="delete"><input type="hidden" name="id" value="<?=$rid?>"><input type="hidden" name="csrf" value="<?=aw_e(aw_csrf())?>"><p class="warning">Surat, foto, riwayat, dan permintaan perbaikan akan dihapus. Tidak dapat dipulihkan tanpa backup.</p><label style="font-size:11px">Ketik nomor surat untuk konfirmasi</label><input type="text" name="reference_confirm" autocomplete="off" required placeholder="<?=aw_e($r['reference_no'])?>"><textarea name="delete_reason" required minlength="5" maxlength="300" placeholder="Alasan penghapusan (minimal 5 karakter)"></textarea><label class="warning"><input type="checkbox" name="delete_ack" value="yes" required> Saya memahami penghapusan bersifat permanen.</label><button class="btn danger" type="submit">Hapus Surat &amp; Foto</button></form></details>
</td></tr>
<?php endforeach;?><?php if(!$rows):?><tr><td colspan="4" style="text-align:center;padding:22px">Belum ada pengajuan.</td></tr><?php endif;?></tbody></table></div></section></main>
<script>const search=document.getElementById('warisSearch');if(search){search.addEventListener('input',()=>{const query=search.value.trim().toLocaleLowerCase('id');document.querySelectorAll('tbody tr').forEach(row=>{const cells=row.querySelectorAll('td');if(cells.length<4)return;const haystack=Array.from(cells).slice(0,2).map(c=>c.textContent).join(' ').toLocaleLowerCase('id');row.hidden=!!query&&!haystack.includes(query);});});}document.querySelectorAll('.delete-form').forEach(form=>form.addEventListener('submit',e=>{if(!window.confirm('HAPUS PERMANEN surat dan semua lampiran? Tindakan ini tidak dapat dibatalkan.'))e.preventDefault();}));</script></body></html>
