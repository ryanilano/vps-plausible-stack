#!/usr/bin/env bash
set -Eeuo pipefail

# First-run setup wizard. Gathers the per-host values you would otherwise hand-edit
# — the Plausible host, the Caddy/Let's Encrypt email, and the 1Password vault —
# then delegates to the existing scripts (which already accept these as env vars):
#
#   1. seed-1password.sh          creates the vault items (skips any that exist)
#   2. generate-env-from-1password.sh   writes .env with the chosen host + secrets
#
# Re-runnable: seeding skips existing items, generate overwrites .env. Any prompt
# can be pre-answered by exporting DOMAIN / CADDY_EMAIL / VAULT before running.
#
#   ./scripts/configure.sh
#   DOMAIN=stats.example.com CADDY_EMAIL=me@example.com VAULT="My Vault" ./scripts/configure.sh

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DEFAULT_DOMAIN="stats.yourdomain.example"
DEFAULT_VAULT="Agentic Vault"

command -v op      >/dev/null 2>&1 || { echo "1Password CLI (op) is not installed or not in PATH." >&2; exit 1; }
command -v openssl >/dev/null 2>&1 || { echo "openssl is required to generate secrets." >&2; exit 1; }
op whoami          >/dev/null 2>&1 || { echo "op is not signed in. Run 'op signin' (or enable the desktop app integration) first." >&2; exit 1; }

# ---- Gather values (env wins; else prompt; email is required) ----------------
if [[ -z "${DOMAIN:-}" ]]; then
  read -rp "Plausible host (e.g. stats.example.com) [${DEFAULT_DOMAIN}]: " DOMAIN
  DOMAIN="${DOMAIN:-$DEFAULT_DOMAIN}"
fi

if [[ -z "${CADDY_EMAIL:-}" ]]; then
  read -rp "Caddy / Let's Encrypt email: " CADDY_EMAIL
fi
[[ -n "${CADDY_EMAIL:-}" ]] || { echo "A Caddy / Let's Encrypt email is required." >&2; exit 1; }

if [[ -z "${VAULT:-}" ]]; then
  read -rp "1Password vault [${DEFAULT_VAULT}]: " VAULT
  VAULT="${VAULT:-$DEFAULT_VAULT}"
fi

# ---- Confirm before touching the vault ---------------------------------------
cat <<CONFIRM

About to configure with:
  Host (DOMAIN):   ${DOMAIN}
  Caddy email:     ${CADDY_EMAIL}
  1Password vault: ${VAULT}

This will create vault items (existing ones are skipped) and write .env.
CONFIRM
read -rp "Proceed? [y/N]: " reply
[[ "${reply:-}" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }

# ---- Delegate to the existing scripts ----------------------------------------
echo
echo "→ Seeding 1Password vault…"
VAULT="$VAULT" CADDY_EMAIL="$CADDY_EMAIL" "${ROOT_DIR}/scripts/seed-1password.sh"

echo
echo "→ Generating .env…"
VAULT="$VAULT" DOMAIN="$DOMAIN" "${ROOT_DIR}/scripts/generate-env-from-1password.sh"

cat <<DONE

Done. Next:
  - On the VPS: scripts/bootstrap-plausible-stack.sh, then scripts/deploy-services.sh
  - Smoke test: curl -I https://${DOMAIN}
DONE
