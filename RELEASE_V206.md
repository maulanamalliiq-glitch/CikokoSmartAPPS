# Cikoko v206 — perbaikan berdasarkan uji Android

- Guest/public first screen, login when accessing forms, history, chat or private data. Bottom tabs remain Beranda, Menu/Layanan, Riwayat/Aktivitas, Notifikasi, Profil.
- Camera/gallery card now shows a **small preview beside buttons**, display photo name or readable camera description.
- SQL migration before first Ahli Waris insert; no raw PDO SQL errors exposed to residents. Automatic migration needs ALTER TABLE privilege. Manual alternative: `cpanel/mobile-api/migrate_waris_v206.sql` in phpMyAdmin after backup.
- Admin chat reply moved to self-contained Stateful bottom sheet; avoids disposing TextEditingController while route animation is still active.
- Local notification permission and channel high with sound/vibration; polling fallback for **foreground only**. Notifications while app background/killed **still require configured server-side FCM service account and cron**. On Android ensure Settings > Apps > Cikoko > Notifications enabled and channel not silent.
- Must deploy backend patch to website root (contents from `cpanel/`) and build Flutter APK/AAB with signing key. The GitHub repo is source, not deployment of your live cPanel.
- Protect production database: backup, confirm migrated columns, then do full E2E test. Do not publish sensitive files to GitHub.
