-- CikokoSmartAPPS v2551 - OTP email password reset.
-- Idempotent. Also provisioned by mobile-api/bootstrap.php on the first API request.
CREATE TABLE IF NOT EXISTS mobile_password_otps (
 user_id VARCHAR(80) NOT NULL PRIMARY KEY,
 code_hash CHAR(64) NOT NULL,
 attempts TINYINT UNSIGNED NOT NULL DEFAULT 0,
 expires_at DATETIME NOT NULL,
 sent_at DATETIME NOT NULL,
 INDEX idx_expiry(expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
