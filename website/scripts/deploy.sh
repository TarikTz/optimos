#!/bin/bash
# Builds the site and uploads it to the server. Usage: scripts/deploy.sh
# Set DEPLOY_HOST (user@server). The nginx file in deploy/ is installed once (sites-available + a symlink in sites-enabled, then
# `certbot --nginx -d optimos.075codes.com`); this script only updates the site files.
set -euo pipefail
cd "$(dirname "$0")/.."

HOST=${DEPLOY_HOST:?set DEPLOY_HOST to user@server, for example: DEPLOY_HOST=deploy@example.com scripts/deploy.sh}
ROOT=/var/www/optimos

pnpm build
ssh "$HOST" "mkdir -p $ROOT"
rsync -az --delete out/ "$HOST:$ROOT/"
echo "Deployed. https://optimos.075codes.com"
