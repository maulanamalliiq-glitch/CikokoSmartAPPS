<?php
declare(strict_types=1);
require_once __DIR__.'/pjlp_shifts_2558.php';

function pj57_query(PDO $db, string $sql, array $params = []): PDOStatement {
    $statement = $db->prepare($sql);
    $statement->execute($params);
    return $statement;
}

function pj57_number(array $input, string $key, float $min, float $max): float {
    $value = $input[$key] ?? null;
    if (!is_numeric($value) || !is_finite((float)$value) || $value < $min || $value > $max) {
        mobile_error('Data lokasi atau nilai tidak valid: '.$key, 422);
    }
    return (float)$value;
}

function pj57_position(array $body): array {
    return [pj57_number($body, 'latitude', -90, 90), pj57_number($body, 'longitude', -180, 180)];
}

function pj57_radius(array $body): int {
    return (int)pj57_number($body, 'radius_m', 30, 2000);
}

function pj57_geofence(array $position, array $site): void {
    [$lat, $lon, $accuracy] = $position;
    $dlat = deg2rad((float)$site['latitude'] - $lat);
    $dlon = deg2rad((float)$site['longitude'] - $lon);
    $h = sin($dlat / 2) ** 2 + cos(deg2rad($lat)) * cos(deg2rad((float)$site['latitude'])) * sin($dlon / 2) ** 2;
    $distance = 2 * 6371000 * asin(sqrt(min(1, max(0, $h))));
    if ($distance > (int)$site['radius_m'] || $accuracy > (int)$site['radius_m']) {
        mobile_error('GPS harus akurat dan berada di dalam radius lokasi kerja.', 422);
    }
}

