CREATE TABLE IF NOT EXISTS pj57_config (
  id INT PRIMARY KEY,
  latitude DOUBLE NOT NULL,
  longitude DOUBLE NOT NULL,
  radius_m INT NOT NULL,
  attendance_weight INT NOT NULL,
  work_weight INT NOT NULL,
  evidence_weight INT NOT NULL,
  active_from DATE NOT NULL,
  updated_by VARCHAR(80) NOT NULL,
  updated_at DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS pj57_schedules (
  user_id VARCHAR(80) NOT NULL,
  work_date DATE NOT NULL,
  latitude DOUBLE NOT NULL,
  longitude DOUBLE NOT NULL,
  radius_m INT NOT NULL,
  scheduled_by VARCHAR(80) NOT NULL,
  PRIMARY KEY (user_id,work_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS pj57_attendance (
  user_id VARCHAR(80) NOT NULL,
  work_date DATE NOT NULL,
  event_type ENUM('checkin','checkout') NOT NULL,
  latitude DOUBLE NOT NULL,
  longitude DOUBLE NOT NULL,
  accuracy_m DOUBLE NOT NULL,
  photo LONGBLOB NOT NULL,
  photo_hash CHAR(64) NOT NULL,
  created_at DATETIME NOT NULL,
  PRIMARY KEY (user_id,work_date,event_type),
  UNIQUE KEY uq_pj57_selfie (user_id,photo_hash)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS pj57_jobs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id VARCHAR(80) NOT NULL,
  title VARCHAR(200) NOT NULL,
  work_month CHAR(7) NOT NULL,
  latitude DOUBLE NOT NULL,
  longitude DOUBLE NOT NULL,
  radius_m INT NOT NULL,
  assigned_by VARCHAR(80) NOT NULL,
  created_at DATETIME NOT NULL,
  KEY ix_pj57_job_month (user_id,work_month)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS pj57_job_evidence (
  job_id BIGINT UNSIGNED NOT NULL,
  stage TINYINT UNSIGNED NOT NULL,
  latitude DOUBLE NOT NULL,
  longitude DOUBLE NOT NULL,
  accuracy_m DOUBLE NOT NULL,
  photo LONGBLOB NOT NULL,
  photo_hash CHAR(64) NOT NULL,
  created_at DATETIME NOT NULL,
  PRIMARY KEY (job_id,stage),
  UNIQUE KEY uq_pj57_evidence (job_id,photo_hash),
  FOREIGN KEY (job_id) REFERENCES pj57_jobs(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS pj57_month_approvals (
  user_id VARCHAR(80) NOT NULL,
  work_month CHAR(7) NOT NULL,
  snapshot JSON NOT NULL,
  approved_by VARCHAR(80) NOT NULL,
  approved_at DATETIME NOT NULL,
  PRIMARY KEY (user_id,work_month)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
