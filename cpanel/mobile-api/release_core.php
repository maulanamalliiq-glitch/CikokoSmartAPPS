<?php
declare(strict_types=1);
function cikoko_release_schema(PDO $db):void {
 static $done=false;if($done)return;
 foreach([
 'CREATE TABLE IF NOT EXISTS mobile_auth_limits(bucket CHAR(64) PRIMARY KEY, attempts INT NOT NULL DEFAULT 0, reset_at BIGINT NOT NULL, INDEX idx_reset(reset_at)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4',
 'CREATE TABLE IF NOT EXISTS mobile_account_requests(id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, user_id VARCHAR(80) NOT NULL, kind VARCHAR(20) NOT NULL, contact VARCHAR(160) NOT NULL, notes VARCHAR(1000) NOT NULL, status VARCHAR(20) NOT NULL DEFAULT "pending", actor_id VARCHAR(80) NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, closed_at DATETIME NULL, INDEX idx_status(status,id), INDEX idx_owner(user_id,id)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4',
 'CREATE TABLE IF NOT EXISTS mobile_submission_areas(source VARCHAR(20) NOT NULL, report_id BIGINT UNSIGNED NOT NULL, rt VARCHAR(3) NOT NULL, rw VARCHAR(3) NOT NULL, captured_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY(source,report_id)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4',
 'CREATE TABLE IF NOT EXISTS mobile_chat_receipts(user_id VARCHAR(80) NOT NULL PRIMARY KEY, admin_delivered_id BIGINT UNSIGNED NOT NULL DEFAULT 0, admin_read_id BIGINT UNSIGNED NOT NULL DEFAULT 0, warga_delivered_id BIGINT UNSIGNED NOT NULL DEFAULT 0, warga_read_id BIGINT UNSIGNED NOT NULL DEFAULT 0, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4',
 'CREATE TABLE IF NOT EXISTS mobile_chat_presence(session_hash CHAR(64) NOT NULL PRIMARY KEY,user_id VARCHAR(80) NOT NULL,user_role VARCHAR(40) NOT NULL,last_seen_at DATETIME NOT NULL,INDEX idx_last_seen(last_seen_at,user_role),INDEX idx_account(user_id)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4',
 'CREATE TABLE IF NOT EXISTS mobile_chat_bot_state(user_id VARCHAR(80) NOT NULL PRIMARY KEY,last_bot_message_id BIGINT UNSIGNED NOT NULL DEFAULT 0,updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4'
 ] as $sql)$db->exec($sql);$done=true;
}
function cikoko_rate_limit(PDO $db,string $scope,string $identity,int $limit,int $window):void {
 // REMOTE_ADDR is used directly: forwarding headers are untrusted.
 $bucket=hash('sha256',$scope.'|'.$identity);$now=time();
 $q=$db->prepare('INSERT INTO mobile_auth_limits(bucket,attempts,reset_at) VALUES(?,1,?) ON DUPLICATE KEY UPDATE attempts=IF(reset_at<=?,1,attempts+1),reset_at=IF(reset_at<=?,VALUES(reset_at),reset_at)');
 $q->execute([$bucket,$now+$window,$now,$now]);
 $q=$db->prepare('SELECT attempts,reset_at FROM mobile_auth_limits WHERE bucket=?');$q->execute([$bucket]);$row=$q->fetch();
 if((int)$row['attempts']>$limit){header('Retry-After: '.max(1,(int)$row['reset_at']-$now));mobile_error('Terlalu banyak percobaan. Silakan mencoba kembali beberapa saat lagi.',429);}
 if(random_int(1,100)===1)$db->exec('DELETE FROM mobile_auth_limits WHERE reset_at<'.($now-86400).' LIMIT 500');
}
function cikoko_password_valid(string $password):bool {
 return strlen($password)<=128 && mobile_strlen($password)>=10 && preg_match('/[A-Za-z]/',$password)===1 && preg_match('/[0-9]/',$password)===1;
}
// Chat receipts are account-scoped watermarks. An admin inbox view only marks
// delivery; a specific open thread is required to mark a message read.
function cikoko_chat_ack(PDO $db,string $owner,string $recipient,string $stage,int $maxId):void {
 if($owner==='' || $maxId<1 || !in_array($recipient,['admin','warga'],true) || !in_array($stage,['delivered','read'],true))return;
 $column=$recipient.'_delivered_id';$read=$recipient.'_read_id';
 $insert=$db->getAttribute(PDO::ATTR_DRIVER_NAME)==='sqlite'?'INSERT OR IGNORE':'INSERT IGNORE';
 $q=$db->prepare($insert.' INTO mobile_chat_receipts(user_id) VALUES(?)');$q->execute([$owner]);
 $sql='UPDATE mobile_chat_receipts SET '.$column.'=CASE WHEN '.$column.'<? THEN ? ELSE '.$column.' END';
 $args=[$maxId,$maxId];
 if($stage==='read'){$sql.=','.$read.'=CASE WHEN '.$read.'<? THEN ? ELSE '.$read.' END';array_push($args,$maxId,$maxId);}
 $args[]=$owner;$db->prepare($sql.' WHERE user_id=?')->execute($args);
}
function cikoko_chat_receipt_data(PDO $db,string $owner):array {
 $q=$db->prepare('SELECT admin_delivered_id,admin_read_id,warga_delivered_id,warga_read_id FROM mobile_chat_receipts WHERE user_id=?');$q->execute([$owner]);
 return $q->fetch(PDO::FETCH_ASSOC)?:[];
}
function cikoko_chat_status(array $row,array $receipt):string {
 if(($row['sender']??'')==='bot')return 'system';
 $id=(int)($row['id']??0);$recipient=(($row['sender']??'')==='admin')?'warga':'admin';
 $read=(int)($receipt[$recipient.'_read_id']??0);$delivered=(int)($receipt[$recipient.'_delivered_id']??0);
 if($id>0 && $read >= $id)return $delivered >= $id?'read':'read_legacy';
 if($id>0 && $delivered >= $id)return 'delivered';
 return 'sent';
}
function cikoko_chat_page(PDO $db,string $owner,string $viewer=''):array {
 $before=max(0,(int)($_GET['before_id']??0));$after=max(0,(int)($_GET['after_id']??0));
 $sql='SELECT id,sender,message,created_at FROM mobile_chat WHERE user_id=?';$args=[$owner];
 if($before>0){$sql.=' AND id<?';$args[]=$before;}
 elseif($after>0){$sql.=' AND id>?';$args[]=$after;}
 $sql.=$after>0&&$before===0?' ORDER BY id ASC LIMIT 61':' ORDER BY id DESC LIMIT 61';
 $q=$db->prepare($sql);$q->execute($args);$rows=$q->fetchAll(PDO::FETCH_ASSOC);
 $more=count($rows)>60;$rows=array_slice($rows,0,60);
 if($after===0||$before>0)$rows=array_reverse($rows);
 if(!in_array($viewer,['warga','admin'],true))return ['ok'=>true,'messages'=>$rows,'has_more'=>$more,'thread_user_id'=>$owner];
 // A read acknowledgment is never written for the current sender's own messages.
 $opposite=$viewer==='admin'?'warga':'admin';$maxRead=0;
 foreach($rows as $row)if($row['sender']===$opposite)$maxRead=max($maxRead,(int)$row['id']);
 if($maxRead>0)cikoko_chat_ack($db,$owner,$viewer,'read',$maxRead);
 $receipt=cikoko_chat_receipt_data($db,$owner);
 foreach($rows as &$row)$row['delivery_status']=cikoko_chat_status($row,$receipt);
 unset($row);
 // Receipt updates must be returned even if no new message has arrived.
 // Keep them limited to this account and last 120 messages.
 $q=$db->prepare('SELECT id,sender FROM mobile_chat WHERE user_id=? ORDER BY id DESC LIMIT 120');$q->execute([$owner]);
 $statuses=[];foreach($q->fetchAll(PDO::FETCH_ASSOC) as $row)$statuses[(string)$row['id']]=cikoko_chat_status($row,$receipt);
 return ['ok'=>true,'messages'=>$rows,'has_more'=>$more,'receipt_updates'=>$statuses,'thread_user_id'=>$owner];
}
function cikoko_capture_area(array &$response):void {
 global $action,$method,$uid,$u;
 if($method!=='POST'||empty($response['ok'])||empty($uid))return;
 $sources=['report'=>'report','waris'=>'waris','ppsu_report'=>'ppsu','fkdm_report'=>'fkdm','v211_ppsu_submit'=>'ppsu','v211_fkdm_submit'=>'fkdm'];
 if(!isset($sources[$action]))return;
 $source=$sources[$action];$id=(int)($response['id']??0);$db=mobile_db();
 if($source==='waris'&&$id<1&&!empty($response['reference'])){
  $q=$db->prepare('SELECT id FROM aw_applications WHERE reference_no=? AND account_id=?');$q->execute([$response['reference'],$uid]);$id=(int)$q->fetchColumn();
 }
 if($id<1)return;$area=['rt'=>'','rw'=>''];
 foreach(db_read('portal_users') as $user)if((string)($user['id']??'')===(string)$uid){$area=$user;break;}
 $q=$db->prepare('INSERT IGNORE INTO mobile_submission_areas(source,report_id,rt,rw) VALUES(?,?,?,?)');$q->execute([$source,$id,(string)($area['rt']??''),(string)($area['rw']??'')]);
}
function cikoko_area_snapshots(PDO $db):array {
 $map=[];foreach($db->query('SELECT source,report_id,rt,rw FROM mobile_submission_areas') as $r)$map[$r['source'].':'.$r['report_id']]=['rt'=>$r['rt'],'rw'=>$r['rw']];return $map;
}