function pj57_photo(): string {
    $photo = $_FILES['photo'] ?? [];
    $path = $photo['tmp_name'] ?? '';
    if (($photo['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK || !is_string($path)
        || !is_uploaded_file($path) || filesize($path) > 1024 * 1024) {
        mobile_error('Ambil foto dari kamera dengan ukuran maksimal 1 MB.', 422);
    }
    $bytes = file_get_contents($path);
    $image = $bytes === false ? false : @getimagesizefromstring($bytes);
    if (!$image || $image[2] !== IMAGETYPE_JPEG || $image[0] * $image[1] > 16000000) {
        mobile_error('Foto JPEG tidak valid.', 422);
    }
    return $bytes;
}

function pj57_employee(PDO $db, string $id, array $actor): array {
    if ($actor['user_role'] === 'pjlp' && $actor['user_id'] !== $id) {
        mobile_error('Akses data pegawai ditolak.', 403);
    }
    $row = pj57_query($db, 'SELECT user_id, full_name, work_unit, hired_on, supervisor_user_id FROM pjlp_employees WHERE active=1 AND user_id=?', [$id])->fetch();
    if (!$row || ($actor['user_role'] === 'asn' && $row['supervisor_user_id'] !== $actor['user_id'])) {
        mobile_error('Profil PJLP tidak tersedia untuk akun ini.', 404);
    }
    return $row;
}

function pj57_month_data(PDO $db, array $employee, string $month, array $config): array {
    $id = $employee['user_id'];
    $start = new DateTimeImmutable($month.'-01', new DateTimeZone('Asia/Jakarta'));
    $end = $start->modify('first day of next month');
    $today = new DateTimeImmutable('today', $start->getTimezone());
    $range = [$id, $start->format('Y-m-d'), $end->format('Y-m-d')];
    $attendance = pj57_query($db, 'SELECT work_date AS date,event_type AS status,created_at FROM pj57_attendance WHERE user_id=? AND work_date>=? AND work_date<? ORDER BY work_date DESC,event_type', $range)->fetchAll();
    $weekend = pj57_query($db, 'SELECT work_date FROM pj57_schedules WHERE user_id=? AND work_date>=? AND work_date<?', $range)->fetchAll(PDO::FETCH_COLUMN);
    $jobs = pj57_query($db, 'SELECT j.id,j.title,j.latitude,j.longitude,j.radius_m,MAX(e.stage) AS progress,COUNT(e.stage) AS stages FROM pj57_jobs j LEFT JOIN pj57_job_evidence e ON e.job_id=j.id WHERE j.user_id=? AND j.work_month=? GROUP BY j.id,j.title,j.latitude,j.longitude,j.radius_m ORDER BY j.id DESC', [$id,$month])->fetchAll();
    $holidays = pj57_query($db, 'SELECT holiday_date FROM pjlp_holidays WHERE holiday_date>=? AND holiday_date<?', array_slice($range,1))->fetchAll(PDO::FETCH_COLUMN);
    $events = [];
    foreach ($attendance as $entry) {
        $events[$entry['date']][$entry['status']] = $entry['created_at'];
    }
    $daily = pj58_daily($db,$range,$events,$config);
    $days = $present = $shiftDays = $shiftComplete = $shiftEvidence = 0;
    for ($day = $start; $day < $end && $day <= $today; $day = $day->modify('+1 day')) {
        $date = $day->format('Y-m-d');
        if (($config && $date < $config['active_from']) || in_array($date,$holidays,true)
            || ($employee['hired_on'] && $date < $employee['hired_on'])
            || ((int)$day->format('N') >= 6 && !in_array($date, $weekend, true))) {
            continue;
        }
        ++$days;
        if (isset($daily[$date])) {
            ++$shiftDays;
            $shiftComplete += (int)$daily[$date]['complete'];
            $shiftEvidence += $daily[$date]['evidence_count'];
        }
        if (isset($daily[$date]) ? $daily[$date]['valid'] : isset($events[$date]['checkin'],$events[$date]['checkout'])) {
            ++$present;
        }
    }
    $completed = count(array_filter($jobs, static fn($job) => (int)$job['progress'] === 100));
    $documented = count(array_filter($jobs, static fn($job) => (int)$job['stages'] === 3));
    $totalWork = count($jobs) + $shiftDays;
    $completed += $shiftComplete;
    $documented += $shiftComplete;
    $score = $config && $month >= substr($config['active_from'],0,7) ? round(
        ($days ? $present / $days : 0) * (int)$config['attendance_weight']
        + ($totalWork ? $completed / $totalWork : 0) * (int)$config['work_weight']
        + ($totalWork ? (3 * ($documented - $shiftComplete) + $shiftEvidence) / (3 * $totalWork) : 0) * (int)$config['evidence_weight'], 2) : null;
    return [
        'employee' => $employee['full_name'], 'unit' => $employee['work_unit'],
        'attendance' => $attendance, 'jobs' => $jobs, 'daily' => array_values($daily),
        'summary' => [
            'scheduled_days' => $days, 'present_days' => $present,
            'assigned_jobs' => $totalWork, 'completed_jobs' => $completed,
            'documented_jobs' => $documented, 'monthly_score' => $score,
        ],
    ];
}

function pj57_pdf_line(array $record): string {
    $summary = $record['summary'];
    return $record['employee'].' | Hadir '.$summary['present_days'].'/'.$summary['scheduled_days']
        .' | Tugas '.$summary['completed_jobs'].'/'.$summary['assigned_jobs']
        .' | Bukti lengkap '.$summary['documented_jobs'].' | Nilai '.$summary['monthly_score'];
}

function cikoko_pjlp_2557_dispatch(string $action, string $method): void {
    $actor = mobile_auth();
    $role = (string)$actor['user_role'];
    $uid = (string)$actor['user_id'];
    $admin = $role === 'admin';
    if (!$admin && !in_array($role, ['pjlp','asn'], true)) {
        mobile_error('Akses modul PJLP ditolak.', 403);
    }
    $multipart = in_array($action, ['pjlp_attendance_submit','pjlp_job_progress','pjlp_daily_report_submit'], true);
    $read = in_array($action, ['pjlp_self_dashboard','pjlp_monitor_dashboard','pjlp_month_pdf','pjlp_team_pdf','pjlp_daily_report_photo','pjlp_attendance_photo','pjlp_evidence_photo'], true);
    if ($method !== ($read ? 'GET' : 'POST')) {
        mobile_error('Metode tidak diizinkan.', 405);
    }
    if ($multipart ? $role !== 'pjlp' : (!$read && !$admin && !($action === 'pjlp_daily_report_open' && $role === 'pjlp'))) {
        mobile_error('Akun tidak berwenang untuk tindakan ini.', 403);
    }
    $db = mobile_db();
    $now = new DateTimeImmutable('now', new DateTimeZone('Asia/Jakarta'));
    $today = $now->format('Y-m-d');
    $timestamp = $now->format('Y-m-d H:i:s');
    $currentMonth = $now->format('Y-m');
    $body = $read ? $_GET : ($multipart ? $_POST : mobile_body());
    $month = (string)($body['month'] ?? $currentMonth);
    if (!preg_match('/^20\d{2}-(0[1-9]|1[0-2])$/D', $month)) {
        mobile_error('Periode harus berformat YYYY-MM.', 422);
    }
    $config = pj57_query($db, 'SELECT * FROM pj57_config WHERE id=1')->fetch() ?: [];
    if ($action === 'pjlp_location_save') {
        [$lat, $lon] = pj57_position($body);
        $radius = pj57_radius($body);
        $weights = [];
        foreach (['attendance_weight','work_weight','evidence_weight'] as $key) {
            $value = filter_var($body[$key] ?? null, FILTER_VALIDATE_INT);
            if ($value === false || $value < 0 || $value > 100) {
                mobile_error('Bobot harus berupa bilangan bulat antara 0 dan 100.', 422);
            }
            $weights[] = $value;
        }
        if (array_sum($weights) !== 100) {
            mobile_error('Total bobot harus 100%.', 422);
        }
        pj57_query($db, 'INSERT INTO pj57_config VALUES (1,?,?,?,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE latitude=VALUES(latitude),longitude=VALUES(longitude),radius_m=VALUES(radius_m),attendance_weight=VALUES(attendance_weight),work_weight=VALUES(work_weight),evidence_weight=VALUES(evidence_weight),updated_by=VALUES(updated_by),updated_at=VALUES(updated_at)', [$lat,$lon,$radius,...$weights,$today,$uid,$timestamp]);
        mobile_json(['ok'=>true]);
    }
    if ($action === 'pjlp_monitor_dashboard' && $role === 'pjlp' || $action === 'pjlp_self_dashboard' && $role !== 'pjlp') {
        mobile_error('Dasbor ini tidak tersedia untuk akun Anda.', 403);
    }
    $target = $role === 'pjlp' ? $uid : mobile_text($body['user_id'] ?? '',80);
    if ($action === 'pjlp_monitor_dashboard' && $target === '') {
        $staff = $admin
            ? pj57_query($db, 'SELECT user_id,full_name,work_unit FROM pjlp_employees WHERE active=1 ORDER BY full_name')->fetchAll()
            : pj57_query($db, 'SELECT user_id,full_name,work_unit FROM pjlp_employees WHERE active=1 AND supervisor_user_id=? ORDER BY full_name', [$uid])->fetchAll();
        mobile_json(['ok'=>true,'staff'=>$staff,'config'=>(object)($admin ? $config : [])]);
    }
    if ($action === 'pjlp_team_pdf') {
        if ($role === 'pjlp') mobile_error('Akses rekap tim ditolak.', 403);
        $unit = mobile_text($body['unit'] ?? '',160);
        if ($unit === '') mobile_error('Pilih unit kerja.', 422);
        $sql = 'SELECT a.snapshot FROM pj57_month_approvals a JOIN pjlp_employees e ON e.user_id=a.user_id WHERE a.work_month=? AND e.work_unit=?';
        $params = [$month,$unit];
        if (!$admin) {
            $sql .= ' AND e.supervisor_user_id=?';
            $params[] = $uid;
        }
        $lines = ['Rekap PJLP per unit', 'Unit '.$unit.' | Periode '.$month, 'Pegawai dengan rekap disahkan'];
        foreach (pj57_query($db,$sql.' ORDER BY e.full_name',$params)->fetchAll(PDO::FETCH_COLUMN) as $snapshot) {
            $lines[] = pj57_pdf_line(json_decode($snapshot,true,512,JSON_THROW_ON_ERROR));
        }
        if (count($lines) === 3) mobile_error('Belum ada rekap yang disahkan untuk unit ini.', 404);
        require_once __DIR__.'/pdf_native.php';
        cikoko_pdf_render('Rekap-PJLP-Unit-'.$month.'.pdf',$lines);
    }
    $employee = pj57_employee($db, $target, $actor);
    if (in_array($action,['pjlp_daily_report_open','pjlp_daily_report_submit','pjlp_daily_report_photo'],true)) {
        pj58_report_action($db,$action,$actor,$employee,$body,$now);
    }
    if (in_array($action,['pjlp_attendance_photo','pjlp_evidence_photo'],true)) {
        if ($action === 'pjlp_attendance_photo') {
            $photo = pj57_query($db,'SELECT photo FROM pj57_attendance WHERE user_id=? AND work_date=? AND event_type=?',
                [$target,(string)($body['date'] ?? ''),(string)($body['type'] ?? '')])->fetchColumn();
        } else {
            $photo = pj57_query($db,'SELECT e.photo FROM pj57_job_evidence e JOIN pj57_jobs j ON j.id=e.job_id WHERE j.user_id=? AND e.job_id=? AND e.stage=?',
                [$target,(int)($body['job_id'] ?? 0),(int)($body['progress'] ?? -1)])->fetchColumn();
        }
        if ($photo === false) mobile_error('Foto tidak tersedia.',404);
        header('Content-Type: image/jpeg');
        header('Content-Length: '.strlen($photo));
        echo $photo;
        exit;
    }
    if ($action === 'pjlp_schedule_save') {
        $date = (string)($body['date'] ?? '');
        $day = DateTimeImmutable::createFromFormat('!Y-m-d',$date,$now->getTimezone());
        if (!$day || $day->format('Y-m-d') !== $date || $date <= $today || (int)$day->format('N') < 6) {
            mobile_error('Pilih tanggal akhir pekan mendatang.', 422);
        }
        [$lat,$lon] = pj57_position($body);
        $radius = pj57_radius($body);
        pj57_query($db, 'INSERT INTO pj57_schedules VALUES (?,?,?,?,?,?) ON DUPLICATE KEY UPDATE latitude=VALUES(latitude),longitude=VALUES(longitude),radius_m=VALUES(radius_m),scheduled_by=VALUES(scheduled_by)', [$target,$date,$lat,$lon,$radius,$uid]);
        mobile_json(['ok'=>true]);
    }
    if ($action === 'pjlp_job_assign') {
        $title = mobile_text($body['title'] ?? '',200);
        if ($title === '' || $month < $currentMonth) mobile_error('Isi judul dan pilih periode berjalan atau mendatang.',422);
        [$lat,$lon] = pj57_position($body);
        pj57_query($db, 'INSERT INTO pj57_jobs (user_id,title,work_month,latitude,longitude,radius_m,assigned_by,created_at) VALUES (?,?,?,?,?,?,?,?)', [$target,$title,$month,$lat,$lon,pj57_radius($body),$uid,$timestamp]);
        mobile_json(['ok'=>true]);
    }
    if ($multipart) {
        if (!$config) mobile_error('Modul belum dikonfigurasi Admin Utama.',503);
        $position = [...pj57_position($body),pj57_number($body,'accuracy_m',0.1,100)];
        if ($action === 'pjlp_attendance_submit') {
            pj58_attendance($db,$uid,$body,$config,$now,$position,pj57_photo());
        }
        $jobId = filter_var($body['job_id'] ?? null,FILTER_VALIDATE_INT);
        $stage = filter_var($body['progress'] ?? null,FILTER_VALIDATE_INT);
        if (!$jobId || !in_array($stage,[0,50,100],true)) mobile_error('Tahap pekerjaan tidak valid.',422);
        $job = pj57_query($db,'SELECT * FROM pj57_jobs WHERE id=? AND user_id=? AND work_month=?',[$jobId,$uid,$currentMonth])->fetch();
        if (!$job) mobile_error('Penugasan bulan berjalan tidak ditemukan.',404);
        pj57_geofence($position,$job);
        if ($stage !== 0 && !pj57_query($db,'SELECT 1 FROM pj57_job_evidence WHERE job_id=? AND stage=?',[$jobId,$stage-50])->fetchColumn()) {
            mobile_error('Kirim bukti tahap sebelumnya terlebih dahulu.',422);
        }
        $photo = pj57_photo();
        $sql = 'INSERT INTO pj57_job_evidence VALUES (?,?,?,?,?,?,?,?)';
        $params = [$jobId,$stage,...$position,$photo,hash('sha256',$photo),$timestamp];
        try {
            pj57_query($db,$sql,$params);
        } catch (PDOException $error) {
            if ((int)($error->errorInfo[1] ?? 0) !== 1062) throw $error;
            mobile_error('Catatan sudah tersimpan atau foto sudah pernah dipakai. Muat ulang data.',409);
        }
        mobile_json(['ok'=>true,'message'=>'Catatan tersimpan.']);
    }
    $approved = pj57_query($db,'SELECT snapshot,approved_by,approved_at FROM pj57_month_approvals WHERE user_id=? AND work_month=?',[$target,$month])->fetch();
    $data = $approved ? json_decode($approved['snapshot'],true,512,JSON_THROW_ON_ERROR) : pj57_month_data($db,$employee,$month,$config);
    if ($action === 'pjlp_month_approve') {
        if ($month >= $currentMonth || $data['summary']['monthly_score'] === null) {
            mobile_error('Pilih bulan yang sudah berakhir dan atur bobot penilaian.',422);
        }
        if (!$approved) {
            $active = pj58_active_shift($db,$target,$now);
            if ($active && substr($active['work_date'],0,7) === $month) {
                mobile_error('Shift terakhir pada periode ini masih aktif.',409);
            }
            pj57_query($db,'INSERT INTO pj57_month_approvals VALUES (?,?,?,?,?) ON DUPLICATE KEY UPDATE approved_at=approved_at',[$target,$month,json_encode($data,JSON_THROW_ON_ERROR),$actor['username'],$timestamp]);
        }
        mobile_json(['ok'=>true]);
    }
    if ($action === 'pjlp_month_pdf') {
        if (!$approved) mobile_error('Rekap belum disahkan Admin Utama.',409);
        require_once __DIR__.'/pdf_native.php';
        $lines = ['Rekap Bulanan PJLP', 'Kelurahan Cikoko | Periode '.$month, pj57_pdf_line($data),
            'Unit '.$data['unit'], 'Disahkan Admin Utama '.$approved['approved_by'].' pada '.$approved['approved_at'].' WIB', '',
            'Riwayat Absensi'];
        foreach ($data['attendance'] as $event) {
            $lines[] = $event['created_at'].' WIB - '.($event['status'] === 'checkin' ? 'Masuk' : 'Pulang');
        }
        if (!empty($data['daily'])) $lines[] = 'Rekap Shift dan Laporan Harian';
        foreach ($data['daily'] ?? [] as $day) {
            $lines[] = $day['date'].' | '.ucfirst($day['shift']).' | '.$day['minutes'].' menit | '
                .($day['report_type'] === 'dinas_luar' ? 'Dinas Luar' : 'Rutin').' | Nilai '.($day['score'] ?? '-');
        }
        $lines[] = 'Bukti Pekerjaan';
        foreach ($data['jobs'] as $job) {
            $lines[] = $job['title'].' | '.(int)$job['stages'].' dari 3 tahap terdokumentasi';
        }
        cikoko_pdf_render('Rekap-PJLP-'.$month.'.pdf',$lines);
    }
    $data['approved'] = (bool)$approved;
    $data['server_date'] = $today;
    $data['configured'] = (bool)$config;
    if ($role === 'pjlp') {
        $data['active_shift'] = pj58_active_shift($db,$uid,$now);
        $data['checked_in_today'] = (bool)pj57_query($db,"SELECT 1 FROM pj57_attendance WHERE user_id=? AND work_date=? AND event_type='checkin'",[$uid,$today])->fetchColumn();
    }
    mobile_json(['ok'=>true]+$data);
}
