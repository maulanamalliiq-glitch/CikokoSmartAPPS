<?php
declare(strict_types=1);
/** Test lokal murni, tidak membuka database atau melakukan request produksi. */
function mobile_error(string $message,int $status=400):void {throw new DomainException($status.': '.$message);}
$GLOBALS['users']=[];
function db_read(string $table):array {return $GLOBALS['users'];}
require dirname(__DIR__).'/cpanel/mobile-api/territory.php';
function expect(bool $condition,string $label):void {if(!$condition)throw new RuntimeException('FAIL '.$label);echo "OK ".$label."\n";}
function fails(callable $fn,string $label):void {
    try{$fn();}catch(DomainException $e){echo "OK ".$label."\n";return;}
    throw new RuntimeException('FAIL '.$label);
}
expect(cikoko_area('3','RT')==='003','normalisasi RT');
expect(cikoko_area('010','RW')==='010','normalisasi RW');
fails(fn()=>cikoko_area('000','RT'),'RT nol ditolak');
fails(fn()=>cikoko_area('1000','RT'),'RT empat digit ditolak');
fails(fn()=>cikoko_area('4x','RT'),'karakter wilayah tidak valid');
$hash=password_hash('Pass-Warga-1',PASSWORD_DEFAULT);
$person=['rt'=>'003','rw'=>'010','password_hash'=>$hash];
expect(cikoko_area_update(['rt'=>'003','rw'=>'010'],$person,true)===['rt'=>'003','rw'=>'010'],'wilayah tidak berubah');
fails(fn()=>cikoko_area_update(['rt'=>'004','rw'=>'010'],$person,true),'perubahan wilayah perlu password');
expect(cikoko_area_update(['rt'=>'004','rw'=>'010','current_password'=>'Pass-Warga-1'],$person,true)===['rt'=>'004','rw'=>'010'],'perubahan wilayah dengan password');
expect(cikoko_area_update(['address'=>'Jalan Cikoko'],$person,true)===[],'API lama tetap dapat memperbarui alamat');
fails(fn()=>cikoko_area_update(['rt'=>'004'],$person,false),'akun petugas tidak dapat mengubah wilayah sendiri');
$GLOBALS['users']=[
 ['id'=>'rt003','name'=>'Ketua RT 003','role'=>'rt','active'=>true,'rt'=>'003','rw'=>'010'],
 ['id'=>'rw010','name'=>'Ketua RW 010','role'=>'rw','active'=>true,'rt'=>'','rw'=>'010'],
 ['id'=>'rt004','name'=>'Ketua RT 004','role'=>'rt','active'=>true,'rt'=>'004','rw'=>'010'],
 ['id'=>'rtOther','name'=>'Ketua RT tidak aktif','role'=>'rt','active'=>false,'rt'=>'003','rw'=>'010'],
 ['id'=>'warga','name'=>'Warga','role'=>'warga','active'=>true,'rt'=>'003','rw'=>'010'],
];
expect(cikoko_officer_for('rt','003','010')['id']==='rt003','tujuan RT tidak bergantung username');
expect(cikoko_officer_for('rw','003','010')['id']==='rw010','tujuan RW berdasarkan RW');
fails(fn()=>cikoko_officer_for('rt','007','010'),'RT tidak terdaftar ditolak');
$GLOBALS['users'][]=['id'=>'rtDuplikat','role'=>'rt','active'=>true,'rt'=>'003','rw'=>'010'];
fails(fn()=>cikoko_officer_for('rt','003','010'),'duplikasi ketua wilayah ditolak');
echo "V2513 territory tests passed.\n";
