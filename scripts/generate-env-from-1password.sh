#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INPUT_FILE="${ROOT_DIR}/config/.env.1pass"
OUTPUT_FILE="${ROOT_DIR}/.env"

if ! command -v op >/dev/null 2>&1; then
  echo "1Password CLI (op) is not installed or not in PATH." >&2
  exit 1
fi
if [[ ! -f "$INPUT_FILE" ]]; then
  echo "Missing template: $INPUT_FILE" >&2
  exit 1
fi

op inject -i "$INPUT_FILE" -o "$OUTPUT_FILE"
chmod 600 "$OUTPUT_FILE"
echo "Generated $OUTPUT_FILE from $INPUT_FILE"
