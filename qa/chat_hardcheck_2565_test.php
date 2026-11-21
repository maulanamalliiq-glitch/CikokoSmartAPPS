<?php
declare(strict_types=1);
// Runs on an in-memory disposable database; never touches production.
require __DIR__.'/../cpanel/mobile-api/chat_hardcheck_2565.php';
function db_read(string $category):array{
 if($category!=='portal_users')return [];
 return [
  ['id'=>'active-warga','active'=>true,'role'=>'warga'],
  ['id'=>'inactive-warga','active'=>false,'role'=>'warga'],
 ];
}
function ensure_chat(bool $ok,string $description):void{
 if(!$ok)throw new RuntimeException('FAIL '.$description);
 echo 'PASS '.$description."\n";
}
if(!in_array('sqlite',PDO::getAvailableDrivers(),true)){
 echo "SKIP SQL integration (pdo_sqlite unavailable); syntax is checked separately\n";
 exit(0);
}
$db=new PDO('sqlite::memory:');
$db->setAttribute(PDO::ATTR_ERRMODE,PDO::ERRMODE_EXCEPTION);
$db->exec('CREATE TABLE mobile_chat (id INTEGER PRIMARY KEY AUTOINCREMENT,user_id TEXT)');
$q=$db->prepare('INSERT INTO mobile_chat(user_id) VALUES(?)');$q->execute(['historical-warga']);
ensure_chat(cikoko_chat_v2565_known_target($db,'historical-warga'),
 'Existing chat owners are valid for staff reply and photo');
ensure_chat(cikoko_chat_v2565_known_target($db,'active-warga'),
 'Active portal user can start a chat with a photo');
ensure_chat(!cikoko_chat_v2565_known_target($db,'inactive-warga'),
 'Inactive portal accounts cannot be targeted without a thread');
ensure_chat(!cikoko_chat_v2565_known_target($db,'missing-warga'),
 'Arbitrary unknown account IDs cannot receive photos');
ensure_chat(!cikoko_chat_v2565_known_target($db,'../secret'),
 'Malformed account IDs are rejected');
echo "ALL CHAT HARD CHECK 2565 TESTS PASSED\n";
