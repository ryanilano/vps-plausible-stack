#!/usr/bin/env bash
set -Eeuo pipefail

# Seed the 1Password vault with the items config/.env.1pass references (S-tier:
# Plausible secrets + Caddy email). Run ONCE on your Mac where `op` is signed in,
# before the first deploy. Existing items are SKIPPED, never overwritten.
#
#   ./scripts/seed-1password.sh
#   VAULT="My Vault" CADDY_EMAIL=me@example.com ./scripts/seed-1password.sh

DEFAULT_VAULT="Agentic Vault"
CATEGORY="Secure Note"

# Same resolution as generate-env-from-1password.sh: VAULT env wins; else prompt on
# a TTY (default "Agentic Vault"). Seeding and injecting MUST target the same vault.
if [[ -z "${VAULT:-}" ]]; then
  if [[ -t 0 ]]; then
    read -rp "1Password vault [${DEFAULT_VAULT}]: " VAULT
  fi
  VAULT="${VAULT:-$DEFAULT_VAULT}"
fi

command -v op      >/dev/null 2>&1 || { echo "1Password CLI (op) is not installed or not in PATH." >&2; exit 1; }
command -v openssl >/dev/null 2>&1 || { echo "openssl is required to generate secrets." >&2; exit 1; }
op whoami          >/dev/null 2>&1 || { echo "op is not signed in. Run 'op signin' (or enable the desktop app integration) first." >&2; exit 1; }
op vault get "$VAULT" >/dev/null 2>&1 || { echo "Vault '$VAULT' not found or not accessible." >&2; exit 1; }

item_exists() { op item get "$1" --vault "$VAULT" >/dev/null 2>&1; }

create_item() {
  local title="$1"; shift
  if item_exists "$title"; then
    echo "• '$title' already exists in '$VAULT' — skipping (won't overwrite)."
    return 0
  fi
  op item create --vault "$VAULT" --category "$CATEGORY" --title "$title" "$@" >/dev/null
  echo "✓ created '$title'"
}

echo "Seeding vault '$VAULT'…"

# Generated secrets. totp vault key MUST be 32 bytes; the others are 48 for headroom.
# postgres password is hex (URL-safe): it is interpolated raw into DATABASE_URL in
# compose.yml, and base64's '/','+','=' break Ecto's URL parser. hex 32 = 256 bits.
create_item "Plausible" \
  "secret key base[password]=$(openssl rand -base64 48)" \
  "totp vault key[password]=$(openssl rand -base64 32)" \
  "postgres password[password]=$(openssl rand -hex 32)"

# External value: Caddy / Let's Encrypt email (prompted, or from CADDY_EMAIL).
if item_exists "Caddy"; then
  echo "• 'Caddy' already exists in '$VAULT' — skipping (won't overwrite)."
else
  caddy_email="${CADDY_EMAIL:-}"
  [[ -n "$caddy_email" ]] || read -rp "Caddy / Let's Encrypt email: " caddy_email
  [[ -n "$caddy_email" ]] || { echo "No email provided." >&2; exit 1; }
  create_item "Caddy" "email[text]=$caddy_email"
fi

echo
echo "Done. Verify every reference resolves before deploying:"
echo "  op inject -i config/.env.1pass"
