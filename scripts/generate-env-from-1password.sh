#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INPUT_FILE="${ROOT_DIR}/config/.env.1pass"
OUTPUT_FILE="${ROOT_DIR}/.env"

# The vault the op:// refs resolve against. MUST match the vault seed-1password.sh
# wrote to (default "Agentic Vault"). Pass VAULT=… to override non-interactively;
# otherwise prompt on a TTY, defaulting to the template's built-in "Agentic Vault".
DEFAULT_VAULT="Agentic Vault"

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

# Rewrite the vault segment of the op:// refs to the chosen vault before injecting.
# A no-op when VAULT is the default, so the committed template stays authoritative.
sed "s#op://${DEFAULT_VAULT}/#op://${VAULT}/#g" "$INPUT_FILE" | op inject -o "$OUTPUT_FILE"
chmod 600 "$OUTPUT_FILE"
echo "Generated $OUTPUT_FILE from $INPUT_FILE (vault: ${VAULT})"
