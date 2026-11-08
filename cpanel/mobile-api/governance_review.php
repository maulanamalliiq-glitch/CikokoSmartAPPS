<?php
declare(strict_types=1);
// Included only after authentication by index.php. No public report access.
function cikoko_gov_sources():array {
 return ['report'=>'mobile_reports','ppsu'=>'mobile_ppsu_reports','fkdm'=>'mobile_fkdm_reports','waris'=>'aw_applications','lpj'=>'cikoko_lpj_docs'];
}
function cikoko_gov_columns(PDO $db,string $table):array {
 if(!in_array($table,array_values(cikoko_gov_sources()),true))return [];
 if($db->getAttribute(PDO::ATTR_DRIVER_NAME)==='sqlite'){
  $rows=$db->query('PRAGMA table_info('.$table.')')->fetchAll(PDO::FETCH_ASSOC);
  return array_column($rows,'name');
 }
 $q=$db->prepare('SELECT COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=?');
 $q->execute([$table]);return $q->fetchAll(PDO::FETCH_COLUMN);
}
function cikoko_gov_schema(PDO $db):void {
 if($db->getAttribute(PDO::ATTR_DRIVER_NAME)==='sqlite'){
  $db->exec('CREATE TABLE IF NOT EXISTS mobile_officer_reviews(id INTEGER PRIMARY KEY AUTOINCREMENT,source TEXT NOT NULL,report_id INTEGER NOT NULL,status TEXT NOT NULL,notes TEXT NOT NULL,actor_id TEXT NOT NULL,revision INTEGER NOT NULL DEFAULT 0,created_at TEXT DEFAULT CURRENT_TIMESTAMP)');
 }else{
  $db->exec('CREATE TABLE IF NOT EXISTS mobile_officer_reviews(id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,source VARCHAR(16) NOT NULL,report_id BIGINT UNSIGNED NOT NULL,status VARCHAR(20) NOT NULL,notes TEXT NOT NULL,actor_id VARCHAR(80) NOT NULL,revision INT UNSIGNED NOT NULL DEFAULT 0,created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,INDEX idx_report(source,report_id,id)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
 }
}
function cikoko_gov_latest(PDO $db):array {
 cikoko_gov_schema($db);$latest=[];
 foreach($db->query('SELECT source,report_id,status,notes,actor_id,revision,created_at FROM mobile_officer_reviews ORDER BY id') as $r)$latest[$r['source'].':'.$r['report_id'].':'.$r['revision']]=$r;
 return $latest;
}
function cikoko_gov_area($value):string {
 $v=is_scalar($value)?trim((string)$value):'';
 return preg_match('/^[0-9]{1,3}$/D',$v) && (int)$v>0 && (int)$v<=99?str_pad((string)(int)$v,2,'0',STR_PAD_LEFT):'';
}
function cikoko_gov_accounts():array {
 $accounts=[];
 foreach(db_read('portal_users') as $user){
  if(!is_array($user))continue;
  $accounts[(string)($user['id']??'')]=['rt'=>cikoko_gov_area($user['rt']??''),'rw'=>cikoko_gov_area($user['rw']??'')];
 }
 return $accounts;
}
function cikoko_gov_collect(PDO $db,bool $includeWaris=false):array {
 $latest=cikoko_gov_latest($db);$areas=cikoko_area_snapshots($db);$items=[];$sources=[];
 foreach(cikoko_gov_sources() as $source=>$table){
  if($source==='waris'&&!$includeWaris)continue;
  $cols=cikoko_gov_columns($db,$table);$sources[$source]=(bool)$cols;
  if(!$cols)continue;
  $sql='SELECT * FROM '.$table.(in_array('deleted_at',$cols,true)?' WHERE deleted_at IS NULL':'');
  foreach($db->query($sql) as $r){
   $id=(int)$r['id'];$owner=(string)($r[$source==='waris'?'account_id':($source==='lpj'?'owner_id':'user_id')]??'');
   $area=$source==='lpj'?['rt'=>cikoko_gov_area($r['rt']??''),'rw'=>cikoko_gov_area($r['rw']??'')]:($areas[$source.':'.$id]??['rt'=>'','rw'=>'']);
   $review=$latest[$source.':'.$id.':'.($source==='lpj'?(int)($r['revision']??1):0)]??[];
   $category=in_array($source,['report','lpj'],true)?(string)($r['kind']??'kegiatan'):$source;
   $items[]=['id'=>$id,'source'=>$source,'category'=>$category,
    'name'=>(string)($r['user_name']??$r['name']??$r['full_name']??$r['owner_name']??$r['applicant_name']??''),
    'title'=>$source==='waris'?(string)($r['reference_no']??'Ahli Waris'):ucwords(str_replace('_',' ',$category)),
    'status'=>(string)(in_array($source,['report','waris'],true)?($r['status']??'masuk'):($review['status']??'masuk')),
    'created_at'=>(string)($r['created_at']??''),'rt'=>$area['rt'],'rw'=>$area['rw']];
  }
 }
 usort($items,static fn($a,$b)=>strcmp($b['created_at'],$a['created_at']) ?: $b['id']<=>$a['id']);
 return ['items'=>$items,'sources'=>$sources];
}
function cikoko_gov_load(PDO $db,string $source,int $id):array {
 $table=cikoko_gov_sources()[$source]??null;
 if(!$table||$source==='waris'||$id<1)mobile_error('Laporan tidak ditemukan.',404);
 $cols=cikoko_gov_columns($db,$table);if(!$cols)mobile_error('Layanan laporan belum tersedia.',404);
 $q=$db->prepare('SELECT * FROM '.$table.' WHERE id=?'.(in_array('deleted_at',$cols,true)?' AND deleted_at IS NULL':'').($db->inTransaction()&&$db->getAttribute(PDO::ATTR_DRIVER_NAME)==='mysql'?' FOR UPDATE':''));
 $q->execute([$id]);$row=$q->fetch(PDO::FETCH_ASSOC);
 if(!$row)mobile_error('Laporan tidak ditemukan.',404);
 return $row;
}
function cikoko_gov_photos(array $row,string $source):array {
 if($source==='lpj')return [];
 if($source==='report')return empty($row['photo_name'])?[]:[(string)$row['photo_name']];
 $photos=json_decode((string)($row['photos_json']??'[]'),true);
 return is_array($photos)?array_values(array_filter($photos,'is_string')):[];
}
function cikoko_gov_decide(PDO $db,array $u,array $body):array {
 mobile_need($u,'reports:verify');mobile_need($u,'reports:view');
 $source=(string)($body['source']??'');$id=(int)($body['id']??0);
 $status=(string)($body['status']??'');$notes=mobile_text($body['notes']??'',1500);
 if(!in_array($status,['masuk','proses','revisi','selesai','ditolak'],true))mobile_error('Status laporan tidak valid.',422);
 if(in_array($status,['revisi','ditolak'],true)&&$notes==='')mobile_error('Mohon isi catatan untuk permintaan perbaikan atau penolakan.',422);
 cikoko_gov_schema($db);
 $db->beginTransaction();
 try{
  $row=cikoko_gov_load($db,$source,$id);
  if($source==='lpj' && (int)($body['revision']??0)!==(int)($row['revision']??1))mobile_error('LPJ telah diperbarui. Silakan buka ulang rincian sebelum melakukan verifikasi.',409);
  if($source==='report')$db->prepare('UPDATE mobile_reports SET status=? WHERE id=?')->execute([$status,$id]);
  $db->prepare('INSERT INTO mobile_officer_reviews(source,report_id,status,notes,actor_id,revision) VALUES(?,?,?,?,?,?)')->execute([$source,$id,$status,$notes,(string)$u['user_id'],$source==='lpj'?(int)($row['revision']??1):0]);
  $db->commit();
 }catch(Throwable $e){if($db->inTransaction())$db->rollBack();throw $e;}
 mobile_emit('progres_laporan','Status laporan diperbarui','Status laporan: '.ucfirst($status).($notes!==''?'. '.$notes:''),'personal',(string)($row[$source==='lpj'?'owner_id':'user_id']));
 return ['ok'=>true,'message'=>'Hasil verifikasi laporan berhasil disimpan.'];
}
function cikoko_governance_dispatch(string $action,string $method,PDO $db,array $u):void {
 if($action==='support_admin_thread'){
  mobile_need($u,'chat:reply');
  if($method!=='GET')mobile_error('Metode tidak diperbolehkan.',405);
  $target=mobile_text($_GET['user_id']??'',80);
  if($target==='')mobile_error('Pilih percakapan warga.',422);
  mobile_json(cikoko_chat_page($db,$target));
 }
 if($action==='territory_monitoring'){
  mobile_need($u,'monitoring:view');if($method!=='GET')mobile_error('Metode tidak diperbolehkan.',405);
  $all=cikoko_gov_collect($db,true);$areas=[];$statuses=[];$categories=[];$total=0;
  foreach($all['items'] as $r){
   if($r['source']==='waris'&&!mobile_can($u,'waris:view'))continue;
   if($r['source']!=='waris'&&!mobile_can($u,'reports:view'))continue;
   $total++;$statuses[$r['status']]=($statuses[$r['status']]??0)+1;
   $categories[$r['category']]=($categories[$r['category']]??0)+1;
   $key=$r['rw'].':'.$r['rt'];
   if(!isset($areas[$key]))$areas[$key]=['rw'=>$r['rw'],'rt'=>$r['rt'],'total'=>0,'pending'=>0,'completed'=>0];
   $areas[$key]['total']++;
   if($r['status']==='selesai')$areas[$key]['completed']++;
   elseif($r['status']!=='ditolak')$areas[$key]['pending']++;
  }
  $areas=array_values($areas);usort($areas,static fn($a,$b)=>strcmp($a['rw'].':'.$a['rt'],$b['rw'].':'.$b['rt']));
  mobile_json(['ok'=>true,'total'=>$total,'statuses'=>(object)$statuses,'categories'=>(object)$categories,'areas'=>$areas,'sources'=>$all['sources'],'area_basis'=>'Wilayah pengajuan baru dicatat saat dikirim. Data lama tanpa catatan wilayah dikelompokkan sebagai belum diketahui. Wilayah LPJ mengikuti dokumen.']);
 }
 if($action==='officer_waris'){
  mobile_need($u,'waris:view');
  if($method!=='GET')mobile_error('Metode tidak diperbolehkan.',405);
  $all=cikoko_gov_collect($db,true);$items=[];
  foreach($all['items'] as $row){
   if($row['source']!=='waris')continue;
   $row['reference']=$row['title'];$row['title']='Ahli Waris';$row['kind']='waris';$items[]=$row;
  }
  mobile_json(['ok'=>true,'items'=>$items]);
 }
 if($action==='officer_report_decide'){
  if($method!=='POST')mobile_error('Metode tidak diperbolehkan.',405);
  mobile_json(cikoko_gov_decide($db,$u,mobile_body()));
 }
 mobile_need($u,'reports:view');
 if($method!=='GET')mobile_error('Metode tidak diperbolehkan.',405);
 if($action==='officer_reports'){
  $all=cikoko_gov_collect($db);$items=$all['items'];
  foreach(['category','status','rt','rw'] as $key){$value=trim((string)($_GET[$key]??''));if($value!=='')$items=array_values(array_filter($items,static fn($r)=>$r[$key]===$value));}
  $offset=max(0,(int)($_GET['offset']??0));$page=array_slice($items,$offset,50);
  mobile_json(['ok'=>true,'items'=>$page,'total'=>count($items),'next_offset'=>$offset+count($page)<count($items)?$offset+count($page):null,'sources'=>$all['sources'],'can_verify'=>mobile_can($u,'reports:verify')]);
 }
 $source=(string)($_GET['source']??'');$id=(int)($_GET['id']??0);$row=cikoko_gov_load($db,$source,$id);$photos=cikoko_gov_photos($row,$source);
 if($action==='officer_report_photo'){
  $index=(int)($_GET['index']??-1);$name=$photos[$index]??'';
  if(!preg_match('/^[a-f0-9]{40}\.(jpg|jpeg|png|webp)$/i',$name))mobile_error('Foto tidak tersedia.',404);
  $dir=realpath(__DIR__.'/private');$path=$dir?realpath($dir.'/'.$name):false;
  if(!$path||dirname($path)!==$dir||!is_file($path))mobile_error('Foto tidak tersedia.',404);
  $mime=(new finfo(FILEINFO_MIME_TYPE))->file($path);
  if(!in_array($mime,['image/jpeg','image/png','image/webp'],true))mobile_error('Foto tidak tersedia.',404);
  header('Content-Type: '.$mime);header('Cache-Control: private, no-store');header('Content-Length: '.filesize($path));readfile($path);exit;
 }
 if($action==='officer_report_detail'){
  cikoko_gov_schema($db);$q=$db->prepare('SELECT status,notes,actor_id,created_at FROM mobile_officer_reviews WHERE source=? AND report_id=? AND revision=? ORDER BY id');$q->execute([$source,$id,$source==='lpj'?(int)($row['revision']??1):0]);$history=$q->fetchAll(PDO::FETCH_ASSOC);
  $last=$history?end($history):[];
  mobile_json(['ok'=>true,'detail'=>['id'=>$id,'source'=>$source,'name'=>$row['user_name']??$row['name']??$row['full_name']??$row['owner_name']??'','category'=>in_array($source,['report','lpj'],true)?($row['kind']??'kegiatan'):$source,'address'=>$row['address']??$row['location']??'','activity'=>$row['notes']??$row['activity']??'','team'=>$row['team']??'','work_date'=>$row['work_date']??$row['created_at']??'','status'=>$source==='report'?($row['status']??'masuk'):($last['status']??'masuk'),'revision'=>$source==='lpj'?(int)($row['revision']??1):0,'photo_count'=>count($photos),'period'=>$row['period']??'','workflow_status'=>$source==='lpj'?($row['status']??''):'','financial'=>$source==='lpj'?(json_decode((string)($row['payload_json']??'{}'),true)?:null):null],'history'=>$history,'can_verify'=>mobile_can($u,'reports:verify')]);
 }
 mobile_error('Layanan tidak ditemukan.',404);
}
