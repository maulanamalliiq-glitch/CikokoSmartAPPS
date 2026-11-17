<?php
declare(strict_types=1);

function pj58_active_shift(PDO $db, string $uid, DateTimeImmutable $now): ?array {
    $row = pj57_query($db, "SELECT a.work_date,a.created_at AS checkin_at,s.shift_name
        FROM pj57_attendance a LEFT JOIN pj58_shifts s ON s.user_id=a.user_id AND s.work_date=a.work_date
        LEFT JOIN pj57_attendance p ON p.user_id=a.user_id AND p.work_date=a.work_date AND p.event_type='checkout'
        WHERE a.user_id=? AND a.event_type='checkin' AND p.user_id IS NULL AND a.created_at>=?
        ORDER BY a.created_at DESC LIMIT 1",
        [$uid,$now->modify('-24 hours')->format('Y-m-d H:i:s')])->fetch();
    return $row ?: null;
}

function pj58_report_action(PDO $db, string $action, array $actor, array $employee, array $body, DateTimeImmutable $now): void {
    $uid = $employee['user_id'];
    $mode = $body['report_type'] ?? '';
    $stage = filter_var($body['progress'] ?? null, FILTER_VALIDATE_INT);
    if (!in_array($mode,['rutin','dinas_luar'],true) || !in_array($stage,[0,50,100],true)) {
        mobile_error('Jenis laporan atau tahap tidak valid.',422);
    }
    if ($action === 'pjlp_daily_report_photo') {
        $photo = pj57_query($db,'SELECT photo FROM pj58_reports WHERE user_id=? AND work_date=? AND report_type=? AND stage=? AND submitted_at IS NOT NULL',
            [$uid,(string)($body['date'] ?? ''),$mode,$stage])->fetchColumn();
        if (!is_string($photo)) mobile_error('Foto tidak tersedia.',404);
        header('Content-Type: image/jpeg');
        header('Content-Length: '.strlen($photo));
        echo $photo;
        exit;
    }
    if ($actor['user_role'] !== 'pjlp') mobile_error('Hanya PJLP dapat mengisi laporannya sendiri.',403);
    $timestamp = $now->format('Y-m-d H:i:s');
    $identity = [$uid,(string)($body['date'] ?? ''),$mode,$stage];
    $photo = $position = $description = null;
    if ($action === 'pjlp_daily_report_submit') {
        $description = mobile_text($body['description'] ?? '',1600);
        if ($description === '') mobile_error('Keterangan wajib diisi.',422);
        $position = [...pj57_position($body),pj57_number($body,'accuracy_m',0.1,100)];
        $photo = pj57_photo();
    }
    $db->beginTransaction();
    try {
        pj57_query($db,'SELECT user_id FROM pjlp_employees WHERE user_id=? FOR UPDATE',[$uid]);
        $shift = pj58_active_shift($db,$uid,$now);
        if (!$shift || !$shift['shift_name']) mobile_error('Absen masuk dengan pilihan shift terlebih dahulu.',422);
        $date = $shift['work_date'];
        if ($action === 'pjlp_daily_report_open') {
            if ($stage !== 0 && !pj57_query($db,'SELECT 1 FROM pj58_reports WHERE user_id=? AND work_date=? AND report_type=? AND stage=? AND submitted_at IS NOT NULL',[$uid,$date,$mode,$stage-50])->fetchColumn()) {
                mobile_error('Kirim laporan tahap sebelumnya terlebih dahulu.',422);
            }
            pj57_query($db,'INSERT INTO pj58_reports (user_id,work_date,report_type,stage,full_name,opened_at) VALUES (?,?,?,?,?,?)
                ON DUPLICATE KEY UPDATE opened_at=opened_at',[$uid,$date,$mode,$stage,$employee['full_name'],$timestamp]);
            $draft = pj57_query($db,'SELECT work_date,full_name,opened_at,submitted_at FROM pj58_reports WHERE user_id=? AND work_date=? AND report_type=? AND stage=?',[$uid,$date,$mode,$stage])->fetch();
            $db->commit();
            mobile_json(['ok'=>true,'report'=>$draft]);
        }
        if ($identity[1] !== $date) mobile_error('Shift sudah berubah. Buka ulang formulir laporan.',409);
        $updated = pj57_query($db,'UPDATE pj58_reports SET description=?,latitude=?,longitude=?,accuracy_m=?,photo=?,photo_hash=?,submitted_at=?
            WHERE user_id=? AND work_date=? AND report_type=? AND stage=? AND submitted_at IS NULL',
            [$description,...$position,$photo,hash('sha256',$photo),$timestamp,...$identity]);
        if ($updated->rowCount() !== 1) mobile_error('Laporan sudah terkirim atau formulir belum dibuka.',409);
        $db->commit();
    } catch (Throwable $error) {
        if ($db->inTransaction()) $db->rollBack();
        if ($error instanceof PDOException && (int)($error->errorInfo[1] ?? 0) === 1062) {
            mobile_error('Foto sudah pernah digunakan. Ambil foto baru.',409);
        }
        throw $error;
    }
    mobile_json(['ok'=>true,'submitted_at'=>$timestamp]);
}

function pj58_attendance(PDO $db, string $uid, array $body, array $config, DateTimeImmutable $now, array $position, string $photo): void {
    $event = $body['type'] ?? '';
    $shiftName = $body['shift'] ?? '';
    $timestamp = $now->format('Y-m-d H:i:s');
    if (!in_array($event,['checkin','checkout'],true)) mobile_error('Jenis absensi tidak valid.',422);
    if ($event === 'checkin' && !in_array($shiftName,['pagi','siang','malam'],true)) {
        mobile_error('Pilih shift pagi, siang, atau malam.',422);
    }
    $db->beginTransaction();
    try {
        pj57_query($db,'SELECT user_id FROM pjlp_employees WHERE user_id=? FOR UPDATE',[$uid]);
        $shift = pj58_active_shift($db,$uid,$now);
        if ($event === 'checkin' && $shift) mobile_error('Selesaikan absensi pulang shift yang masih aktif.',409);
        if ($event === 'checkout' && !$shift) mobile_error('Tidak ada shift aktif untuk absen pulang.',422);
        $date = $shift['work_date'] ?? $now->format('Y-m-d');
        // The shift start date determines the geofence rule for both punches.
        $weekday = (int)(new DateTimeImmutable($date,$now->getTimezone()))->format('N');
        if ($weekday >= 6) {
            $site = pj57_query($db,'SELECT latitude,longitude,radius_m FROM pj57_schedules WHERE user_id=? AND work_date=?',[$uid,$date])->fetch();
            if (!$site) mobile_error('Tidak ada jadwal akhir pekan.',422);
            pj57_geofence($position,$site);
        } elseif ($weekday !== 3) {
            pj57_geofence($position,$config);
        }
        pj57_query($db,'INSERT INTO pj57_attendance VALUES (?,?,?,?,?,?,?,?,?)',
            [$uid,$date,$event,...$position,$photo,hash('sha256',$photo),$timestamp]);
        if ($event === 'checkin') {
            pj57_query($db,'INSERT INTO pj58_shifts (user_id,work_date,shift_name) VALUES (?,?,?)',[$uid,$date,$shiftName]);
        }
        $db->commit();
    } catch (Throwable $error) {
        if ($db->inTransaction()) $db->rollBack();
        if ($error instanceof PDOException && (int)($error->errorInfo[1] ?? 0) === 1062) {
            mobile_error('Absensi sudah tercatat atau selfie sudah pernah digunakan.',409);
        }
        throw $error;
    }
    mobile_json(['ok'=>true,'message'=>'Absensi tersimpan.']);
}

function pj58_daily(PDO $db, array $range, array $events, array $config): array {
    $shifts = pj57_query($db,'SELECT work_date,shift_name FROM pj58_shifts WHERE user_id=? AND work_date>=? AND work_date<? ORDER BY work_date DESC',$range)->fetchAll();
    $reports = pj57_query($db,'SELECT work_date,report_type,stage,full_name,opened_at,submitted_at,description FROM pj58_reports
        WHERE user_id=? AND work_date>=? AND work_date<? AND submitted_at IS NOT NULL ORDER BY stage',$range)->fetchAll();
    $byDay = [];
    foreach ($reports as $report) {
        $byDay[$report['work_date']][$report['report_type']][] = $report;
    }
    $days = [];
    $zone = new DateTimeZone('Asia/Jakarta');
    foreach ($shifts as $shift) {
        $date = $shift['work_date'];
        $start = $events[$date]['checkin'] ?? null;
        $end = $events[$date]['checkout'] ?? null;
        $seconds = $start && $end
            ? (new DateTimeImmutable($end,$zone))->getTimestamp() - (new DateTimeImmutable($start,$zone))->getTimestamp()
            : 0;
        $types = $byDay[$date] ?? [];
        $mode = isset($types['dinas_luar']) ? 'dinas_luar' : 'rutin';
        $evidence = $types[$mode] ?? [];
        $valid = $seconds >= 8 * 3600;
        $complete = count($evidence) === 3;
        $score = $config && $valid ? round(
            (int)$config['attendance_weight']
            + ($complete ? (int)$config['work_weight'] : 0)
            + count($evidence)/3*(int)$config['evidence_weight'], 2) : null;
        $days[$date] = [
            'date'=>$date,'shift'=>$shift['shift_name'],'checkin_at'=>$start,'checkout_at'=>$end,
            'minutes'=>max(0,intdiv($seconds,60)),'valid'=>$valid,'score'=>$score,'report_type'=>$mode,
            'reports'=>array_merge($types['rutin'] ?? [],$types['dinas_luar'] ?? []),
            'complete'=>$complete,'evidence_count'=>count($evidence),
        ];
    }
    return $days;
}
