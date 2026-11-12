<?php
declare(strict_types=1);

/**
 * Compatibility dispatcher for publications created by an older website.
 * It used to insert audience="public" without specifying a recipient, so
 * neither the mobile inbox nor FCM could deliver the row.
 *
 * Called from cron_dispatch.php before Firebase credential checking.
 * Existing private notifications are never modified.
 */
function cikoko_distribute_legacy_website_events(PDO $db):array {
    $converted=0;
    $skipped=0;
    $categories=['berita','pengumuman','inovasi'];
    for($n=0;$n<15;$n++){
        if(!$db->beginTransaction())break;
        try{
            $q=$db->query('SELECT id,category,title,message,created_at
                FROM mobile_events
                WHERE audience="public" AND dispatched_at IS NULL
                ORDER BY id ASC LIMIT 1 FOR UPDATE');
            $event=$q->fetch(PDO::FETCH_ASSOC);
            if(!$event){$db->commit();break;}
            $id=(int)$event['id'];
            $category=(string)$event['category'];
            // Do not send stale events when first enabling the bridge.
            $fresh=strtotime((string)$event['created_at'])>=time()-86400;
            if($fresh&&in_array($category,$categories,true)){
                $targets=mobile_notification_recipients($category,'public',null);
                $insert=$db->prepare('INSERT INTO mobile_events
                    (category,title,message,audience,recipient)
                    VALUES(?,?,?,"personal",?)');
                foreach($targets as $target){
                    if(($target['audience']??'')!=='personal'||empty($target['recipient']))continue;
                    $insert->execute([
                        $category,(string)$event['title'],
                        (string)$event['message'],(string)$target['recipient']
                    ]);
                    $converted++;
                }
            }else{$skipped++;}
            $update=$db->prepare('UPDATE mobile_events SET dispatched_at=NOW() WHERE id=?');
            $update->execute([$id]);
            $db->commit();
        }catch(Throwable $e){
            if($db->inTransaction())$db->rollBack();
            error_log('[Cikoko] Legacy publication dispatch failed: '.$e->getMessage());
            break;
        }
    }
    return ['converted'=>$converted,'skipped'=>$skipped];
}
