<?php
declare(strict_types=1);
require __DIR__.'/lib.php';
need_admin();
header('Cache-Control: no-store, private');
$errors=[];$notice='';$preview=[];$stats=['pjlp'=>0,'pppk'=>0];$duplicates=[];
if($_SERVER['REQUEST_METHOD']==='POST'){
 csrf_check();
 $action=(string)($_POST['action']??'');
 if($action==='preview'){
  unset($_SESSION['cikoko_employee_import']);
  $f=$_FILES['csv']??null;
  if(!$f||$f['error']!==UPLOAD_ERR_OK||$f['size']>150000||$f['size']<20)$errors[]='Unggah CSV UTF-8 maksimal 150 KB.';
  else{
   $fp=fopen($f['tmp_name'],'rb');$header=fgetcsv($fp);
   if($header){$header=array_map(static fn($s)=>strtolower(trim(preg_replace('/^\xEF\xBB\xBF/','',(string)$s))),$header);}
   $required=['nama','username','role','id_phl','phone','email','password_awal_unik'];
   if(!$header||array_diff($required,$header))$errors[]='Kolom CSV tidak sesuai template pra-impor.';
   else{
    $indices=array_flip($header);$seen=[];$count=0;
    while(($values=fgetcsv($fp))!==false){
     if(count($values)===1&&trim((string)$values[0])==='')continue;
     $count++;if($count>150){$errors[]='Maksimal 150 akun per impor.';break;}
     $row=[];foreach($required as $key)$row[$key]=trim((string)($values[$indices[$key]]??''));
     $username=$row['username'];$role=$row['role'];$password=$row['password_awal_unik'];
     if(mb_strlen($row['nama'])<3||!preg_match('/^[a-zA-Z0-9_.-]{4,40}$/D',$username)||!in_array($role,['pjlp','pppk'],true)||strlen($password)<10||strlen($password)>128||($row['email']!==''&&!filter_var($row['email'],FILTER_VALIDATE_EMAIL))||isset($seen[strtolower($username)])){
      $errors[]='Data tidak valid/duplikat dalam CSV pada baris '.($count+1).'.';continue;
     }
     $seen[strtolower($username)]=true;$preview[]=$row;$stats[$role]++;
    }
   }
   fclose($fp);
   if(!$errors&&$preview){
    $existing=db_read('portal_users');$taken=[];
    foreach($existing as $u)$taken[strtolower((string)($u['username']??''))]=true;
    $admin=db_read('admin');$taken[strtolower((string)($admin['username']??''))]=true;
    foreach($preview as $row)if(isset($taken[strtolower($row['username'])]))$duplicates[]=$row['username'];
    if($duplicates)$errors[]='Ada username yang sudah terdaftar. Impor dibatalkan, tidak menimpa akun lama.';
    else $_SESSION['cikoko_employee_import']=['rows'=>$preview,'created'=>time()];
   }elseif(!$preview)$errors[]='Tidak ada data yang dapat diimpor.';
  }
 }elseif($action==='confirm'){
  $draft=$_SESSION['cikoko_employee_import']??null;
  unset($_SESSION['cikoko_employee_import']);
  if(!is_array($draft)||time()-(int)($draft['created']??0)>900||!is_array($draft['rows']??null))$errors[]='Pratinjau kedaluwarsa. Unggah ulang CSV.';
  else{
   $path=data_path('portal_users');$fp=@fopen($path,'c+');
   if(!$fp||!flock($fp,LOCK_EX)){$errors[]='Penyimpanan akun terkunci.';if($fp)fclose($fp);}
   else{
    $raw=stream_get_contents($fp);$users=json_decode($raw?:'[]',true);$users=is_array($users)?$users:[];
    $taken=[];foreach($users as $u)$taken[strtolower((string)($u['username']??''))]=true;
    $admin=db_read('admin');$taken[strtolower((string)($admin['username']??''))]=true;
    foreach($draft['rows'] as $row)if(isset($taken[strtolower($row['username'])]))$duplicates[]=$row['username'];
    if($duplicates)$errors[]='Username telah digunakan sejak pratinjau. Tidak ada akun ditambahkan.';
    else{
     foreach($draft['rows'] as $row){
      $users[]=['id'=>bin2hex(random_bytes(12)),'name'=>$row['nama'],'username'=>$row['username'],
       'password_hash'=>password_hash($row['password_awal_unik'],PASSWORD_DEFAULT),'role'=>$row['role'],
       'department'=>strtoupper($row['role']),'employee_id'=>$row['id_phl'],'phone'=>$row['phone'],
       'email'=>$row['email'],'rt'=>'','rw'=>'','active'=>true,'password_change_required'=>true,'created_at'=>date('c')];
     }
     $json=json_encode($users,JSON_UNESCAPED_UNICODE|JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES|JSON_THROW_ON_ERROR);
     rewind($fp);
     if(ftruncate($fp,0)&&fwrite($fp,$json)===strlen($json)&&fflush($fp))$notice='Berhasil menambahkan '.count($draft['rows']).' akun. Simpan CSV rahasia untuk distribusi password secara individual.';
     else $errors[]='Gagal menyimpan data akun. Pulihkan backup sebelum mengulangi.';
    }
    flock($fp,LOCK_UN);fclose($fp);
   }
  }
 }
}
if(!$preview&&isset($_SESSION['cikoko_employee_import']['rows']))$preview=$_SESSION['cikoko_employee_import']['rows'];
?><!doctype html><html lang="id"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Impor Pegawai — Cikoko</title><style>body{font:15px system-ui;background:#f3f6fc;color:#172b4d;margin:0}.wrap{max-width:1000px;margin:36px auto;padding:20px}.panel{background:white;padding:26px;border-radius:14px;box-shadow:0 4px 20px #1234}h1{margin-top:0}button{background:#164b9b;color:white;border:0;padding:12px 18px;border-radius:8px;cursor:pointer}input{margin:14px 0}.warn{background:#fff2d8;padding:14px;border-radius:8px}.err{background:#ffe4e4;padding:12px}.ok{background:#e3f7e9;padding:12px}table{width:100%;border-collapse:collapse}th,td{padding:8px;border-bottom:1px solid #ddd;text-align:left}th{background:#edf3ff}.scroll{overflow:auto}small{color:#5b6c81}</style></head><body><main class="wrap"><section class="panel"><p><a href="<?=esc(url('admin.php'))?>">← Dashboard Admin</a></p><h1>Impor Akun PJLP &amp; PPPK</h1><p>Unggah CSV pra-impor, periksa daftar, lalu konfirmasi. Hanya Admin Utama yang dapat mengakses halaman ini.</p><p class="warn"><strong>Keamanan:</strong> Backup folder data sebelum impor. File CSV berisi kata sandi awal; jangan unggah ke GitHub atau bagikan ke grup. Username yang sudah ada tidak akan ditimpa.</p><?php foreach($errors as $error):?><p class="err"><?=esc($error)?></p><?php endforeach;?><?php if($notice):?><p class="ok"><?=esc($notice)?></p><?php endif;?><form method="post" enctype="multipart/form-data"><input type="hidden" name="csrf" value="<?=esc(csrf())?>"><input type="hidden" name="action" value="preview"><label>File CSV UTF-8 <input type="file" name="csv" accept=".csv,text/csv" required></label><button type="submit">Periksa Data</button></form><?php if($preview&&!$errors):?><h2>Pratinjau <?=count($preview)?> akun</h2><p>PPPK: <?=count(array_filter($preview,static fn($r)=>$r['role']==='pppk'))?> | PJLP: <?=count(array_filter($preview,static fn($r)=>$r['role']==='pjlp'))?></p><div class="scroll"><table><thead><tr><th>Nama</th><th>Username</th><th>Peran</th><th>ID PHL</th></tr></thead><tbody><?php foreach($preview as $row):?><tr><td><?=esc($row['nama'])?></td><td><?=esc($row['username'])?></td><td><?=esc(strtoupper($row['role']))?></td><td><?=esc($row['id_phl'])?></td></tr><?php endforeach;?></tbody></table></div><form method="post"><input type="hidden" name="csrf" value="<?=esc(csrf())?>"><input type="hidden" name="action" value="confirm"><p><button type="submit">Konfirmasi &amp; Buat Akun</button></p></form><?php endif;?><p><small>Impor membuat akun di portal_users yang digunakan login Android. Tidak diperlukan SQL.</small></p></section></main></body></html>