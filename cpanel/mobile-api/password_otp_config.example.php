<?php
// Template: save as /home/CPANEL_USER/cikoko_otp_mail.php (OUTSIDE public_html).
// Sender requested for CikokoSmartAPPS: cikokosmarthome@gmail.com
// Gmail SMTP requires Google 2-Step Verification and a Google App Password.
// Generate a separate 64-hex-character OTP secret in cPanel Terminal:
// php -r 'echo bin2hex(random_bytes(32)), PHP_EOL;'
// NEVER commit the real file or app password to GitHub.
return [
  'from' => 'cikokosmarthome@gmail.com',
  'smtp_username' => 'cikokosmarthome@gmail.com',
  // 16-character Google App Password, NOT the normal Gmail password.
  'smtp_app_password' => 'REPLACE_WITH_GOOGLE_APP_PASSWORD',
  'secret' => 'REPLACE_WITH_64_HEX_CHARACTERS_FROM_RANDOM_BYTES',
];
