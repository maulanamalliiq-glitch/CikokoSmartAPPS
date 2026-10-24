<?php
require __DIR__.'/bootstrap.php';$user=aw_need_user();$error='';$success='';
if($_SERVER['REQUEST_METHOD']==='POST') {try {
 aw_check();$nik=aw_post('nik',16);$pewarisNik=aw_post('deceased_nik',16);$kk=aw_post('deceased_kk',20);
 if(!preg_match('/^[0-9]{16}$/',$nik))throw new RuntimeException('NIK pemohon harus 16 angka.');
 if($pewarisNik!==''&&!preg_match('/^[0-9]{16}$/',$pewarisNik))throw new RuntimeException('NIK pewaris harus 16 angka.');
 foreach(['phone','address','relation','deceased_name','marital_status','heirs'] as $req){if(aw_post($req,12000)==='')throw new RuntimeException('Lengkapi semua kolom wajib.');}
 $children=[];
 foreach(($_POST['child_name']??[]) as $i=>$nm){
  $nm=trim((string)$nm);if($nm==='')continue;
  if(count($children)>=10)throw new RuntimeException('Maksimal 10 anak.');
  $childNo=(int)($_POST['child_index'][$i]??0);if($childNo<1||$childNo>10)throw new RuntimeException('Urutan anak tidak valid.');
  $children[]=['number'=>$childNo,'name'=>mb_substr($nm,0,160),'note'=>mb_substr(trim((string)($_POST['child_note'][$i]??'')),0,300)];
 }
 $items=aw_files_list();aw_uploads_validate($items);
 foreach($children as $i=>$child){$code='child_'.$child['number'];$found=false;foreach($items as $f){if($f['field']===$code){$found=true;break;}}if(!$found)throw new RuntimeException('Foto KTP/KK/Akta lahir anak ke-'.$child['number'].' belum diunggah.');}

 $required=[];foreach(aw_requirements() as $r)if($r[2]==='wajib')$required[$r[0]]=false;
 foreach($items as $f)if(isset($required[$f['field']]))$required[$f['field']]=true;
 foreach($required as $code=>$ok)if(!$ok)throw new RuntimeException('Dokumen wajib belum lengkap: '.substr($code,1));
 if(empty($_POST['declaration']))throw new RuntimeException('Pernyataan persetujuan harus dicentang.');
 $db=aw_db();$stored=[];$db->beginTransaction();try{
  $ref='AW-'.date('Ymd').'-'.strtoupper(bin2hex(random_bytes(4)));
  $sql='INSERT INTO aw_applications (reference_no,account_id,applicant_name,applicant_nik,applicant_phone,applicant_address,relationship,deceased_name,deceased_nik,deceased_kk,marital_status,deceased_birthplace,deceased_birthdate,deceased_deathdate,deceased_marriage_date,heirs,children_json) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)';
  $db->prepare($sql)->execute([$ref,$user['id'],$user['name']?:aw_post('name'),$nik,aw_post('phone',30),aw_post('address',3000),aw_post('relation',100),aw_post('deceased_name'),$pewarisNik?:null,$kk?:null,aw_post('marital_status',30),aw_post('birthplace',160)?:null,aw_post('birthdate',10)?:null,aw_post('deathdate',10)?:null,aw_post('marriage_date',10)?:null,aw_post('heirs',12000),json_encode($children,JSON_UNESCAPED_UNICODE)]);$id=(int)$db->lastInsertId();
  $dir=__DIR__.'/private/uploads';
  $ins=$db->prepare('INSERT INTO aw_attachments (application_id,requirement_code,original_name,storage_name,mime_type,size_bytes) VALUES (?,?,?,?,?,?)');
  foreach($items as $f){$mime=(new finfo(FILEINFO_MIME_TYPE))->file($f['tmp']);$ext=['image/jpeg'=>'jpg','image/png'=>'png','image/webp'=>'webp'][$mime];$file=bin2hex(random_bytes(20)).'.'.$ext;if(!move_uploaded_file($f['tmp'],$dir.'/'.$file))throw new RuntimeException('Penyimpanan lampiran gagal.');$stored[]=$dir.'/'.$file;$ins->execute([$id,preg_match('/^(?:r[1-8]|child_(?:10|[1-9]))$/',$f['field'])?$f['field']:'extra',mb_substr(basename($f['name']),0,255),$file,$mime,(int)$f['size']]);}
  $db->prepare('INSERT INTO aw_history(application_id,previous_status,new_status,actor_id,notes) VALUES (?,NULL,?,?,?)')->execute([$id,'masuk',$user['id'],'Permohonan baru']);$db->commit();try {require_once dirname(__DIR__).'/mobile-api/bootstrap.php';mobile_emit('surat','Permohonan Ahli Waris baru','Nomor '.$ref,'admin');mobile_emit('progres_surat','Surat diterima','Nomor '.$ref,'personal',$user['id']);}catch(Throwable $eventEx){error_log($eventEx->getMessage());}header('Location: index.php?sent='.rawurlencode($ref));exit;
 }catch(Throwable $e){$db->rollBack();foreach($stored as $p)@unlink($p);throw $e;}
} catch(Throwable $e){$error=$e->getMessage();}}
?><!doctype html><html lang="id"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Permohonan Ahli Waris · Cikoko</title><link rel="stylesheet" href="style.css"><link rel="stylesheet" href="compact-warisan.css"></head><body><main class="wrap">
<header class="hero"><small>LAYANAN KELURAHAN CIKOKO</small><h1>Permohonan Pencatatan Ahli Waris</h1><p>Lengkapi identitas dan foto persyaratan. Data dapat ditinjau petugas setelah permohonan dikirim.</p></header><nav class="quick"><a href="../portal.php?tab=dashboard">← Portal Warga</a><a href="../portal.php?tab=history">Riwayat Pengajuan</a></nav>
<?php if($error):?><div class="alert error"><?=aw_e($error)?></div><?php endif;?><?php if(isset($_GET['sent'])):?><div class="alert ok">Permohonan berhasil dikirim. Nomor: <b><?=aw_e($_GET['sent'])?></b></div><?php endif;?>
<form id="warisForm" method="post" enctype="multipart/form-data"><input type="hidden" name="csrf" value="<?=aw_e(aw_csrf())?>">
<section class="panel"><h2>Data Pemohon dan Pewaris</h2><div class="fields">
<label>Nama Pemohon<input name="name" readonly value="<?=aw_e($user['name'])?>"></label>
<label>NIK Pemohon<input name="nik" inputmode="numeric" pattern="[0-9]{16}" minlength="16" maxlength="16" required placeholder="16 digit"></label>
<label>No. HP / WhatsApp<input name="phone" type="tel" required maxlength="30"></label>
<label>Hubungan dengan Pewaris<input name="relation" required placeholder="Anak / Istri / Suami / lainnya"></label>
<label class="wide">Alamat Lengkap<textarea name="address" rows="2" required></textarea></label>
<label>Nama Almarhum / Almarhumah<input name="deceased_name" required></label>
<label>Tempat Lahir Almarhum / Almarhumah<input name="birthplace"></label>
<label>Tanggal Lahir Almarhum / Almarhumah<input type="date" name="birthdate"></label>
<label>Tanggal Menikah Almarhum / Almarhumah<input type="date" name="marriage_date"></label>
<label>Status Perkawinan<select name="marital_status" required><option value="">Pilih status</option><option>Menikah</option><option>Belum menikah</option><option>Cerai hidup</option><option>Cerai mati</option></select></label>
<label>Tanggal Meninggal<input type="date" name="deathdate" required></label>
<label class="wide">Daftar Ahli Waris<textarea name="heirs" rows="3" required placeholder="Nama dan hubungan keluarga setiap ahli waris"></textarea></label>
</div></section>
<section class="panel"><h2>Foto Persyaratan</h2><p class="hint">Pilih Galeri atau Kamera. Gambar berukuran besar dikompresi otomatis sebelum dikirim; teks penting tetap perlu dipastikan terbaca pada pratinjau.</p><div class="requirements">
<?php foreach(aw_requirements() as $i=>$req):?><div class="req-row"><div class="req-text"><b><?=($i+1)?>. <?=aw_e($req[1])?></b><small><?= $req[2]==='wajib'?'Wajib':'Jika berlaku' ?></small></div><div class="photo-actions"><label class="photo-btn">🖼️ Galeri<input class="photo-input" name="<?=$req[0]?>" type="file" accept="image/*" <?=$req[2]==='wajib'?'required':''?>></label><label class="photo-btn">📷 Kamera<input type="file" accept="image/*" capture="environment" data-pair="<?=$req[0]?>"></label><span class="photo-status">Belum dipilih</span></div></div><?php endforeach;?>
</div></section>
<section class="panel"><div class="children-header"><div><h2>Data Anak (hingga 10)</h2><p class="hint">Tambahkan anak sesuai kebutuhan. Setiap anak dilengkapi foto KTP, KK, atau akta lahir.</p></div><button type="button" id="addChild" class="muted-button">+ Tambah Anak</button></div><div id="children"></div></section>
<section class="panel"><h2>Lampiran Tambahan (Opsional)</h2><div id="extras"></div><button type="button" id="addExtra" class="muted-button">+ Tambah Foto</button><p class="hint">Foto yang dikirim akan tersimpan privat dan hanya dapat dilihat pemohon serta petugas berwenang.</p><label class="declaration"><input type="checkbox" name="declaration" value="1" required> Saya menyatakan data dan foto persyaratan benar serta menyetujui pemrosesan permohonan oleh petugas.</label><div class="submitrow"><button type="submit">Kirim Permohonan →</button><span>Nomor pengajuan muncul setelah berhasil dikirim.</span></div></section>
</form></main><div id="uploadOverlay" hidden><div class="upload-dialog"><b id="uploadTitle">Mengunggah permohonan...</b><div class="progress-track"><div id="uploadFill"></div></div><strong id="uploadPct">0%</strong><p id="uploadNote">Jangan tutup halaman selama pengiriman.</p></div></div><script src="waris-ui.js"></script></body></html>
