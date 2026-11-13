-- Modul cuti PPSU Cikoko. Impor via phpMyAdmin setelah backup.
CREATE TABLE IF NOT EXISTS pjlp_employees(
 id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
 user_id VARCHAR(80) NOT NULL UNIQUE,
 id_phl VARCHAR(40) NOT NULL UNIQUE,
 full_name VARCHAR(160) NOT NULL,
 position_name VARCHAR(120) NOT NULL DEFAULT 'PJLP PPSU',
 work_unit VARCHAR(160) NOT NULL DEFAULT 'Kantor Kelurahan Cikoko',
 hired_on DATE NOT NULL,
 supervisor_user_id VARCHAR(80) NOT NULL,
 active TINYINT(1) NOT NULL DEFAULT 1,
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS pjlp_leave_balances(
 employee_id BIGINT UNSIGNED NOT NULL,
 leave_year SMALLINT UNSIGNED NOT NULL,
 allowance_days SMALLINT UNSIGNED NOT NULL,
 adjustment_days SMALLINT NOT NULL DEFAULT 0,
 updated_by VARCHAR(80) NOT NULL,
 updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 PRIMARY KEY(employee_id,leave_year),
 CONSTRAINT fk_pjlp_balance_employee FOREIGN KEY(employee_id) REFERENCES pjlp_employees(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS pjlp_holidays(
 holiday_date DATE NOT NULL PRIMARY KEY,
 description VARCHAR(160) NOT NULL,
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS pjlp_leave_requests(
 id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
 employee_id BIGINT UNSIGNED NOT NULL,
 leave_year SMALLINT UNSIGNED NOT NULL,
 start_date DATE NOT NULL,
 end_date DATE NOT NULL,
 requested_days SMALLINT UNSIGNED NOT NULL,
 reason VARCHAR(1000) NOT NULL,
 leave_address VARCHAR(500) NOT NULL,
 phone VARCHAR(40) NOT NULL,
 status ENUM('pending_admin','pending_supervisor','pending_lurah','approved','revision','deferred','rejected') NOT NULL DEFAULT 'pending_admin',
 official_number VARCHAR(100) NULL UNIQUE,
 submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 verified_at DATETIME NULL,
 pdf_sha256 CHAR(64) NULL,
 CONSTRAINT fk_pjlp_request_employee FOREIGN KEY(employee_id) REFERENCES pjlp_employees(id),
 INDEX idx_pjlp_employee_status(employee_id,status),
 INDEX idx_pjlp_leave_dates(employee_id,start_date,end_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS pjlp_leave_approvals(
 id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
 request_id BIGINT UNSIGNED NOT NULL,
 stage ENUM('admin','supervisor','lurah') NOT NULL,
 actor_user_id VARCHAR(80) NOT NULL,
 decision ENUM('approve','revision','defer','reject') NOT NULL,
 reason VARCHAR(1000) NOT NULL DEFAULT '',
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT fk_pjlp_approval_request FOREIGN KEY(request_id) REFERENCES pjlp_leave_requests(id),
 INDEX idx_pjlp_approval_stage(request_id,stage)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS pjlp_officials(
 id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
 user_id VARCHAR(80) NOT NULL UNIQUE,
 full_name VARCHAR(160) NOT NULL,
 title VARCHAR(160) NOT NULL,
 nip VARCHAR(40) NOT NULL,
 qr_file VARCHAR(255) NULL,
 updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS pjlp_leave_audit(
 id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
 request_id BIGINT UNSIGNED NULL,
 actor_user_id VARCHAR(80) NOT NULL,
 event_name VARCHAR(80) NOT NULL,
 details_json TEXT NULL,
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 INDEX idx_pjlp_audit_request(request_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
