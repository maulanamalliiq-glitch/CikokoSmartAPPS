<?php
declare(strict_types=1);
// Kebijakan akses otoritatif di server. UI mobile tidak boleh menjadi kontrol keamanan tunggal.
function mobile_role_names():array {return [
 'admin'=>'Admin Utama','admin_kelurahan'=>'Admin Kelurahan','lurah'=>'Lurah','asn'=>'ASN / PNS','pppk'=>'PPPK','pjlp'=>'PJLP','ptsp'=>'PTSP','dukcapil'=>'Dukcapil','rt'=>'RT','rw'=>'RW','bendahara_rt'=>'Bendahara RT','bendahara_rw'=>'Bendahara RW','fkdm'=>'FKDM','lmk'=>'LMK','jumantik_rt'=>'Jumantik RT','jumantik_rw'=>'Jumantik RW','dasawisma'=>'Dasawisma','pkk'=>'PKK','posyandu'=>'Posyandu','ppsu'=>'PPSU','warga'=>'Warga'
 ];}
function mobile_permission_keys():array {return ['report:jumantik','report:kegiatan','report:fkdm','report:lmk','report:posyandu','report:pkk','report:kerja_bakti','report:ppsu','reports:view','reports:verify','waris:create','waris:view','waris:verify','content:create','archive:create','archive:view','chat:reply','role:manage'];}
function mobile_default_permissions(string $role):array {
 $base=['warga'=>['report:jumantik','waris:create'],
 'admin_kelurahan'=>['report:kegiatan','reports:view','reports:verify','waris:view','waris:verify','content:create','archive:create','archive:view','chat:reply'],
 'lurah'=>['reports:view','reports:verify','waris:view','waris:verify','archive:view'],
 'asn'=>['report:kegiatan'],
 'ptsp'=>['report:kegiatan','reports:view','reports:verify','waris:view','waris:verify'],
 'dukcapil'=>['report:kegiatan'],
 'pppk'=>['report:kegiatan'],'pjlp'=>['report:kegiatan'],
 'rt'=>['report:kegiatan','report:kerja_bakti'],'rw'=>['report:kegiatan','report:kerja_bakti'],
 'bendahara_rt'=>[], 'bendahara_rw'=>[],
 'fkdm'=>['report:fkdm','report:kegiatan'],'lmk'=>['report:lmk','report:kegiatan'],
 'jumantik_rt'=>['report:jumantik'],'jumantik_rw'=>['report:jumantik'],
 'dasawisma'=>['report:pkk','report:kegiatan'],'pkk'=>['report:pkk','report:kegiatan'],
 'posyandu'=>['report:posyandu','report:kegiatan'],'ppsu'=>['report:ppsu','report:kegiatan','report:kerja_bakti']];
 if($role==='admin')return mobile_permission_keys();
 return $base[$role]??[];
}
function mobile_permission_schema(PDO $db):void {
 static $done=false;if($done)return;
 $db->exec('CREATE TABLE IF NOT EXISTS mobile_role_permissions (role VARCHAR(50) NOT NULL, capability VARCHAR(70) NOT NULL, allowed TINYINT(1) NOT NULL, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, PRIMARY KEY(role,capability)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
 $done=true;
}
function mobile_can(array $user,string $key):bool {
 $role=(string)($user['user_role']??'');
 if($role==='admin')return true;
 if(!in_array($key,mobile_permission_keys(),true))return false;
 if($key==='role:manage')return false; // hak kelola role hanya untuk Admin Utama
 try {
  $db=mobile_db();mobile_permission_schema($db);
  $s=$db->prepare('SELECT allowed FROM mobile_role_permissions WHERE role=? AND capability=?');$s->execute([$role,$key]);$v=$s->fetchColumn();
  if($v!==false)return (int)$v===1;
 }catch(Throwable $e){error_log('Permissions read failed: '.$e->getMessage());return false;}
 return in_array($key,mobile_default_permissions($role),true);
}
function mobile_need(array $user,string $key):void {if(!mobile_can($user,$key))mobile_error('Hak akses ditolak untuk fitur ini',403);}
