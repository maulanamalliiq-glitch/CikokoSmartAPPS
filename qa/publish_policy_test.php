<?php
declare(strict_types=1);
function mobile_error(string $message,int $code=400):void {throw new RuntimeException($code.' '.$message);}
require __DIR__.'/../cpanel/mobile-api/rt_rw_service.php';
require __DIR__.'/../cpanel/mobile-api/civic_lpj.php';
require __DIR__.'/../cpanel/mobile-api/waris_staging.php';
$checks=[];
$checks['area 1 becomes 01']=cikoko_area('1')==='01';
$checks['invalid assignment is not silently normalized']=cikoko_optional_area('123')==='';
$checks['out-of-range area is refused']=cikoko_optional_area('00')==='';
$letter=['user_id'=>'resident-A','rt'=>'02','rw'=>'05'];
$checks['resident sees own letter']=cikoko_rt_can_view($letter,['user_role'=>'warga'],'resident-A',null);
$checks['other resident cannot see letter']=!cikoko_rt_can_view($letter,['user_role'=>'warga'],'resident-B',null);
$checks['matching RT may review']=cikoko_rt_can_view($letter,['user_role'=>'rt'],'officer',['rt'=>'2','rw'=>'05']);
$checks['different RT cannot review']=!cikoko_rt_can_view($letter,['user_role'=>'rt'],'officer',['rt'=>'03','rw'=>'05']);
$checks['different RW cannot review']=!cikoko_rt_can_view($letter,['user_role'=>'rw'],'officer',['rw'=>'06']);
$lpj=['user_id'=>'treasurer-A','kind'=>'lpj_rt','rt'=>'02','rw'=>'05'];
$checks['RT sees matching LPJ']=cikoko_civic_allowed($lpj,['duty'=>'rt','rt'=>'02','rw'=>'05'],'officer');
$checks['other RW cannot see LPJ']=!cikoko_civic_allowed($lpj,['duty'=>'rw','rt'=>'','rw'=>'06'],'officer');
$checks['other RT cannot see LPJ']=!cikoko_civic_allowed($lpj,['duty'=>'rt','rt'=>'01','rw'=>'05'],'officer');
$checks['owner sees own LPJ']=cikoko_civic_allowed($lpj,['duty'=>'bendahara_rt','rt'=>'02','rw'=>'05'],'treasurer-A');
$checks['split inheritance code is accepted']=cikoko_waris_stage_allowed('r4_ktp')
  &&cikoko_waris_stage_allowed('child_10_akta');
$checks['file traversal code refused']=!cikoko_waris_stage_allowed('../outside')
  &&!cikoko_waris_stage_allowed('child_11_ktp');
$failed=[];
foreach($checks as $name=>$ok){
    echo ($ok?'PASS':'FAIL')." $name\n";
    if(!$ok)$failed[]=$name;
}
if($failed)exit(1);
echo "Security policy tests passed (offline; not a production DB test).\n";
