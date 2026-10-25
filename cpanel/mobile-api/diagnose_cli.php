<?php
/** Cikoko v2501: pemeriksaan aman dan hanya-baca untuk operator cPanel.
 * Jalankan via SSH/cPanel Terminal, bukan URL publik:
 * php /home/USER/public_html/mobile-api/diagnose_cli.php
 * Hasil hanya angka agregat; jangan unggah konfigurasi rahasia atau data pribadi.
 */
declare(strict_types=1);
if (PHP_SAPI !== 'cli') {
    http_response_code(403);
    exit('Forbidden');
}
require __DIR__.'/bootstrap.php';
$issues = [];
$path = getenv('CIKOKO_FIREBASE_SA') ?: '';
$hasServiceAccount = $path !== '' && is_file($path) && is_readable($path);
if (!$hasServiceAccount) $issues[] = 'FCM_SERVICE_ACCOUNT_NOT_CONFIGURED';
$db = mobile_db();
$counts = [];
foreach ([
    'perangkat_terdaftar' => 'SELECT COUNT(*) FROM mobile_devices',
    'event_belum_dikirim' => 'SELECT COUNT(*) FROM mobile_events WHERE dispatched_at IS NULL',
    'event_sudah_dikirim' => 'SELECT COUNT(*) FROM mobile_events WHERE dispatched_at IS NOT NULL',
    'event_sudah_dibaca' => 'SELECT COUNT(*) FROM mobile_event_reads'
] as $key => $sql) {
    try { $counts[$key] = (int)$db->query($sql)->fetchColumn(); }
    catch (Throwable $e) {
        error_log('Cikoko diagnostic '.$key.': '.$e->getMessage());
        $counts[$key] = null;
        $issues[] = 'DB_QUERY_ERROR_'.$key;
    }
}
if (($counts['perangkat_terdaftar'] ?? 0) === 0) $issues[] = 'NO_REGISTERED_FCM_DEVICES';
if (($counts['event_belum_dikirim'] ?? 0) > 0) $issues[] = 'PENDING_FCM_EVENTS_CHECK_CRON';
echo json_encode([
    'service' => 'CIKOKO_FCM_DIAGNOSTIC',
    'service_account_configured' => $hasServiceAccount,
    'counts' => $counts,
    'issues' => array_values(array_unique($issues)),
    'note' => 'Status sukses pengiriman memerlukan pemeriksaan cron dan pesan masuk perangkat Android.'
], JSON_PRETTY_PRINT|JSON_UNESCAPED_UNICODE).PHP_EOL;
