#!/usr/bin/env bash
set -Eeuo pipefail

# Host prep for the S-tier Plausible stack on Debian 13 (IONOS VPS S).
# Stock Caddy (HTTP-01) — no Go/xcaddy, no custom image build.

if [[ "${EUID}" -eq 0 ]]; then
  echo "Do not run this script as root; it uses sudo where needed." >&2
  exit 1
fi

# ---- Base packages + Docker CE ---------------------------------------------
sudo apt update
sudo apt install -y ca-certificates curl gnupg ufw git

for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
  sudo apt remove -y "$pkg" 2>/dev/null || true
done

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker

if ! apt-cache policy docker-ce | grep -q 'download.docker.com'; then
  echo "ERROR: docker-ce is not being served from download.docker.com." >&2
  exit 1
fi
echo "✓ Docker installed from download.docker.com: $(docker --version)"

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
echo "Bootstrap done. Log out and back in so the docker group applies, then:"
echo "  - place compose.yml, Caddyfile, and .env in ~/vps-plausible-stack/"
echo "  - create the grey-cloud A record: stats.yourdomain.example -> VPS IP (before deploy)"
echo "  - ./scripts/deploy-services.sh"
echo "  - then run ./scripts/harden-host.sh and apply docs/ssh-hardening.md"
