<?php
declare(strict_types=1);
// Isolated, deterministic inbox regression: never connects to production.
require __DIR__.'/../cpanel/mobile-api/chat_inbox_2563.php';
if(!in_array('sqlite',PDO::getAvailableDrivers(),true)){
 fwrite(STDERR,"SKIP: pdo_sqlite not installed; php -l still required.\n");
 exit(0);
}
$db=new PDO('sqlite::memory:');
$db->setAttribute(PDO::ATTR_ERRMODE,PDO::ERRMODE_EXCEPTION);
$db->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE,PDO::FETCH_ASSOC);
$db->exec('CREATE TABLE mobile_chat (
 id INTEGER PRIMARY KEY AUTOINCREMENT,user_id TEXT,name TEXT,
 sender TEXT,message TEXT,created_at TEXT)');
$db->exec('CREATE TABLE mobile_chat_receipts (
 user_id TEXT PRIMARY KEY, admin_read_id INTEGER NOT NULL DEFAULT 0)');
$q=$db->prepare('INSERT INTO mobile_chat(user_id,name,sender,message,created_at)
 VALUES(?,?,?,?,?)');
foreach([
 ['resident-A','Warga A','warga','Pertanyaan A','2026-11-16 10:00:00'],
 ['resident-B','Warga B','warga','Pertanyaan B','2026-11-16 10:01:00'],
 ['resident-A','Admin Kelurahan','admin','Balasan A','2026-11-16 10:02:00'],
 ['resident-A','Warga A','warga','Pertanyaan lanjut A','2026-11-16 10:03:00'],
 ['resident-B','Admin Kelurahan','admin','Balasan B','2026-11-16 10:04:00'],
 ['resident-B','Warga B','warga','Pertanyaan kedua B','2026-11-16 10:05:00'],
 ['resident-C','Warga A','warga','Akun C dengan nama sama','2026-11-16 10:06:00'],
] as $m)$q->execute($m);
$db->exec("INSERT INTO mobile_chat_receipts(user_id,admin_read_id) VALUES('resident-A',1),('resident-B',6)");
function check_inbox(bool $ok,string $label):void{
 if(!$ok)throw new RuntimeException('FAIL: '.$label);
 echo 'PASS: '.$label."\n";
}
$x=cikoko_chat_inbox_2563($db);
check_inbox(count($x['threads'])===3,'One row per distinct stable account ID');
$byId=array_column($x['threads'],null,'user_id');
check_inbox(count($byId)===3,'All unique resident accounts retained');
check_inbox($byId['resident-A']['name']==='Warga A','Display name comes from resident, not last staff message');
check_inbox($byId['resident-A']['unread_count']===1,'Unread count after last admin read marker');
check_inbox($byId['resident-B']['unread_count']===0,'Read resident thread no unread');
check_inbox($byId['resident-C']['unread_count']===1,'Separate account with same name is not mixed into another');
check_inbox($x['unread_total']===2 && $x['unread_conversations']===2,'Unread total and conversation count correct');
check_inbox($x['threads'][0]['user_id']==='resident-C','Newest conversations sorted first');
echo "CHAT INBOX 2563 TESTS PASSED\n";
