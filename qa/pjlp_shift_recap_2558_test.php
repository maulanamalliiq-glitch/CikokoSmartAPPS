<?php
declare(strict_types=1);
require_once __DIR__.'/../cpanel/mobile-api/pjlp_attendance_2557.php';

final class RecapFixtureStatement extends PDOStatement {
    public function __construct(private array $rows) {}
    public function execute(?array $params = null): bool { return true; }
    public function fetchAll(int $mode = PDO::FETCH_DEFAULT, mixed ...$args): array { return $this->rows; }
}

final class RecapFixtureDatabase extends PDO {
    public function __construct(private array $shifts, private array $reports) {}
    public function prepare(string $query, array $options = []): PDOStatement|false {
        return new RecapFixtureStatement(str_contains($query,'FROM pj58_shifts') ? $this->shifts : $this->reports);
    }
}

function expect_same(mixed $expected, mixed $actual, string $label): void {
    if ($expected !== $actual) throw new RuntimeException($label.': '.var_export($actual,true));
}

$night = '2026-11-30';
$short = '2026-11-29';
$shifts = [
    ['work_date'=>$night,'shift_name'=>'malam'],
    ['work_date'=>$short,'shift_name'=>'siang'],
];
$reports = [
    ['work_date'=>$night,'report_type'=>'rutin','stage'=>0],
    ['work_date'=>$night,'report_type'=>'rutin','stage'=>50],
    ['work_date'=>$night,'report_type'=>'rutin','stage'=>100],
    ['work_date'=>$night,'report_type'=>'dinas_luar','stage'=>0],
];
$attendance = [
    $night=>['checkin'=>$night.' 22:00:00','checkout'=>'2026-12-01 06:00:00'],
    $short=>['checkin'=>$short.' 13:00:00','checkout'=>$short.' 20:59:59'],
];
$config = ['attendance_weight'=>30,'work_weight'=>50,'evidence_weight'=>20];
$result = pj58_daily(new RecapFixtureDatabase($shifts,$reports),['employee','2026-11-01','2026-12-01'],$attendance,$config);
expect_same(true,$result[$night]['valid'],'Shift malam delapan jam lintas bulan');
expect_same(480,$result[$night]['minutes'],'Durasi lintas tengah malam');
expect_same('dinas_luar',$result[$night]['report_type'],'Dinas luar menggantikan sumber nilai rutin');
expect_same(1,$result[$night]['evidence_count'],'Bukti rutin tidak ikut penilaian dinas luar');
expect_same(36.67,$result[$night]['score'],'Nilai berdasarkan satu tahap dinas luar');
expect_same(4,count($result[$night]['reports']),'Kedua jenis laporan tetap tampil');
expect_same(false,$result[$short]['valid'],'Durasi kurang dari delapan jam');
expect_same(null,$result[$short]['score'],'Nilai harian belum diberikan');
echo "PJLP 2558 shift recap checks passed.\n";
