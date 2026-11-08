-- READ ONLY; run in phpMyAdmin against the database actually used by datawebs.my.id.
SELECT DATABASE() AS active_database, VERSION() AS mysql_version;
SHOW TABLES LIKE 'mobile_%';
SHOW COLUMNS FROM mobile_reports;
SHOW INDEX FROM mobile_reports;
SHOW COLUMNS FROM mobile_chat;
SHOW INDEX FROM mobile_chat;
SHOW COLUMNS FROM mobile_chat_receipts;
SHOW COLUMNS FROM mobile_chat_presence;
SELECT COUNT(*) AS count_reports,MAX(id) AS latest_report_id FROM mobile_reports;
SELECT COUNT(*) AS count_chats,MAX(id) AS latest_chat_id FROM mobile_chat;
