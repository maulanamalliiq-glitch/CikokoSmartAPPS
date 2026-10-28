<?php
declare(strict_types=1);
// API contract for authenticated document lists and exact AW references.
function cikoko_v2525_identity_row(array $row,string $kind):array {
 $raw=$row['id']??$row['application_id']??$row['request_id']??null;
 $v=is_scalar($raw)?trim((string)$raw):'';
 $id=ctype_digit($v)&&(int)$v>0?(int)$v:0;
 $row['id']=$id;$row['application_id']=$id;$row['request_id']=$id;
 $row['id_valid']=$id>0;$row['kind']=$kind;
 if($kind==='waris'){
  $ref=trim((string)($row['reference_no']??$row['reference']??''));
  if(preg_match('/^AW-[A-Z0-9-]{6,80}$/i',$ref)){
   $row['reference']=$ref;$row['reference_no']=$ref;$row['document_key']='waris:'.$ref;
  }
 }else{$row['document_key']=$id>0?'report:'.$id:null;}
 return $row;
}
function cikoko_v2525_reference_from_input(array $b):string {
 foreach(['reference_no','reference','document_key','title','id'] as $field){
  $v=$b[$field]??null;
  if(!is_scalar($v))continue;
  $ref=trim((string)$v);
  if(substr($ref,0,6)==='waris:')$ref=substr($ref,6);
  if(preg_match('/^AW-[A-Z0-9-]{6,80}$/i',$ref))return $ref;
 }
 return '';
}
function cikoko_v2525_identifier(PDO $db,$raw,string $kind):int {
 if(!is_scalar($raw))return 0;
 $s=trim((string)$raw);
 if(ctype_digit($s)&&(int)$s>0)return (int)$s;
 if(substr($s,0,6)==='waris:')$s=substr($s,6);
 if($kind==='waris'&&preg_match('/^AW-[A-Z0-9-]{6,80}$/i',$s)){
  $q=$db->prepare('SELECT id FROM aw_applications WHERE reference_no=? LIMIT 1');
  $q->execute([$s]);return (int)($q->fetchColumn()?:0);
 }
 return 0;
}
