<?php
declare(strict_types=1);
function cikoko_report_history_schema(PDO $db):void {
  static $ok=false;
  if($ok)return;
  $db->exec('CREATE TABLE IF NOT EXISTS mobile_report_progress (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    report_id BIGINT UNSIGNED NOT NULL,
    previous_status VARCHAR(20) NOT NULL,
    new_status VARCHAR(20) NOT NULL,
    actor_id VARCHAR(80) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_report(report_id,id)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
  $ok=true;
}
function cikoko_report_history_log(PDO $db,int $id,string $actor,string $previous,string $next):void {
  cikoko_report_history_schema($db);
  if($previous===$next)return;
  $s=$db->prepare('INSERT INTO mobile_report_progress
    (report_id,previous_status,new_status,actor_id) VALUES(?,?,?,?)');
  $s->execute([$id,$previous,$next,$actor]);
}
function cikoko_report_history(PDO $db,int $id,string $created,string $initial='masuk'):array {
  cikoko_report_history_schema($db);
  $rows=[['new_status'=>'masuk','created_at'=>$created,'notes'=>'Laporan telah diterima']];
  $s=$db->prepare('SELECT new_status,created_at FROM mobile_report_progress WHERE report_id=? ORDER BY id ASC');
  $s->execute([$id]);
  foreach($s->fetchAll() as $row)$rows[]=[
    'new_status'=>$row['new_status'],
    'created_at'=>$row['created_at'],
    'notes'=>'Status laporan diperbarui oleh petugas',
  ];
  return $rows;
}
