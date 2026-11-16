<?php
declare(strict_types=1);

/**
 * Native Flutter admin CMS over the same JSON storage as the website.
 * Admin access is rechecked on each request; bearer tokens are never
 * included in image URLs. This file does not render browser HTML.
 */
function cikoko_mobile_cms_route(string $action,string $method):void {
 $user=mobile_auth();
 if(($user['user_role']??'')!=='admin'){
  mobile_error('Hanya Admin Utama dapat mengelola seluruh halaman.',403);
 }
 $allowedContent=['berita','pengumuman','galeri','layanan'];
 $allowedSlots=['brand_logo','hero','news','gallery','service',
  'service_1','service_2','service_3','service_4','service_5','service_6'];
 $allowedPages=['cms-halaman','wilayah','laporan-publik','profil',
  'kontak','ppid','agenda','pimpinan'];

 if($action==='cms_content_list'&&$method==='GET'){
  $rows=array_values(array_filter(db_read('content'),static function($r)use($allowedContent){
   return is_array($r)&&in_array($r['type']??'',$allowedContent,true);
  }));
  usort($rows,static fn($a,$b)=>strcmp((string)($b['created_at']??''),
    (string)($a['created_at']??'')));
  mobile_json(['ok'=>true,'items'=>$rows]);
 }

 if($action==='cms_media_upload'&&$method==='POST'){
  $filename=mobile_file('photo',true);
  $from=__DIR__.'/private/'.$filename;
  $directory=dirname(__DIR__).'/assets/images';
  if(!is_dir($directory)&&!@mkdir($directory,0755,true)){
   @unlink($from);
   mobile_error('Penyimpanan foto website tidak tersedia.',503);
  }
  $target='app-'.$filename;
  if(!@rename($from,$directory.'/'.$target)){
   @unlink($from);
   mobile_error('Foto belum dapat disimpan ke website.',503);
  }
  @chmod($directory.'/'.$target,0644);
  mobile_json(['ok'=>true,'path'=>'assets/images/'.$target,
   'url'=>'https://datawebs.my.id/assets/images/'.$target]);
 }

 if($action==='cms_content_save'&&$method==='POST'){
  $b=mobile_body();
  $type=mobile_text($b['type']??'',30);
  $id=mobile_text($b['id']??'',100);
  $title=mobile_text($b['title']??'',200);
  $body=mobile_text($b['body']??'',12000);
  $link=mobile_text($b['link']??'',1500);
  $image=mobile_text($b['image']??'',255);
  if(!in_array($type,$allowedContent,true)||mobile_strlen($title)<3
    ||mobile_strlen($body)<3)mobile_error('Jenis, judul dan isi wajib diisi.',422);
  if($link!==''&&(!filter_var($link,FILTER_VALIDATE_URL)
    ||strtolower((string)parse_url($link,PHP_URL_SCHEME))!=='https')){
    mobile_error('Tautan harus HTTPS.',422);
  }
  if($image!==''&&!cikoko_mobile_cms_safe_image($image)){
   mobile_error('Foto harus berasal dari pengunggahan website.',422);
  }
  $rows=db_read('content');$index=null;
  if($id!==''){
   foreach($rows as $i=>$row)if(is_array($row)&&($row['id']??'')===$id){
    $index=$i;break;
   }
   if($index===null)mobile_error('Konten tidak ditemukan.',404);
   if(($rows[$index]['type']??'')!==$type)mobile_error('Jenis konten tidak cocok.',422);
  }else{$id=bin2hex(random_bytes(12));}
  $old=$index!==null?$rows[$index]:[];
  if($image===''&&isset($old['image']))$image=(string)$old['image'];
  $oldImages=is_array($old['images']??null)?$old['images']:[];
  $images=$type==='berita'
   ?array_slice(array_values(array_unique(array_filter(array_merge(
    $image!==''?[$image]:[],$oldImages),'is_string'))),0,5):[];
  $new=[
   'id'=>$id,'type'=>$type,'title'=>$title,'body'=>nl2br(esc($body)),
   'link'=>$link,'image'=>$image,'images'=>$images,
   'created_at'=>$old['created_at']??date('Y-m-d H:i:s'),
  ];
  if($index===null)$rows[]=$new;else $rows[$index]=$new;
  if(!db_write('content',$rows))mobile_error('Konten tidak berhasil disimpan.',503);
  mobile_json(['ok'=>true,'id'=>$id,'item'=>$new]);
 }

 if($action==='cms_content_delete'&&$method==='POST'){
  $b=mobile_body();$id=mobile_text($b['id']??'',100);
  if($id==='')mobile_error('ID konten wajib.',422);
  $rows=db_read('content');
  $filtered=array_values(array_filter($rows,static fn($r)=>
   !is_array($r)||($r['id']??'')!==$id));
  if(count($rows)===count($filtered))mobile_error('Konten tidak ditemukan.',404);
  if(!db_write('content',$filtered))mobile_error('Konten tidak berhasil dihapus.',503);
  mobile_json(['ok'=>true]);
 }

 if($action==='cms_appearance_list'&&$method==='GET'){
  $current=appearance();
  $selected=[];
  foreach($allowedSlots as $slot)$selected[$slot]=$current[$slot]??[];
  mobile_json(['ok'=>true,'slots'=>$selected]);
 }

 if($action==='cms_appearance_save'&&$method==='POST'){
  $b=mobile_body();
  $slot=mobile_text($b['slot']??'',40);
  if(!in_array($slot,$allowedSlots,true))mobile_error('Slot tampilan tidak valid.',422);
  $current=db_read('appearance');
  $previous=ap($slot);
  $photo=mobile_text($b['file']??($previous['file']??''),255);
  if($photo!==''&&!cikoko_mobile_cms_safe_image($photo)){
   mobile_error('Foto harus sudah tersedia di folder gambar website.',422);
  }
  $fit=($b['fit']??'cover')==='contain'?'contain':'cover';
  $current[$slot]=array_merge($previous,[
   'file'=>$photo,'fit'=>$fit,
   'x'=>max(0,min(100,(int)($b['x']??50))),
   'y'=>max(0,min(100,(int)($b['y']??50))),
  ]);
  if(!db_write('appearance',$current))mobile_error('Tampilan tidak berhasil disimpan.',503);
  mobile_json(['ok'=>true,'slot'=>$slot,'appearance'=>$current[$slot]]);
 }

 if($action==='cms_page_list'&&$method==='GET'){
  $saved=db_read('cikoko_pages_cms');
  $pages=[];
  foreach($allowedPages as $key){
   $item=$saved[$key]??[];
   $pages[$key]=is_array($item)
    ?['title'=>(string)($item['title']??''),
      'body'=>(string)($item['body']??'')]:['title'=>'','body'=>''];
  }
  mobile_json(['ok'=>true,'pages'=>$pages]);
 }

 if($action==='cms_page_save'&&$method==='POST'){
  $b=mobile_body();$slug=mobile_text($b['slug']??'',60);
  $title=mobile_text($b['title']??'',160);$body=mobile_text($b['body']??'',12000);
  if(!in_array($slug,$allowedPages,true)||mobile_strlen($title)<3
   ||mobile_strlen($body)<3)mobile_error('Halaman, judul dan isi wajib diisi.',422);
  $pages=db_read('cikoko_pages_cms');
  $pages[$slug]=['title'=>$title,'body'=>$body,'updated_at'=>date('c')];
  if(!db_write('cikoko_pages_cms',$pages))mobile_error('Halaman belum dapat disimpan.',503);
  mobile_json(['ok'=>true,'slug'=>$slug]);
 }

 mobile_error('Layanan editor tidak ditemukan.',404);
}

function cikoko_mobile_cms_safe_image(string $path):bool {
 if(!preg_match('~^assets/images/[a-zA-Z0-9._-]+\.(jpg|jpeg|png|webp)$~iD',$path))return false;
 if(str_contains($path,'..'))return false;
 $root=realpath(dirname(__DIR__).'/assets/images');
 $file=$root?realpath(dirname(__DIR__).'/'.$path):false;
 return $root!==false&&$file!==false&&dirname($file)===$root&&is_file($file);
}
