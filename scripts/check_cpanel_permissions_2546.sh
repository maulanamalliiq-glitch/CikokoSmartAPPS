#!/usr/bin/env bash
# Cikoko cPanel 2546. READ ONLY unless --apply is explicitly supplied.
# Never delete/overwrite personal data, uploaded photos or database credentials.
set -euo pipefail
ROOT="${1:-}"; MODE="${2:---check}"
if [[ -z "$ROOT" || ! -f "$ROOT/lib.php" || ! -d "$ROOT/mobile-api" ]]; then
 echo 'Usage: bash check_cpanel_permissions_2546.sh /home/USER/public_html [--check|--apply]' >&2; exit 2
fi
if [[ "$MODE" != '--check' && "$MODE" != '--apply' ]]; then echo 'Invalid mode' >&2; exit 2; fi
echo "Checking $ROOT ($MODE)"
for d in "$ROOT" "$ROOT/mobile-api" "$ROOT/ahli-waris" "$ROOT/assets" "$ROOT/includes" "$ROOT/partials"; do
 if [[ -d "$d" ]];then echo "$(stat -c '%a %U:%G %n' "$d")";if [[ "$MODE" == '--apply' ]];then chmod 755 "$d";fi;fi
done
for f in "$ROOT/.htaccess" "$ROOT/mobile-api/.htaccess" "$ROOT/ahli-waris/.htaccess" "$ROOT/index.php" "$ROOT/mobile-api/index.php"; do
 if [[ -f "$f" ]];then echo "$(stat -c '%a %U:%G %n' "$f")";if [[ "$MODE" == '--apply' ]];then chmod 644 "$f";fi;fi
done
for f in "$ROOT"/{admin.php,informasi.php,listing.php,portal.php,lib.php,roles-lib.php}; do
 if [[ -f "$f" ]];then echo "$(stat -c '%a %U:%G %n' "$f")";if [[ "$MODE" == '--apply' ]];then chmod 644 "$f";fi;fi
done
if [[ -d "$ROOT/assets" && "$MODE" == '--apply' ]];then
 find "$ROOT/assets" -type d -exec chmod 755 {} +
 find "$ROOT/assets" -type f \( -iname '*.css' -o -iname '*.js' -o -iname '*.svg' -o -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) -exec chmod 644 {} +
fi
echo 'Private/config/data files remain untouched. No chmod 777; no deletion.'
if command -v namei >/dev/null;then namei -l "$ROOT/.htaccess" || true;fi
echo 'Apache may still return 403 when document root parent directory ownership/traversal is wrong. Ask cPanel host to inspect.'
