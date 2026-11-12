<?php
declare(strict_types=1);

/**
 * Bridge for older website CMS releases.
 * The live site calls cikoko_publish_notification after publishing content.
 * Emit private per-account events immediately, instead of one public row
 * which the Android inbox/FCM dispatcher cannot deliver.
 */
function cikoko_publish_notification(string $type,string $title):bool {
    if(!in_array($type,['berita','pengumuman','inovasi'],true))return false;
    try {
        require_once dirname(__DIR__).'/mobile-api/bootstrap.php';
        $targets=mobile_notification_recipients($type,'public',null);
        if(!$targets)return true;
        $db=mobile_db();
        $st=$db->prepare('INSERT INTO mobile_events
          (category,title,message,audience,recipient) VALUES(?,?,?,"personal",?)');
        $msg=$type==='berita'?'Berita terbaru Kelurahan Cikoko telah diterbitkan.':
            ($type==='inovasi'?'Informasi inovasi Kelurahan Cikoko diperbarui.':
                'Pengumuman terbaru Kelurahan Cikoko telah diterbitkan.');
        $db->beginTransaction();
        try{
            foreach($targets as $t){
                if(($t['audience']??'')!=='personal'||empty($t['recipient']))continue;
                $st->execute([$type,substr(trim($title),0,240),$msg,(string)$t['recipient']]);
            }
            $db->commit();
        }catch(Throwable $e){
            if($db->inTransaction())$db->rollBack();
            throw $e;
        }
        return true;
    }catch(Throwable $e){
        error_log('Cikoko website → Android notification failed: '.$e->getMessage());
        return false;
    }
}
