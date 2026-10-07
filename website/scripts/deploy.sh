#!/bin/bash
# Builds the site and uploads it to the server. Usage: scripts/deploy.sh
# The nginx file in deploy/ is installed once (sites-available + a symlink in sites-enabled, then
# `certbot --nginx -d optimos.075codes.com`); this script only updates the site files.
set -euo pipefail
cd "$(dirname "$0")/.."

HOST=${DEPLOY_HOST:-user@your-server}
ROOT=/var/www/optimos

pnpm build
ssh "$HOST" "mkdir -p $ROOT"
rsync -az --delete out/ "$HOST:$ROOT/"
echo "Deployed. https://optimos.075codes.com"
