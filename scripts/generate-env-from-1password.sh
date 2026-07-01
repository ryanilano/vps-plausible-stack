#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INPUT_FILE="${ROOT_DIR}/config/.env.1pass"
OUTPUT_FILE="${ROOT_DIR}/.env"

# The vault the op:// refs resolve against. MUST match the vault seed-1password.sh
# wrote to (default "Agentic Vault"). Pass VAULT=… to override non-interactively;
# otherwise prompt on a TTY, defaulting to the template's built-in "Agentic Vault".
DEFAULT_VAULT="Agentic Vault"

# The public host (bare, no scheme). Drives both Plausible's BASE_URL (derived in
# compose as https://$DOMAIN) and Caddy's site address. Resolved like VAULT:
# DOMAIN env wins; else prompt on a TTY; else the template's built-in default.
DEFAULT_DOMAIN="stats.yourdomain.example"

if ! command -v op >/dev/null 2>&1; then
  echo "1Password CLI (op) is not installed or not in PATH." >&2
  exit 1
fi
if [[ ! -f "$INPUT_FILE" ]]; then
  echo "Missing template: $INPUT_FILE" >&2
  exit 1
fi

if [[ -z "${VAULT:-}" ]]; then
  if [[ -t 0 ]]; then
    read -rp "1Password vault [${DEFAULT_VAULT}]: " VAULT
  fi
  VAULT="${VAULT:-$DEFAULT_VAULT}"
fi

if [[ -z "${DOMAIN:-}" ]]; then
  if [[ -t 0 ]]; then
    read -rp "Plausible host [${DEFAULT_DOMAIN}]: " DOMAIN
  fi
  DOMAIN="${DOMAIN:-$DEFAULT_DOMAIN}"
fi

# Rewrite the vault segment of the op:// refs and the DOMAIN value before injecting.
# Both are no-ops at their defaults, so the committed template stays authoritative.
sed -e "s#op://${DEFAULT_VAULT}/#op://${VAULT}/#g" \
    -e "s#^DOMAIN=${DEFAULT_DOMAIN}\$#DOMAIN=${DOMAIN}#" \
    "$INPUT_FILE" | op inject -o "$OUTPUT_FILE"
chmod 600 "$OUTPUT_FILE"
echo "Generated $OUTPUT_FILE from $INPUT_FILE (vault: ${VAULT}, domain: ${DOMAIN})"
