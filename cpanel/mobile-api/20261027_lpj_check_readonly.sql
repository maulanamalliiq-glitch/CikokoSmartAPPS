-- Cikoko LPJ v2513 preflight / post-deployment verification; READ ONLY.
-- Do not show PIN hashes, signatures, private paths or residents' personal data.
SELECT TABLE_NAME, COUNT(*) AS kolom
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA='datd1747_smartapp'
  AND TABLE_NAME IN ('civic_officers','cikoko_lpj_docs','cikoko_lpj_approvals',
                     'cikoko_lpj_pins','cikoko_lpj_audit')
GROUP BY TABLE_NAME ORDER BY TABLE_NAME;

SELECT duty, COALESCE(rt,'-') AS rt, rw, active, COUNT(*) AS jumlah_petugas
FROM datd1747_smartapp.civic_officers
WHERE duty IN ('rt','rw','bendahara_rt','bendahara_rw','lmk')
GROUP BY duty,rt,rw,active ORDER BY rw,rt,duty;

SELECT kind, status, COUNT(*) AS jumlah_lpj
FROM datd1747_smartapp.cikoko_lpj_docs
GROUP BY kind,status ORDER BY kind,status;

SELECT document_id,revision,duty,action,recorded_at
FROM datd1747_smartapp.cikoko_lpj_approvals
ORDER BY id DESC LIMIT 25;
