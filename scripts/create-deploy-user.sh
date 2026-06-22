#!/usr/bin/env bash
set -Eeuo pipefail

# Create a non-root user to own and run the edge stack, instead of using root.
# Run this ONCE on the VPS, AS ROOT (IONOS gives you root to start with):
#
#   ssh root@<vps-ip>
#   # copy this script up (or paste it), then:
#   ./create-deploy-user.sh
#
# It creates the user, installs your SSH key, and grants sudo — which the
# bootstrap step needs exactly once. After bootstrap adds the user to the docker
# group, day-to-day deploys need no sudo at all.
#
# Config (env vars):
#   DEPLOY_USER     username to create     (default: deploy)
#   SSH_PUBKEY      public key to install for SSH login
#                   (default: copy root's ~/.ssh/authorized_keys)
#   NOPASSWD_SUDO   set to 1 for passwordless sudo instead of a password prompt

DEPLOY_USER="${DEPLOY_USER:-deploy}"

[[ "${EUID}" -eq 0 ]] || { echo "Run this as root (e.g. ssh root@<vps-ip>)." >&2; exit 1; }

# 1. Create the user. No password is set here — login is via SSH key.
if id "$DEPLOY_USER" >/dev/null 2>&1; then
  echo "• user '$DEPLOY_USER' already exists — leaving it as-is."
else
  adduser --disabled-password --gecos "" "$DEPLOY_USER"
  echo "✓ created user '$DEPLOY_USER'"
fi

# 2. Grant sudo. Bootstrap needs it once; deploys afterward use the docker group.
usermod -aG sudo "$DEPLOY_USER"
echo "✓ added '$DEPLOY_USER' to the sudo group"

# 3. Install the SSH public key so you can log in as this user from your Mac.
home_dir="$(getent passwd "$DEPLOY_USER" | cut -d: -f6)"
install -d -m 700 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$home_dir/.ssh"

if [[ -n "${SSH_PUBKEY:-}" ]]; then
  printf '%s\n' "$SSH_PUBKEY" > "$home_dir/.ssh/authorized_keys"
  echo "• installed the provided SSH_PUBKEY"
elif [[ -f /root/.ssh/authorized_keys ]]; then
  cp /root/.ssh/authorized_keys "$home_dir/.ssh/authorized_keys"
  echo "• copied root's authorized_keys for '$DEPLOY_USER'"
else
  echo "No SSH_PUBKEY given and /root/.ssh/authorized_keys not found." >&2
  echo "Re-run with SSH_PUBKEY='ssh-ed25519 AAAA... you@mac'." >&2
  exit 1
fi
chmod 600 "$home_dir/.ssh/authorized_keys"
chown "$DEPLOY_USER:$DEPLOY_USER" "$home_dir/.ssh/authorized_keys"
echo "✓ installed authorized_keys"

# 4. Make sudo usable: passwordless, or a password you set now.
if [[ "${NOPASSWD_SUDO:-}" == "1" ]]; then
  sudoers="/etc/sudoers.d/90-$DEPLOY_USER"
  echo "$DEPLOY_USER ALL=(ALL) NOPASSWD:ALL" > "$sudoers"
  chmod 440 "$sudoers"
  visudo -cf "$sudoers" >/dev/null || { echo "sudoers validation failed; removing." >&2; rm -f "$sudoers"; exit 1; }
  echo "✓ granted passwordless sudo to '$DEPLOY_USER'"
else
  echo
  echo "Set a password for '$DEPLOY_USER' (sudo needs it during bootstrap):"
  passwd "$DEPLOY_USER"
fi

cat <<EOF

Done. Next steps:
  1. From your Mac, confirm key login:   ssh $DEPLOY_USER@<vps-ip>
  2. As $DEPLOY_USER, clone the repo and run scripts/bootstrap-edge-stack.sh
  3. Once that works, harden SSH (recommended) in /etc/ssh/sshd_config:
       PermitRootLogin no
       PasswordAuthentication no
     then: sudo systemctl restart ssh
     (Only after you've confirmed key login as '$DEPLOY_USER' — don't lock
      yourself out.)
EOF
