<?php
declare(strict_types=1);
$dsn=(string)getenv('TEST_MYSQL_DSN');
if(strpos($dsn,'dbname=cikoko_test')===false)throw new RuntimeException('Only isolated cikoko_test database is allowed');
require __DIR__.'/../cpanel/mobile-api/report_integrity_2546.php';
$db=new PDO($dsn,(string)getenv('TEST_MYSQL_USER'),(string)getenv('TEST_MYSQL_PASSWORD'),[
 PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION,PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC,PDO::ATTR_EMULATE_PREPARES=>false
]);
$db->exec('DROP TABLE IF EXISTS mobile_reports');
$db->exec('CREATE TABLE mobile_reports(id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,user_id VARCHAR(80) NOT NULL,user_name VARCHAR(160) NOT NULL,user_role VARCHAR(50) NOT NULL,kind VARCHAR(60) NOT NULL,address VARCHAR(500) NOT NULL,phone VARCHAR(40) NOT NULL,notes TEXT NOT NULL,photo_name VARCHAR(100) NULL,status VARCHAR(20) NOT NULL DEFAULT "masuk",created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,INDEX idx_user(user_id)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
function ck(bool $ok,string $description):void {if(!$ok)throw new RuntimeException('FAILED: '.$description);echo 'PASS: '.$description."\n";}
$a=['user_id'=>'warga-A','username'=>'Warga A','user_role'=>'warga'];
$b=['user_id'=>'asn-B','username'=>'ASN B','user_role'=>'asn'];
$db->beginTransaction();
$id=cikoko_report_create($db,$a,'jumantik','RT 01 / RW 02','08123456789','Dokumentasi A',str_repeat('a',40).'.jpg');
$db->commit();
ck($id>0,'Warga report persists and returns a verified database ID');
$q=$db->prepare('SELECT user_id,user_role,kind,photo_name,status FROM mobile_reports WHERE id=?');$q->execute([$id]);$row=$q->fetch(PDO::FETCH_ASSOC);
ck($row['user_id']==='warga-A'&&$row['kind']==='jumantik'&&$row['status']==='masuk','Report owner and status belong to the correct citizen');
$id2=cikoko_report_create($db,$b,'kegiatan','Kantor Cikoko','','Koordinasi staf',str_repeat('b',40).'.png');
ck($id2>$id,'ASN receives an independent report ID');
try{cikoko_report_create($db,$a,'jumantik','','','',str_repeat('c',40).'.png');throw new RuntimeException('Invalid report accepted');}
catch(InvalidArgumentException $e){ck(true,'Missing required report data is rejected before insertion');}
$db->beginTransaction();
$id3=cikoko_report_create($db,$a,'jumantik','RT 03','','Rollback test',str_repeat('c',40).'.webp');
$db->rollBack();
$q=$db->prepare('SELECT COUNT(*) FROM mobile_reports WHERE id=?');$q->execute([$id3]);
ck((int)$q->fetchColumn()===0,'Rollback prevents ghost reports');
ck((int)$db->query('SELECT COUNT(*) FROM mobile_reports')->fetchColumn()===2,'No additional or cross-account report inserts');
echo "ALL REPORT MYSQL 2546 TESTS PASS\n";
