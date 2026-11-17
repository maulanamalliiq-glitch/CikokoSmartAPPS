-- Install after migrate_pjlp_2557.sql. Existing attendance, jobs and approvals are retained.
CREATE TABLE IF NOT EXISTS pj58_shifts (
  user_id VARCHAR(80) NOT NULL,
  work_date DATE NOT NULL,
  shift_name ENUM('pagi','siang','malam') NOT NULL,
  PRIMARY KEY (user_id,work_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS pj58_reports (
  user_id VARCHAR(80) NOT NULL,
  work_date DATE NOT NULL,
  report_type ENUM('rutin','dinas_luar') NOT NULL,
  stage TINYINT UNSIGNED NOT NULL,
  full_name VARCHAR(160) NOT NULL,
  opened_at DATETIME NOT NULL,
  submitted_at DATETIME DEFAULT NULL,
  description VARCHAR(1600) DEFAULT NULL,
  latitude DOUBLE DEFAULT NULL,
  longitude DOUBLE DEFAULT NULL,
  accuracy_m DOUBLE DEFAULT NULL,
  photo LONGBLOB,
  photo_hash CHAR(64) DEFAULT NULL,
  PRIMARY KEY (user_id,work_date,report_type,stage),
  UNIQUE KEY uq_pj58_photo (user_id,photo_hash),
  CONSTRAINT fk_pj58_shift FOREIGN KEY (user_id,work_date) REFERENCES pj58_shifts(user_id,work_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
