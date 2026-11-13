<?php
declare(strict_types=1);
// Server-driven native Flutter module definitions. No executable HTML/JS is accepted.
function cikoko_dynamic_path():string {return __DIR__.'/.cikoko-dynamic-modules.php';}
function cikoko_dynamic_read():array {
 $raw=@file_get_contents(cikoko_dynamic_path());
 $prefix='<?php __halt_compiler(); ?>';
 if(!is_string($raw)||!str_starts_with($raw,$prefix))return [];
 $v=json_decode(substr($raw,strlen($prefix)),true);
 return is_array($v)?$v:[];
}
function cikoko_dynamic_dispatch(string $action,string $method):void {
 $user=mobile_auth();$role=(string)($user['user_role']??'');
 $admin=in_array($role,['admin','admin_kelurahan'],true);
 if($action==='dynamic_modules'){
  if($method!=='GET')mobile_error('Metode tidak tersedia.',405);
  $items=array_values(array_filter(cikoko_dynamic_read(),static fn($v)=>is_array($v)&&($admin||(($v['active']??false)===true&&in_array($role,$v['roles']??[],true)))));
  mobile_json(['ok'=>true,'items'=>$items,'schema_version'=>1]);
 }
 if($action!=='dynamic_modules_save'||$method!=='POST')mobile_error('Layanan tidak tersedia.',404);
 if(!$admin)mobile_error('Hanya admin yang dapat mengelola modul.',403);
 $payload=mobile_body();$rows=$payload['items']??null;
 if(!is_array($rows)||count($rows)>40)mobile_error('Maksimal 40 modul.',422);
 $safe=[];$seen=[];$types=['text','number','date','multiline','choice'];
 foreach($rows as $row){
  if(!is_array($row))mobile_error('Format modul tidak valid.',422);
  $id=(string)($row['id']??'');$title=trim((string)($row['title']??''));
  if(!preg_match('/^[a-z][a-z0-9_]{2,39}$/D',$id)||isset($seen[$id])||mb_strlen($title)>80||$title==='')mobile_error('ID atau judul modul tidak valid.',422);
  $seen[$id]=true;$fields=[];$keys=[];
  $source=$row['fields']??[];
  if(!is_array($source)||count($source)>25)mobile_error('Maksimal 25 kolom per modul.',422);
  foreach($source as $field){
   if(!is_array($field))mobile_error('Kolom tidak valid.',422);
   $key=(string)($field['key']??'');$label=trim((string)($field['label']??''));$type=(string)($field['type']??'text');
   if(!preg_match('/^[a-z][a-z0-9_]{1,39}$/D',$key)||isset($keys[$key])||!in_array($type,$types,true)||$label===''||mb_strlen($label)>80)mobile_error('Definisi kolom tidak valid.',422);
   $keys[$key]=true;$options=[];
   if($type==='choice'){
    foreach(($field['options']??[]) as $option){
     if(!is_string($option)||mb_strlen($option)>80)mobile_error('Pilihan tidak valid.',422);
     $options[]=trim($option);
    }
    if(count($options)<1||count($options)>30)mobile_error('Pilihan harus 1–30.',422);
   }
   $fields[]=['key'=>$key,'label'=>$label,'type'=>$type,'required'=>($field['required']??false)===true,'options'=>$options];
  }
  $roles=array_values(array_intersect(['admin','admin_kelurahan','ppsu','pjlp','warga'],array_filter($row['roles']??[], 'is_string')));
  $safe[]=['id'=>$id,'title'=>$title,'description'=>mb_substr(trim((string)($row['description']??'')),0,300),'active'=>($row['active']??false)===true,'roles'=>$roles,'fields'=>$fields];
 }
 $path=cikoko_dynamic_path();$tmp=$path.'.'.bin2hex(random_bytes(6)).'.tmp';
 $data='<?php __halt_compiler(); ?>'.json_encode($safe,JSON_UNESCAPED_UNICODE|JSON_THROW_ON_ERROR);
 if(file_put_contents($tmp,$data,LOCK_EX)===false||!rename($tmp,$path)){@unlink($tmp);mobile_error('Penyimpanan modul gagal.',503);}
 @chmod($path,0600);
 mobile_json(['ok'=>true,'items'=>$safe]);
}
