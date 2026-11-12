<?php
declare(strict_types=1);
require __DIR__.'/../cpanel/mobile-api/release_core.php';
function check(bool $condition,string $label):void {
 if(!$condition){fwrite(STDERR,"FAIL: ".$label."\n");exit(1);}
 echo "PASS: ".$label."\n";
}
$db=new PDO('sqlite::memory:',null,null,[
 PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION,
 PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC,
]);
$db->exec('CREATE TABLE mobile_chat(
 id INTEGER PRIMARY KEY AUTOINCREMENT,user_id TEXT,name TEXT,
 sender TEXT,message TEXT,created_at TEXT)');
$db->exec('CREATE TABLE mobile_chat_receipts(
 user_id TEXT PRIMARY KEY,admin_delivered_id INTEGER DEFAULT 0,
 admin_read_id INTEGER DEFAULT 0,warga_delivered_id INTEGER DEFAULT 0,
 warga_read_id INTEGER DEFAULT 0)');
$db->exec("INSERT INTO mobile_chat(user_id,name,sender,message,created_at)
 VALUES('warga_uji','Warga Uji','warga','Uji tanda terima','2026-11-12 13:00:00')");
$id=(int)$db->lastInsertId();
$initial=cikoko_chat_page($db,'warga_uji','warga');
check(($initial['receipt_updates'][(string)$id]??'')==='sent',
 'New message has exactly sent status');
cikoko_chat_ack($db,'warga_uji','admin','delivered',$id);
$afterDelivery=cikoko_chat_receipt_data($db,'warga_uji');
check((int)$afterDelivery['admin_read_id']===0,
 'Inbox delivery alone does not falsely mark read');
$delivered=cikoko_chat_page($db,'warga_uji','warga');
check(($delivered['receipt_updates'][(string)$id]??'')==='delivered',
 'Delivered status has two checks but is not green');
$seenByStaff=cikoko_chat_page($db,'warga_uji','admin');
check(($seenByStaff['receipt_updates'][(string)$id]??'')==='read',
 'Opening staff thread acknowledges actual read');
$read=cikoko_chat_page($db,'warga_uji','warga');
check(($read['receipt_updates'][(string)$id]??'')==='read',
 'Warga sees green double-check after staff opens chat');
$db->exec("INSERT INTO mobile_chat(user_id,name,sender,message,created_at)
 VALUES('warga_lain','Warga Lain','warga','Percakapan privat','2026-11-12 13:01:00')");
$other=cikoko_chat_receipt_data($db,'warga_lain');
check($other===[],'Other account receipts were not mutated');
echo "Cikoko Chat 2548 receipt tests passed.\n";
