<?php
declare(strict_types=1);
/**
 * Cikoko Smart 2618 — PUBLIC yearly Bank Sampah total for Beranda.
 * Read-only: only confirmed archive and closed live sessions.
 * Requires the 2617 Bank Sampah schema and the existing bootstrap.php.
 */
ini_set('display_errors', '0');
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store, max-age=0');
header('X-Content-Type-Options: nosniff');
if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'GET') {
    header('Allow: GET');
    http_response_code(405);
    echo json_encode(['ok' => false, 'error' => 'Metode tidak diizinkan.'], JSON_UNESCAPED_UNICODE);
    exit;
}
set_exception_handler(static function (Throwable $e): void {
    error_log('[Cikoko Bank Sampah Public 2618] ' . $e->getMessage());
    if (!headers_sent()) http_response_code(503);
    echo json_encode(['ok' => false, 'error' => 'Rekap tahunan belum tersedia.'], JSON_UNESCAPED_UNICODE);
});
require_once __DIR__ . '/bootstrap.php';
$today = new DateTimeImmutable('now', new DateTimeZone('Asia/Jakarta'));
$rawYear = $_GET['year'] ?? $today->format('Y');
$year = filter_var($rawYear, FILTER_VALIDATE_INT);
if ($year === false || $year < 2020 || $year > 2100) {
    http_response_code(422);
    echo json_encode(['ok' => false, 'error' => 'Tahun rekap tidak valid.'], JSON_UNESCAPED_UNICODE);
    exit;
}
$start = sprintf('%04d-01-01', $year);
$end = sprintf('%04d-01-01', $year + 1);
$todayDate = $today->format('Y-m-d');
$db = mobile_db();

// Draft/open sessions never appear in the publicly visible total.
$live = $db->prepare('SELECT
    COALESCE(SUM(e.weight_kg), 0) AS weight_kg,
    COALESCE(SUM(e.amount_rp), 0) AS amount_rp,
    COUNT(e.id) AS entries
    FROM mobile_bank_sampah_sessions_2610 s
    JOIN mobile_bank_sampah_entries_2610 e
      ON e.session_id=s.id AND e.voided_at IS NULL
    WHERE s.status = "closed"
      AND s.session_date >= ? AND s.session_date < ?
      AND s.session_date <= ?');
$live->execute([$start, $end, $todayDate]);
$liveRow = $live->fetch(PDO::FETCH_ASSOC) ?: [];

// Historical archive is confirmed-only and suppressed on dates with
// published live entries so a past weighing session cannot count twice.
$archive = $db->prepare('SELECT
    COALESCE(SUM(a.weight_kg), 0) AS weight_kg,
    COALESCE(SUM(a.amount_rp), 0) AS amount_rp,
    COUNT(*) AS entries
    FROM mobile_bank_sampah_archive_entries_2026 a
    WHERE a.review_status = "confirmed"
      AND a.session_date >= ? AND a.session_date < ?
      AND a.session_date <= ?
      AND NOT EXISTS (
          SELECT 1 FROM mobile_bank_sampah_sessions_2610 s
          JOIN mobile_bank_sampah_entries_2610 e
            ON e.session_id=s.id AND e.voided_at IS NULL
          WHERE s.session_date=a.session_date
            AND s.status="closed"
      )');
$archive->execute([$start, $end, $todayDate]);
$archiveRow = $archive->fetch(PDO::FETCH_ASSOC) ?: [];

$grams = (int) round((float) ($liveRow['weight_kg'] ?? 0) * 1000)
       + (int) round((float) ($archiveRow['weight_kg'] ?? 0) * 1000);
$amount = (int) ($liveRow['amount_rp'] ?? 0) + (int) ($archiveRow['amount_rp'] ?? 0);
$entries = (int) ($liveRow['entries'] ?? 0) + (int) ($archiveRow['entries'] ?? 0);
echo json_encode([
    'ok' => true,
    'year' => $year,
    'totals' => [
        'weight_kg' => number_format($grams / 1000, 3, '.', ''),
        'amount_rp' => $amount,
        'entries' => $entries,
    ],
    'published_only' => true,
    'as_of' => $todayDate,
], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
