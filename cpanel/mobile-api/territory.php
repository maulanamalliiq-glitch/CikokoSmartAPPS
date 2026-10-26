<?php
declare(strict_types=1);

/** Normalisasi RT/RW: minimal 2 digit untuk tampilan RT 02 / RW 05; data lama 002/005 tetap dikenali. */
function cikoko_area($value,string $label,bool $required=true):string {
    $input=trim((string)$value);
    if($input==='') {
        if($required)mobile_error('Nomor '.$label.' wajib diisi.',422);
        return '';
    }
    if(!preg_match('/^[0-9]{1,3}$/D',$input) || (int)$input<1 || (int)$input>999) {
        mobile_error('Nomor '.$label.' harus angka 1 sampai 999.',422);
    }
    return str_pad((string)(int)$input,2,'0',STR_PAD_LEFT);
}
function cikoko_user_by_id(string $uid):?array {
    foreach(db_read('portal_users') as $person)
        if((string)($person['id']??'')===$uid)return $person;
    return null;
}
/** Warga menentukan domisili, tetapi bukan identitas atau hak akun ketua RT/RW. */
function cikoko_area_update(array $request,array $existing,bool $resident):array {
    $oldRt=cikoko_area($existing['rt']??'','RT',false);
    $oldRw=cikoko_area($existing['rw']??'','RW',false);
    if(!$resident){
        // Wilayah akun petugas resmi hanya dapat diubah oleh Admin Utama.
        if(array_key_exists('rt',$request)||array_key_exists('rw',$request))
            mobile_error('Wilayah petugas diatur melalui pengelolaan akun resmi.',403);
        return [];
    }
    // Kompatibilitas aplikasi lama: perubahan profil nonwilayah tidak dipaksa mengisi RT/RW.
    if(!array_key_exists('rt',$request)&&!array_key_exists('rw',$request))return [];
    $newRt=cikoko_area($request['rt']??$oldRt,'RT');
    $newRw=cikoko_area($request['rw']??$oldRw,'RW');
    if($newRt!==$oldRt||$newRw!==$oldRw){
        $password=(string)($request['current_password']??'');
        if($password===''||!password_verify($password,(string)($existing['password_hash']??'')))
            mobile_error('Konfirmasi password diperlukan saat mengubah RT/RW.',403);
    }
    return ['rt'=>$newRt,'rw'=>$newRw];
}
/** Harus tepat satu akun ketua aktif per wilayah. Tidak mengambil role dari input warga. */
function cikoko_officer_for(string $role,string $rt,string $rw):array {
    $rt=cikoko_area($rt,'RT');
    $rw=cikoko_area($rw,'RW');
    $found=[];
    foreach(db_read('portal_users') as $person){
        if(($person['role']??'')!==$role||empty($person['active']))continue;
        if(cikoko_area($person['rw']??'','RW',false)!==$rw)continue;
        if($role==='rt'&&cikoko_area($person['rt']??'','RT',false)!==$rt)continue;
        $found[]=$person;
    }
    if(count($found)!==1)
        mobile_error(count($found)===0
            ?'Ketua '.strtoupper($role).' untuk wilayah tersebut belum ditetapkan. Permohonan belum dikirim.'
            :'Terdapat lebih dari satu Ketua '.strtoupper($role).' pada wilayah yang sama. Hubungi pengelola.',409);
    return $found[0];
}
