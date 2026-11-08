<?php
declare(strict_types=1);
class GovResponse extends RuntimeException {public array $data;public int $status;function __construct(array $data,int $status){$this->data=$data;$this->status=$status;parent::__construct(json_encode($data));}}
function mobile_error(string $message,int $code=400):void {throw new GovResponse(['error'=>$message],$code);}
function mobile_json(array $data,int $code=200):void {throw new GovResponse($data,$code);}
function mobile_text($value,int $max=1000):string{return substr(trim((string)$value),0,$max);}
function mobile_body():array {return $GLOBALS['body']??[];}
function db_read(string $key):array {if($key!=='portal_users')return $GLOBALS['homeSaved']??[];return [['id'=>'a','rt'=>'1','rw'=>'2'],['id'=>'b','rt'=>'','rw'=>'']];}
function mobile_emit(...$args):void {$GLOBALS['emits'][]=$args;}
function mobile_need(array $u,string $key):void {if(!mobile_can($u,$key))mobile_error('Tidak diizinkan',403);}
function mobile_can(array $u,string $key):bool {return in_array($key,$u['caps']??[],true);}
function mobile_auth():array{return $GLOBALS['actor']??['user_role'=>'warga'];}
function db_write(string $key,array $value):bool{$GLOBALS['homeSaved']=$value;return true;}
require __DIR__.'/../cpanel/mobile-api/governance_review.php';
require __DIR__.'/../cpanel/mobile-api/home_slides.php';
function check(bool $condition,string $name):void{if(!$condition)throw new RuntimeException($name);echo "PASS $name\n";}
function response(callable $fn):GovResponse{try{$fn();}catch(GovResponse $e){return $e;}throw new RuntimeException('Expected response');}
$db=new PDO('sqlite::memory:',null,null,[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION,PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC]);
$db->exec("CREATE TABLE mobile_reports(id INTEGER PRIMARY KEY,user_id TEXT,user_name TEXT,kind TEXT,status TEXT,created_at TEXT,notes TEXT,photo_name TEXT)");
$db->exec("CREATE TABLE mobile_ppsu_reports(id INTEGER PRIMARY KEY,user_id TEXT,name TEXT,activity TEXT,photos_json TEXT,created_at TEXT,deleted_at TEXT)");
$db->exec("CREATE TABLE mobile_fkdm_reports(id INTEGER PRIMARY KEY,user_id TEXT,full_name TEXT,activity TEXT,photos_json TEXT,created_at TEXT,deleted_at TEXT)");
$db->exec("CREATE TABLE aw_applications(id INTEGER PRIMARY KEY,account_id TEXT,applicant_name TEXT,reference_no TEXT,status TEXT,created_at TEXT)");
$db->exec("INSERT INTO mobile_reports VALUES(1,'a','Pelapor A','jumantik','masuk','2026-11-01','Kegiatan','')");
$db->exec("INSERT INTO mobile_ppsu_reports VALUES(1,'a','Pelapor A','Bersih','[]','2026-11-02',NULL),(2,'a','Terhapus','Hapus','[]','2026-11-03','2026-11-04')");
$db->exec("INSERT INTO mobile_fkdm_reports VALUES(1,'b','Pelapor B','Kegiatan','[]','2026-11-04',NULL)");
$db->exec("INSERT INTO aw_applications VALUES(1,'b','Pemohon B','AW-TEST0001','selesai','2026-11-05')");
$asn=['user_id'=>'officer','caps'=>['reports:view','reports:verify','waris:view','waris:verify','monitoring:view']];
$readOnly=['user_id'=>'reader','caps'=>['reports:view']];$warga=['user_id'=>'a','caps'=>[]];
foreach(['officer_reports','officer_report_detail','officer_report_photo','territory_monitoring','officer_waris','support_admin_thread'] as $action){
 $r=response(fn()=>cikoko_governance_dispatch($action,'GET',$db,$warga));check($r->status===403,'warga denied '.$action);
}
$r=response(fn()=>cikoko_governance_dispatch('officer_reports','GET',$db,$asn));
check(count($r->data['items'])===3,'all report sources combined without deleted field rows');
check($r->data['can_verify']===true,'ASN can verify');
$r=response(fn()=>cikoko_gov_decide($db,$readOnly,['source'=>'report','id'=>1,'status'=>'selesai']));check($r->status===403,'view-only cannot write');
$r=response(fn()=>cikoko_gov_decide($db,$asn,['source'=>'ppsu','id'=>1,'status'=>'revisi']));check($r->status===422,'revision requires reason');
cikoko_gov_decide($db,$asn,['source'=>'ppsu','id'=>1,'status'=>'revisi','notes'=>'Tambahkan dokumentasi.']);
check($GLOBALS['emits'][0][3]==='personal' && $GLOBALS['emits'][0][4]==='a','only report owner notified');
cikoko_gov_decide($db,$asn,['source'=>'report','id'=>1,'status'=>'selesai']);
check($db->query('SELECT status FROM mobile_reports WHERE id=1')->fetchColumn()==='selesai','general status persisted');
check($db->query('SELECT COUNT(*) FROM mobile_officer_reviews')->fetchColumn()==2,'verification audit persisted');
$all=cikoko_gov_collect($db);$ppsu=array_values(array_filter($all['items'],fn($r)=>$r['source']==='ppsu'));
check($ppsu[0]['status']==='revisi','PPSU review persists across reads');
$r=response(fn()=>cikoko_gov_decide($db,$asn,['source'=>'waris','id'=>1,'status'=>'selesai']));check($r->status===404,'report writer cannot mutate waris through alternate source');
$r=response(fn()=>cikoko_governance_dispatch('territory_monitoring','GET',$db,$asn));
check($r->data['total']===4,'monitoring totals all current records');
check(count($r->data['areas'])===2,'known and unknown area kept separate');
check(!str_contains(json_encode($r->data),'Pelapor')&&!str_contains(json_encode($r->data),'Pemohon'),'monitoring omits personal identities');
$_GET=['category'=>'ppsu'];$r=response(fn()=>cikoko_governance_dispatch('officer_reports','GET',$db,$asn));check($r->data['total']===1,'category filtering');
$_GET=[];
$r=response(fn()=>cikoko_governance_dispatch('officer_waris','GET',$db,$asn));check(count($r->data['items'])===1&&$r->data['items'][0]['reference']==='AW-TEST0001','dedicated waris list uses exact reference');
// Totals must include records beyond the first 50 displayed items.
for($id=2;$id<=65;$id++)$db->exec("INSERT INTO mobile_reports VALUES($id,'a','Pelapor A','kegiatan','masuk','2026-11-01','','')");
$r=response(fn()=>cikoko_governance_dispatch('officer_reports','GET',$db,$asn));check(count($r->data['items'])===50 && $r->data['total']===67 && $r->data['next_offset']===50,'paging keeps complete total');
$_GET=['offset'=>'50'];$r=response(fn()=>cikoko_governance_dispatch('officer_reports','GET',$db,$asn));check(count($r->data['items'])===17 && $r->data['next_offset']===null,'last page complete');
$_GET=[];$r=response(fn()=>cikoko_governance_dispatch('territory_monitoring','GET',$db,$asn));check($r->data['total']===68,'monitoring is not truncated by list paging');
$_GET=[];
$db->exec("CREATE TABLE cikoko_lpj_docs(id INTEGER PRIMARY KEY,owner_id TEXT,owner_name TEXT,kind TEXT,rt TEXT,rw TEXT,status TEXT,revision INTEGER,payload_json TEXT,created_at TEXT)");
$db->exec("INSERT INTO cikoko_lpj_docs VALUES(1,'a','Bendahara','lpj_rt','001','002','menunggu_ketua',1,'{}','2026-11-08')");
$r=response(fn()=>cikoko_gov_decide($db,$asn,['source'=>'lpj','id'=>1,'status'=>'selesai']));check($r->status===409,'LPJ requires matching displayed revision');
cikoko_gov_decide($db,$asn,['source'=>'lpj','id'=>1,'status'=>'selesai','revision'=>1]);
check($db->query('SELECT status FROM cikoko_lpj_docs WHERE id=1')->fetchColumn()==='menunggu_ketua','administrative check cannot approve financial workflow');
$db->exec('UPDATE cikoko_lpj_docs SET revision=2 WHERE id=1');
$all=cikoko_gov_collect($db);$lpj=array_values(array_filter($all['items'],fn($r)=>$r['source']==='lpj'));
check($lpj[0]['status']==='masuk','new LPJ revision requires new verification');
check($lpj[0]['rt']==='01' && $lpj[0]['rw']==='02','LPJ official territory normalized');
$db->exec("CREATE TABLE mobile_chat(id INTEGER PRIMARY KEY,user_id TEXT,sender TEXT,message TEXT,created_at TEXT)");
$db->exec("INSERT INTO mobile_chat VALUES(1,'a','warga','Pesan A','2026-11-08'),(2,'b','warga','Pesan B','2026-11-08')");
$_GET=['user_id'=>'a'];$admin=['user_id'=>'admin','caps'=>['chat:reply']];
$r=response(fn()=>cikoko_governance_dispatch('support_admin_thread','GET',$db,$admin));
check(count($r->data['messages'])===1&&$r->data['messages'][0]['message']==='Pesan A','admin thread never mixes residents');
$GLOBALS['actor']=['user_role'=>'warga'];
$r=response(fn()=>cikoko_home_slides_dispatch('home_slides_save','POST'));check($r->status===403,'citizen cannot edit home images');
$GLOBALS['actor']=['user_role'=>'admin'];$GLOBALS['body']=['slides'=>array_fill(0,6,str_repeat('a',40).'.jpg')];
$r=response(fn()=>cikoko_home_slides_dispatch('home_slides_save','POST'));check($r->status===422,'more than five images rejected');
$GLOBALS['body']=['slides'=>[str_repeat('a',40).'.jpg']];
$r=response(fn()=>cikoko_home_slides_dispatch('home_slides_save','POST'));check($r->status===422,'ordinary private file cannot become public home image');
$GLOBALS['homeSaved']=[['name'=>'../../private/photo.jpg']];
check(cikoko_home_slides()===[],'path traversal cannot enter published image list');
echo "ALL GOVERNANCE TESTS PASSED\n";
