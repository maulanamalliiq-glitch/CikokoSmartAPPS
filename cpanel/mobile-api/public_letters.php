<?php
declare(strict_types=1);
/**
 * Public read-only letter statistics. NEVER return citizen names, NIK, contact
 * details, addresses, uploads, staff notes, or private history.
 * Signed-in detail endpoints remain protected by mobile_auth().
 */
function cikoko_public_letter_bucket(string $status):string {
    if(in_array($status,['masuk','menunggu_rt'],true))return 'masuk';
    if(in_array($status,['selesai','terverifikasi'],true))return 'selesai';
    return 'proses';
}
function cikoko_public_letter_status(string $status):string {
    return match($status) {
        'menunggu_rt'=>'Menunggu verifikasi RT',
        'menunggu_rw'=>'Menunggu verifikasi RW',
        'terverifikasi'=>'Terverifikasi RT/RW',
        'masuk'=>'Surat masuk',
        'proses'=>'Sedang diproses',
        'revisi'=>'Menunggu perbaikan',
        'ditolak'=>'Ditolak',
        'selesai'=>'Selesai',
        default=>'Dalam proses',
    };
}
function cikoko_public_table_exists(PDO $db,string $table):bool {
    $q=$db->prepare('SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=?');
    $q->execute([$table]);
    return (int)$q->fetchColumn()>0;
}
function cikoko_public_letters(PDO $db):void {
    $counts=['masuk'=>0,'proses'=>0,'selesai'=>0];
    $items=[];
    $sources=[
      ['table'=>'aw_applications','kind'=>'waris','title'=>'Surat Ahli Waris'],
      ['table'=>'mobile_rt_rw_letters','kind'=>'rt_rw','title'=>'Surat Pengantar RT/RW'],
    ];
    try {
      foreach($sources as $source){
        $table=$source['table']; // Only hardcoded table names may appear in SQL.
        if(!cikoko_public_table_exists($db,$table))continue;
        $totals=$db->query('SELECT status,COUNT(*) AS total FROM '.$table.' GROUP BY status')->fetchAll();
        foreach($totals as $t){
          $bucket=cikoko_public_letter_bucket((string)$t['status']);
          $counts[$bucket]+=(int)$t['total'];
        }
        $reference=$source['kind']==='waris'
          ?'reference_no'
          :"CONCAT('RT/RW-',LPAD(id,7,'0'))";
        $query='SELECT '.$reference.' AS reference,status,created_at FROM '.$table.' ORDER BY id DESC LIMIT 80';
        foreach($db->query($query)->fetchAll() as $v){
          $ref=(string)($v['reference']??'');
          if($ref==='')continue;
          $status=(string)($v['status']??'masuk');
          $items[]=[
            'reference'=>$ref,
            'kind'=>$source['kind'],
            'title'=>$source['title'],
            'status'=>cikoko_public_letter_status($status),
            'bucket'=>cikoko_public_letter_bucket($status),
            'created_at'=>(string)($v['created_at']??''),
          ];
        }
      }
    }catch(Throwable $e){
      error_log('Cikoko public letter statistics: '.$e->getMessage());
      mobile_error('Status pelayanan belum tersedia. Coba muat ulang.',503);
    }
    usort($items,static fn($a,$b)=>strcmp($b['created_at'],$a['created_at']));
    mobile_json([
      'ok'=>true,'counts'=>$counts,
      // Recent requests only; aggregate counts cover all records, not just items.
      'items'=>array_slice($items,0,80),
      'scope'=>'Surat Ahli Waris dan Surat Pengantar RT/RW',
    ]);
}
