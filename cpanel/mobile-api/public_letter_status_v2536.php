<?php
declare(strict_types=1);

/**
 * Cikoko status pelayanan surat: public reference/status ONLY.
 * Reads the existing RT/RW and Ahli Waris submissions without changing any
 * application, status, attachment, history, or database schema.
 */
function cikoko_public_letter_status_v2536():void {
    $db=mobile_db();
    $counts=['masuk'=>0,'proses'=>0,'selesai'=>0];
    $items=[];$sourcesOk=0;$errorCount=0;
    $bucket=static function(string $status,string $kind):string {
        $status=strtolower(trim($status));
        if($kind==='rt_rw'){
            if(in_array($status,['menunggu_rt','masuk','diajukan'],true))return 'masuk';
            if(in_array($status,['terverifikasi','selesai','ditolak'],true))return 'selesai';
            return 'proses';
        }
        if($status==='masuk')return 'masuk';
        if(in_array($status,['selesai','terverifikasi','ditolak'],true))return 'selesai';
        return 'proses';
    };
    $sources=[
      ['table'=>'mobile_rt_rw_letters','kind'=>'rt_rw','title'=>'Surat Pengantar RT/RW','with_reference'=>false],
      ['table'=>'aw_applications','kind'=>'waris','title'=>'Surat Ahli Waris','with_reference'=>true],
    ];
    foreach($sources as $source){
        $table=$source['table'];
        // Table names are fixed server-side literals (never client input).
        try {
            $columns=$source['with_reference']?'id,reference_no,status,created_at':'id,status,created_at';
            $stmt=$db->query('SELECT '.$columns.' FROM '.$table.' ORDER BY id DESC LIMIT 3000');
            $rows=$stmt->fetchAll(PDO::FETCH_ASSOC);
            $sourcesOk++;
            foreach($rows as $row){
                $id=(int)($row['id']??0);
                if($id<1)continue;
                $status=(string)($row['status']??'proses');
                $kind=$source['kind'];
                $state=$bucket($status,$kind);
                $counts[$state]++;
                $reference=$source['with_reference']
                  ? trim((string)($row['reference_no']??'')) : '';
                if($reference===''){
                    // Clearly labeled tracking fallback; NOT an official letter number.
                    $reference=$kind==='waris'
                      ? 'Pengajuan Ahli Waris #'.$id
                      : 'CK-RT-'.str_pad((string)$id,6,'0',STR_PAD_LEFT);
                }
                $items[]=[
                  'reference'=>$reference,
                  'kind'=>$kind,'title'=>$source['title'],
                  'status'=>$status,'bucket'=>$state,
                  'created_at'=>(string)($row['created_at']??''),
                ];
            }
        }catch(Throwable $error){
            ++$errorCount;
            error_log('Cikoko public letter status read failure for '.$table.': '.$error->getMessage());
        }
    }
    usort($items,static function(array $a,array $b):int{
        return strcmp((string)$b['created_at'],(string)$a['created_at']);
    });
    // With the current small number of submissions this includes every row.
    // Never return identities, NIK, phone, address, bodies, document links or attachments.
    $limited=array_slice($items,0,200);
    mobile_json([
        'ok'=>$sourcesOk>0,
        'counts'=>$counts,
        'items'=>$limited,
        'total_items'=>count($items),
        'limit'=>200,
        'complete'=>$errorCount===0,
        'message'=>$errorCount>0
          ? 'Sebagian informasi status surat belum dapat ditampilkan. Silakan mencoba kembali.'
          : '',
    ]);
}
