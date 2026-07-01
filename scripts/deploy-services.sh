#!/usr/bin/env bash
set -Eeuo pipefail

# S-tier deploy: stock images, so no build step and no Authentik auth-gate audit
# (there's no gated *.homelab.example handle to guard). If you ever add a gated
# dashboard, restore the audit from the M+ deploy-services.sh first.

STACK_DIR="${STACK_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$STACK_DIR"

[[ -f .env ]]                         || { echo ".env missing — run scripts/generate-env-from-1password.sh"; exit 1; }
[[ -f compose.yml ]]                  || { echo "compose.yml missing"; exit 1; }
[[ -f Caddyfile ]]                    || { echo "Caddyfile missing"; exit 1; }
[[ -f clickhouse/low-resources.xml ]] || { echo "clickhouse/*.xml missing — run scripts/bootstrap-plausible-stack.sh"; exit 1; }

docker compose config >/dev/null      # syntax check (compose.yml + .env)
docker compose pull
docker compose up -d
docker compose ps

cat <<'TESTS'

Smoke test (give it a minute for the cert to issue on first boot):
  curl -I https://stats.yourdomain.example          # expect 200 once Plausible is up
  docker compose logs -f caddy             # if the cert doesn't issue
TESTS
