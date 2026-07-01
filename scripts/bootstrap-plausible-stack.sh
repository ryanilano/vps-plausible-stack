#!/usr/bin/env bash
set -Eeuo pipefail

# Host prep for the Plausible stack on Debian 13 (IONOS VPS S).
# Stock Caddy (HTTP-01) — no Go/xcaddy, no custom image build.

if [[ "${EUID}" -eq 0 ]]; then
  echo "Do not run this script as root; it uses sudo where needed." >&2
  exit 1
fi

# ---- Prerequisites ----------------------------------------------------------
# Docker and git are expected to be installed already (see README "Requirements").
# This script prepares the host for the stack; it does not provision Docker itself.
for cmd in docker git; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "ERROR: '$cmd' not found. Install Docker and git first (see README Requirements)." >&2
    exit 1
  }
done
echo "✓ Prerequisites present: $(docker --version), $(git --version)"

# ---- Base packages ----------------------------------------------------------
# Only what this script itself needs: ufw (firewall, configured below) and
# ca-certificates (TLS for the ClickHouse config clone).
sudo apt update
sudo apt install -y ufw ca-certificates

# docker group is root-equivalent by design (rootful Docker). Accepted here.
sudo usermod -aG docker "$USER"

# ---- Swap (safety net for the ClickHouse migration spike on 2 GB) ----------
if ! sudo swapon --show | grep -q '/swapfile'; then
  sudo fallocate -l 4G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab >/dev/null
fi
echo 'vm.swappiness=10' | sudo tee /etc/sysctl.d/99-swappiness.conf >/dev/null
sudo sysctl --system >/dev/null

# ---- Docker log rotation ----------------------------------------------------
sudo install -d /etc/docker
echo '{ "log-driver": "json-file", "log-opts": { "max-size": "10m", "max-file": "3" } }' \
  | sudo tee /etc/docker/daemon.json >/dev/null
sudo systemctl restart docker

# ---- Firewall: SSH + HTTP/HTTPS only ---------------------------------------
# HTTP-01 needs 80 reachable; Caddy needs 80/443. Nothing else publishes a port.
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

# ---- Working tree -----------------------------------------------------------
mkdir -p ~/vps-plausible-stack/clickhouse

# ---- ClickHouse low-resource configs (required) ----------------------------
if [[ ! -f ~/vps-plausible-stack/clickhouse/low-resources.xml ]]; then
  git clone -b v3.2.1 --depth 1 https://github.com/plausible/community-edition /tmp/plausible-ce
  cp /tmp/plausible-ce/clickhouse/*.xml ~/vps-plausible-stack/clickhouse/
  rm -rf /tmp/plausible-ce
fi

echo
echo "Bootstrap done. Log out and back in so the docker group membership applies, then:"
echo "  - place compose.yml, Caddyfile, and .env in ~/vps-plausible-stack/"
echo "  - create the grey-cloud A record: stats.yourdomain.example -> VPS IP (before deploy)"
echo "  - ./scripts/deploy-services.sh"
echo "  - then run ./scripts/harden-host.sh and apply docs/ssh-hardening.md"
