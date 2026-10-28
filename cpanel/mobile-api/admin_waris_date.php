<?php
declare(strict_types=1);
/**
 * Cikoko 2532: ubah hanya tanggal pengajuan Ahli Waris (aw_applications.created_at).
 * Tidak mengubah lampiran, waktu upload file, nomor referensi, status, atau tabel lain.
 * Hak akses: HANYA akun admin utama, bukan admin_kelurahan atau staf.
 * Tidak membuat/mengubah skema database.
 */
function cikoko_admin_waris_date(string $method, PDO $db, array $u):void {
    if(($u['user_role']??'')!=='admin')mobile_error('Hanya Admin Utama yang dapat mengubah tanggal pengajuan Ahli Waris.',403);
    if($method!=='POST')mobile_error('Metode permintaan tidak tersedia.',405);

    $body=mobile_body();
    $idRaw=$body['id']??null;
    $dateRaw=$body['date']??null;
    if(!is_scalar($idRaw)||!ctype_digit((string)$idRaw)||(int)$idRaw<1)mobile_error('ID pengajuan tidak valid.',422);
    if(!is_string($dateRaw)||!preg_match('/^\\d{4}-\\d{2}-\\d{2}$/D',$dateRaw))mobile_error('Tanggal harus YYYY-MM-DD.',422);
    $date=DateTimeImmutable::createFromFormat('!Y-m-d',$dateRaw);
    if(!$date||$date->format('Y-m-d')!==$dateRaw)mobile_error('Tanggal pengajuan tidak valid.',422);
    if((int)$date->format('Y')<2000 || $date->format('Y-m-d')>date('Y-m-d'))
        mobile_error('Tanggal harus antara tahun 2000 dan hari ini.',422);

    $db->beginTransaction();
    try {
        $stmt=$db->prepare('SELECT id,reference_no,status,created_at FROM aw_applications WHERE id=? FOR UPDATE');
        $stmt->execute([(int)$idRaw]);
        $row=$stmt->fetch();
        if(!$row) { $db->rollBack(); mobile_error('Pengajuan Ahli Waris tidak ditemukan.',404); }
        $old=(string)($row['created_at']??'');
        $oldDate=substr($old,0,10);
        if($oldDate!==$dateRaw) {
            $time=preg_match('/\\d{2}:\\d{2}:\\d{2}/',substr($old,11),$m)?$m[0]:'00:00:00';
            $newValue=$dateRaw.' '.$time;
            $db->prepare('UPDATE aw_applications SET created_at=? WHERE id=?')->execute([$newValue,(int)$idRaw]);
            // Audit perubahan menggunakan tabel riwayat lama; status tidak diubah.
            $note='Penyesuaian tanggal pengajuan: '.$oldDate.' menjadi '.$dateRaw.' (Admin Utama)';
            $db->prepare('INSERT INTO aw_history(application_id,previous_status,new_status,actor_id,notes) VALUES(?,?,?,?,?)')
                ->execute([(int)$idRaw,(string)$row['status'],(string)$row['status'],(string)$u['user_id'],$note]);
        }
        $db->commit();
        mobile_json(['ok'=>true,'id'=>(int)$idRaw,'date'=>$dateRaw,'changed'=>$oldDate!==$dateRaw,
            'message'=>$oldDate!==$dateRaw?'Tanggal pengajuan berhasil diperbarui.':'Tanggal pengajuan tidak berubah.']);
    } catch(Throwable $e) {
        if($db->inTransaction())$db->rollBack();
        error_log('[Cikoko waris date edit] '.$e->getMessage());
        mobile_error('Tanggal pengajuan belum dapat disimpan. Periksa log server.',503);
    }
}
