<?php
// COPY this file OUTSIDE public_html as: /home/CPANEL_USER/cikoko_otp_mail.php
// This file is a TEMPLATE. Do not commit the real file or your secret to GitHub.
// In cPanel, create an email mailbox at your own domain, e.g. no-reply@YOUR_DOMAIN.
// Generate a secret in cPanel Terminal: php -r 'echo bin2hex(random_bytes(32)), PHP_EOL;'
return [
  'from' => 'no-reply@YOUR_DOMAIN.example',
  'secret' => 'REPLACE_WITH_64_HEX_CHARACTERS_FROM_RANDOM_BYTES',
];
