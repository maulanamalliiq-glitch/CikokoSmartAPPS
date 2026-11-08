<?php
declare(strict_types=1);
/** Persist reports on the currently authenticated PDO connection and verify ownership.
 * Requires prior permission check and valid uploaded photo filename.
 */
function cikoko_report_create(PDO $db,array $user,string $kind,string $address,string $phone,string $notes,string $photo):int {
 $owner=(string)($user['user_id']??'');$name=(string)($user['username']??'');$role=(string)($user['user_role']??'');
 if($owner===''||$role===''||$kind===''||$address===''||$notes===''||$photo==='')throw new InvalidArgumentException('Invalid authenticated report fields');
 $stmt=$db->prepare('INSERT INTO mobile_reports(user_id,user_name,user_role,kind,address,phone,notes,photo_name) VALUES(?,?,?,?,?,?,?,?)');
 $stmt->execute([$owner,$name,$role,$kind,$address,$phone,$notes,$photo]);
 $id=(int)$db->lastInsertId();
 if($id<1)throw new RuntimeException('Report insert did not return an ID');
 $check=$db->prepare('SELECT id FROM mobile_reports WHERE id=? AND user_id=? AND photo_name=? LIMIT 1');
 $check->execute([$id,$owner,$photo]);
 if((int)$check->fetchColumn()!==$id)throw new RuntimeException('Report read-after-write ownership check failed');
 return $id;
}
