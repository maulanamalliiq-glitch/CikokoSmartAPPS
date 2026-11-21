<?php
declare(strict_types=1);

/**
 * A staff photo/text can target a real account even if its first message
 * has not yet been inserted. Never trust a display name or a user-supplied
 * thread identifier; all calls must have passed chat:reply authorization.
 */
function cikoko_chat_v2565_known_target(PDO $db,string $owner):bool {
 if(!preg_match('/^[A-Za-z0-9_-]{2,80}$/D',$owner))return false;
 $q=$db->prepare('SELECT 1 FROM mobile_chat WHERE user_id=? LIMIT 1');
 $q->execute([$owner]);
 if($q->fetchColumn())return true;
 foreach(db_read('portal_users') as $account){
  if(!is_array($account))continue;
  if((string)($account['id']??'')===$owner&&
   !empty($account['active']))return true;
 }
 return false;
}
