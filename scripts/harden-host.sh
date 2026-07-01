#!/usr/bin/env bash
set -Eeuo pipefail

# harden-host.sh — host hardening for the S-tier Plausible stack VPS (Debian 13 / IONOS).
#
# Installs and configures:
#   - fail2ban          (bans SSH brute-forcers at the UFW layer)
#   - unattended-upgrades (auto-applies Debian SECURITY updates only)
#
# It deliberately does NOT touch /etc/ssh/sshd_config. SSH hardening is a manual,
# careful step — see docs/ssh-hardening.md — precisely so a script can never
# lock you out of the box.
#
# Run AFTER scripts/bootstrap-plausible-stack.sh, as your non-root user (e.g. ryan; uses sudo).
#
# Anti-lockout: set ADMIN_IP to your own home/office IP so fail2ban never bans
# the address you administer from. Strongly recommended.
#
#   ADMIN_IP=203.0.113.7 ./scripts/harden-host.sh
#   ADMIN_IP="203.0.113.7 198.51.100.0/24" ./scripts/harden-host.sh   # multiple ok

if [[ "${EUID}" -eq 0 ]]; then
  echo "Do not run this script as root; it uses sudo where needed." >&2
  exit 1
fi

ADMIN_IP="${ADMIN_IP:-}"

# ---------------------------------------------------------------------------
# Packages
#   python3-systemd is required for fail2ban's systemd journal backend below.
# ---------------------------------------------------------------------------
sudo apt update
sudo apt install -y fail2ban python3-systemd unattended-upgrades

# ---------------------------------------------------------------------------
# fail2ban
# ---------------------------------------------------------------------------
# Whitelist: loopback + RFC1918 (covers Docker bridge ranges so internal traffic
# is never banned), plus your ADMIN_IP if provided. This is the anti-lockout
# safety valve — if you fat-finger a key, fail2ban won't ban the IP you admin from.
IGNOREIP="127.0.0.1/8 ::1 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16"
[[ -n "$ADMIN_IP" ]] && IGNOREIP="$IGNOREIP $ADMIN_IP"

sudo tee /etc/fail2ban/jail.local >/dev/null <<EOF
[DEFAULT]
# Ban via UFW (this box uses UFW for its firewall), so bans coexist with the
# rules bootstrap configured instead of fighting them through raw iptables.
banaction          = ufw
banaction_allports = ufw

# Read auth events from the systemd journal. On Debian 13 sshd logs to journald;
# the systemd backend avoids depending on /var/log/auth.log existing.
backend = systemd

# Never ban these. EDIT to add your admin IP if you didn't pass ADMIN_IP.
ignoreip = ${IGNOREIP}

# 5 failures within 10 minutes -> 1 hour ban.
findtime = 10m
maxretry = 5
bantime  = 1h

# Escalate repeat offenders: each re-ban multiplies the previous bantime,
# capped at one week. (Uses fail2ban's sqlite db, which is on by default.)
bantime.increment = true
bantime.factor    = 2
bantime.maxtime   = 1w

[sshd]
enabled = true
port    = ssh
# 'normal' matches failed logins. Switch to 'aggressive' to also catch pre-auth
# disconnects and bad-protocol probes — more bans, slightly noisier logs.
mode    = normal
EOF

sudo systemctl enable --now fail2ban
sudo systemctl restart fail2ban

# ---------------------------------------------------------------------------
# unattended-upgrades
# ---------------------------------------------------------------------------
# Run the periodic update/upgrade timers.
sudo tee /etc/apt/apt.conf.d/20auto-upgrades >/dev/null <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

# Local policy: SECURITY updates only. Docker CE is intentionally NOT
# auto-upgraded — it's pinned and bumped deliberately (see CHANGES.md), so an
# unattended Docker bump can't silently disturb the running stack.
sudo tee /etc/apt/apt.conf.d/52unattended-upgrades-local >/dev/null <<'EOF'
// Debian security archive only (trixie -> trixie-security). Both origin forms
// are listed for robustness; duplicates with the shipped 50-file are harmless.
Unattended-Upgrade::Origins-Pattern {
    "origin=Debian,codename=${distro_codename},label=Debian-Security";
    "origin=Debian,codename=${distro_codename}-security,label=Debian-Security";
};

// Don't let the container runtime auto-upgrade — keep it deliberate.
Unattended-Upgrade::Package-Blacklist {
    "docker-ce";
    "docker-ce-cli";
    "containerd.io";
};

// Clean obsolete kernels/deps so /boot and disk don't fill silently.
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";

// Reboots are NOT automatic — a single-host edge shouldn't surprise-reboot.
// To enable a scheduled reboot for kernel/libc updates, flip these two:
//   Unattended-Upgrade::Automatic-Reboot "true";
//   Unattended-Upgrade::Automatic-Reboot-Time "04:30";
Unattended-Upgrade::Automatic-Reboot "false";

// Optional: mail reports if you set up a local MTA.
// Unattended-Upgrade::Mail "you@example.com";
EOF

sudo systemctl enable --now unattended-upgrades

# ---------------------------------------------------------------------------
# Summary + how to verify
# ---------------------------------------------------------------------------
cat <<'EOF'

Host hardening applied: fail2ban + unattended-upgrades.

NOTE: SSH itself was NOT touched. Apply that by hand — see
docs/ssh-hardening.md — keeping a session open so you can't lock yourself out.

Verify fail2ban:
  sudo fail2ban-client status            # jails loaded
  sudo fail2ban-client status sshd       # bans, whitelist, watched journal
  systemctl status fail2ban --no-pager

Verify unattended-upgrades (dry run shows what WOULD be upgraded, changes nothing):
  sudo unattended-upgrade --dry-run --debug 2>&1 | tail -n 20
  systemctl status unattended-upgrades --no-pager
  systemctl list-timers 'apt-daily*' --no-pager

If you DIDN'T pass ADMIN_IP, add your admin IP to the ignoreip line in
/etc/fail2ban/jail.local now, then: sudo systemctl restart fail2ban
EOF
