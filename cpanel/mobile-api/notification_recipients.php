<?php
declare(strict_types=1);
// Convert administrative events into private events for authorized reviewers.
function mobile_notification_recipients(string $category,string $audience,?string $recipient):array {
 if($audience==='personal'){
  $id=trim((string)$recipient);
  return $id===''?[]:[['audience'=>'personal','recipient'=>$id]];
 }
 if($audience!=='admin')return [['audience'=>$audience,'recipient'=>$recipient]];
 $ids=['admin'=>true];
 $capability=$category==='chat'?'chat:reply':
   (in_array($category,['surat','progres_surat'],true)?'waris:view':'reports:view');
 if(function_exists('mobile_can')){
  foreach(db_read('portal_users') as $account){
   if(!is_array($account)||empty($account['active'])||empty($account['id']))continue;
   $viewer=['user_id'=>(string)$account['id'],'user_role'=>(string)($account['role']??'')];
   if(mobile_can($viewer,$capability))$ids[(string)$account['id']]=true;
  }
 }
 return array_map(static fn($id)=>['audience'=>'personal','recipient'=>(string)$id],array_keys($ids));
}
