<?php
declare(strict_types=1);

/**
 * One row per canonical mobile_chat.user_id, never one row per message.
 * Does not merge accounts by display name: two accounts can share a name.
 * The caller MUST check chat:reply authorization before invoking this helper.
 */
function cikoko_chat_inbox_2563(PDO $db, int $limit=100):array {
 $limit=max(1,min(100,$limit));
 $sql='SELECT last_message.user_id, last_message.id AS last_id,
       last_message.message, last_message.created_at, last_message.sender,
       COALESCE(
        (SELECT sender_message.name FROM mobile_chat sender_message
         WHERE sender_message.user_id=last_message.user_id
           AND sender_message.sender="warga"
         ORDER BY sender_message.id DESC LIMIT 1),
        last_message.name
       ) AS name,
       (SELECT COUNT(*) FROM mobile_chat incoming
        WHERE incoming.user_id=last_message.user_id
          AND incoming.sender="warga"
          AND incoming.id>COALESCE(receipts.admin_read_id,0)
       ) AS unread_count
   FROM mobile_chat last_message
   JOIN (
     SELECT user_id, MAX(id) AS last_id
     FROM mobile_chat
     WHERE user_id IS NOT NULL AND user_id<>""
     GROUP BY user_id
   ) recent ON recent.last_id=last_message.id AND
       recent.user_id=last_message.user_id
   LEFT JOIN mobile_chat_receipts receipts
     ON receipts.user_id=last_message.user_id
   ORDER BY last_message.id DESC LIMIT '.($limit+1);
 $rows=$db->query($sql)->fetchAll(PDO::FETCH_ASSOC);
 $hasMore=count($rows)>$limit;
 $rows=array_slice($rows,0,$limit);
 $threads=[];$unread=0;$unreadThreads=0;$seen=[];
 foreach($rows as $row) {
  $id=(string)($row['user_id']??'');
  // Invalid legacy identifiers may not be opened; don't expose them in inbox.
  if(!preg_match('/^[A-Za-z0-9_-]{2,80}$/D',$id)||isset($seen[$id]))continue;
  $seen[$id]=true;
  $count=max(0,(int)($row['unread_count']??0));
  $unread+=$count;
  if($count>0)$unreadThreads++;
  $name=trim((string)($row['name']??''));
  $threads[]=[
   'user_id'=>$id,
   'name'=>$name!==''?$name:'Warga Cikoko',
   'last_id'=>(int)($row['last_id']??0),
   'message'=>(string)($row['message']??''),
   'created_at'=>(string)($row['created_at']??''),
   'sender'=>(string)($row['sender']??''),
   'unread_count'=>$count,
  ];
 }
 return ['ok'=>true,'threads'=>$threads,'unread_total'=>$unread,
  'unread_conversations'=>$unreadThreads,'has_more'=>$hasMore];
}
