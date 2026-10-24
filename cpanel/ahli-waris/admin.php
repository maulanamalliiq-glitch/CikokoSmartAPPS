<?php
declare(strict_types=1);
require __DIR__.'/bootstrap.php';
$user=aw_need_user(true);
$err='';$ok='';$allowed=['masuk','proses','revisi','selesai','ditolak'];
$labels=[];foreach(aw_requirements() as $r)$labels[$r[0]]=$r[1];
if(($_SERVER['REQUEST_METHOD']??'GET')==='POST'){
 try {
  aw_check();$id=(int)($_POST['id']??0);if(!$id)throw new RuntimeException('ID permohonan tidak valid.');
  $db=aw_db();
  // MySQL DDL commits implicitly: create the table before opening the transaction.
  $db->exec('CREATE TABLE IF NOT EXISTS mobile_waris_corrections (id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,application_id BIGINT UNSIGNED NOT NULL,requirement_code VARCHAR(40) NOT NULL,reason VARCHAR(1000) NOT NULL,requested_by VARCHAR(100) NOT NULL,requested_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,resolved_at DATETIME NULL,UNIQUE KEY uq_application_code(application_id,requirement_code),INDEX idx_pending(application_id,resolved_at)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
  $db->beginTransaction();
  $s=$db->prepare('SELECT id,account_id,status,children_json,reference_no FROM aw_applications WHERE id=? FOR UPDATE');$s->execute([$id]);$app=$s->fetch();if(!$app)throw new RuntimeException('Pengajuan tidak ditemukan.');
  $action=(string)($_POST['action']??'status');
  $note=aw_post('notes',1000);
  if($action==='correction'){
    $children=json_decode((string)$app['children_json'],true);$number=min(10,count(is_array($children)?$children:[]));
    $choices=$labels;for($n=1;$n<=$number;$n++)$choices['child_'.$n]='Dokumen anak ke-'.$n;
    $codes=$_POST['missing']??[];
    if(!is_array($codes)||!$codes||count($codes)>18||mb_strlen($note)<5)throw new RuntimeException('Pilih dokumen yang kurang dan isi catatan minimal 5 karakter.');
    foreach($codes as $code)if(!is_string($code)||!isset($choices[$code]))throw new RuntimeException('Kode dokumen tidak dikenal.');
    if(in_array($app['status'],['selesai','ditolak'],true))throw new RuntimeException('Permohonan telah ditutup.');
    $q=$db->prepare('INSERT INTO mobile_waris_corrections(application_id,requirement_code,reason,requested_by,requested_at,resolved_at) VALUES(?,?,?,?,NOW(),NULL) ON DUPLICATE KEY UPDATE reason=VALUES(reason),requested_by=VALUES(requested_by),requested_at=NOW(),resolved_at=NULL');
    foreach(array_unique($codes) as $code)$q->execute([$id,$code,$note,$user['id']]);
    $status='revisi';
  }else{
    $status=(string)($_POST['status']??'');if(!in_array($status,$allowed,true))throw new RuntimeException('Status tidak valid.');
  }
  $q=$db->prepare('UPDATE aw_applications SET status=?,staff_notes=? WHERE id=?');$q->execute([$status,$note,$id]);
  $db->prepare('INSERT INTO aw_history(application_id,previous_status,new_status,actor_id,notes) VALUES(?,?,?,?,?)')->execute([$id,$app['status'],$status,$user['id'],$note]);
  $db->commit();
  try{
    require_once dirname(__DIR__).'/mobile-api/bootstrap.php';
    require_once dirname(__DIR__).'/mobile-api/waris_review.php';
    waris_review_schema($db);
    waris_emit_link($db,'waris',$id,'progres_surat',$action==='correction'?'Dokumen Ahli Waris perlu diperbaiki':'Progres Ahli Waris: '.ucfirst($status),$note?:'Periksa perkembangan surat di aplikasi','personal',(string)$app['account_id']);
  }catch(Throwable $e){error_log('Cikoko event for web admin: '.$e->getMessage());}
  $ok=$action==='correction'?'Permintaan dokumen kurang berhasil dikirim.':'Status berhasil disimpan.';
 }catch(Throwable $e){if(isset($db)&&$db->inTransaction())$db->rollBack();$err=$e->getMessage();}
}
$db=aw_db();
$q=$db->query('SELECT id,reference_no,applicant_name,applicant_phone,deceased_name,status,created_at,staff_notes,children_json FROM aw_applications ORDER BY created_at DESC LIMIT 200');$rows=$q->fetchAll();
?><!doctype html><html lang="id"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Verifikasi Ahli Waris</title><link rel="stylesheet" href="style.css">
<style>
body{background:#f3f7fb;font-family:system-ui,-apple-system,sans-serif}.wrap{max-width:1400px}.hero{background:#12614e;padding:18px 22px;border-radius:15px}.hero h1{font-family:inherit;font-size:25px}.panel{padding:14px}table{min-width:820px}td,th{padding:10px;font-size:13px;vertical-align:top}input,select,textarea{font-size:12px}form.inline{display:flex;gap:6px;flex-wrap:wrap;align-items:center}select{width:auto;min-width:105px}.btn{background:#146bd6;color:#fff;border:0;border-radius:8px;padding:9px 12px;cursor:pointer}.btn:focus-visible,summary:focus-visible{outline:2px solid #2b72e9}.missing{margin-top:8px;background:#f1f6ff;border:1px solid #d6e6fc;border-radius:10px;padding:9px}.missing summary{cursor:pointer;font-weight:700;color:#1b569b}.missing form{display:grid;gap:8px;margin-top:10px}.missing .choices{display:grid;grid-template-columns:repeat(auto-fit,minmax(145px,1fr));gap:7px}.missing label{display:flex;gap:5px;align-items:center}.missing textarea{min-height:62px;width:100%;resize:vertical;box-sizing:border-box}.table-wrap{overflow-x:auto}.alert{margin:12px 0}
</style></head><body><main class="wrap"><header class="hero"><h1>Verifikasi Permohonan Ahli Waris</h1><p>Detail pengajuan, permintaan perbaikan dokumen, status, dan catatan petugas.</p></header>
<?php if($err):?><div class="alert error"><?=aw_e($err)?></div><?php endif;?><?php if($ok):?><div class="alert ok"><?=aw_e($ok)?></div><?php endif;?>
<section class="panel"><div class="table-wrap"><table><thead><tr><th>Nomor / Tanggal</th><th>Pemohon</th><th>Pewaris</th><th>Detail</th><th>Status dan Pemeriksaan</th></tr></thead><tbody>
<?php foreach($rows as $r):?>
<tr><td><strong><?=aw_e($r['reference_no'])?></strong><div><?=aw_e($r['created_at'])?></div></td>
<td><?=aw_e($r['applicant_name'])?><div><?=aw_e($r['applicant_phone'])?></div></td>
<td><?=aw_e($r['deceased_name'])?></td>
<td><a href="detail.php?id=<?=(int)$r['id']?>">Lihat data dan foto</a></td>
<td><form class="inline" method="post"><input type="hidden" name="action" value="status"><input type="hidden" name="csrf" value="<?=aw_e(aw_csrf())?>"><input type="hidden" name="id" value="<?=(int)$r['id']?>"><select name="status"><?php foreach($allowed as $s):?><option value="<?=aw_e($s)?>" <?=$s===$r['status']?'selected':''?>><?=aw_e(ucfirst($s))?></option><?php endforeach;?></select><input name="notes" aria-label="Catatan verifikasi" placeholder="Catatan petugas" value="<?=aw_e($r['staff_notes'])?>"><button class="btn" type="submit">Simpan</button></form>
<?php if(!in_array($r['status'],['selesai','ditolak'],true)):?>
<details class="missing"><summary>Minta Warga Melengkapi Dokumen</summary><form method="post"><input type="hidden" name="action" value="correction"><input type="hidden" name="id" value="<?=(int)$r['id']?>"><input type="hidden" name="csrf" value="<?=aw_e(aw_csrf())?>"><div class="choices">
<?php $choices=$labels;$kids=json_decode((string)$r['children_json'],true);for($n=1;$n<=min(10,count(is_array($kids)?$kids:[]));$n++)$choices['child_'.$n]='Dokumen anak ke-'.$n;foreach($choices as $key=>$name):?><label><input type="checkbox" name="missing[]" value="<?=aw_e($key)?>"><?=aw_e($name)?></label><?php endforeach;?></div>
<textarea name="notes" required minlength="5" maxlength="1000" placeholder="Jelaskan foto/dokumen yang perlu diperbaiki" aria-label="Catatan perbaikan"></textarea><button type="submit" class="btn">Kirim Permintaan Perbaikan</button></form></details>
<?php endif;?></td></tr>
<?php endforeach;?><?php if(!$rows):?><tr><td colspan="5">Belum ada pengajuan.</td></tr><?php endif;?></tbody></table></div></section></main></body></html>
