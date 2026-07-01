# SSH Hardening (manual — do NOT script this)

These steps are notes, not automation, on purpose: a script that gets SSH wrong
locks you out of the box. Apply them by hand, in order, with a session open the
whole time. `scripts/harden-host.sh` (fail2ban + unattended-upgrades)
deliberately leaves `sshd_config` alone for the same reason.

> Environment assumed: Debian 13 (trixie), IONOS VPS, and a non-root user with
> `sudo` + Docker access that you created beforehand. This guide uses `ryan` as the
> example username — substitute your own, and confirm the service name before reloading.

## The golden rule

**Keep your current SSH session open.** Make the change, then open a *second,
separate* session to test it. Only close the first session once the second one
logs in cleanly. If the test fails, you fix it from the session that's still
open — no lockout.

## Pre-flight (all must be true before you touch anything)

- [ ] Key login as `ryan` works: from your Mac, `ssh ryan@<vps-ip>` logs in
      with your key, no password. If this isn't already true, **stop** —
      disabling password auth now would lock you out.
- [ ] fail2ban won't ban you: your admin IP is on the `ignoreip` line in
      `/etc/fail2ban/jail.local` (pass `ADMIN_IP=...` to `harden-host.sh`, or add
      it and `sudo systemctl restart fail2ban`).
- [ ] You know your out-of-band recovery path: the **IONOS console / KVM** in
      the IONOS panel gets you a screen on the box even if SSH is dead. Confirm
      you can open it *before* you need it.

## The change

Debian's `sshd_config` ends with `Include /etc/ssh/sshd_config.d/*.conf` read at
the top, and sshd takes the **first** value it sees for a setting — so a drop-in
file wins over the main config and is trivial to roll back (delete one file).

Create `/etc/ssh/sshd_config.d/99-hardening.conf`:

```sh
sudo tee /etc/ssh/sshd_config.d/99-hardening.conf >/dev/null <<'EOF'
# Key-only, no root. The core of SSH hardening.
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes

# Optional but recommended: only this user may log in over SSH.
AllowUsers ryan

# Optional: tighten the brute-force window (fail2ban does the heavy lifting).
MaxAuthTries 3
LoginGraceTime 20
EOF
```

## Validate, then apply

```sh
# 1. Syntax-check. If this prints errors, DO NOT reload — fix them first.
sudo sshd -t

# 2. Apply to new connections. 'reload' does not drop your current session.
sudo systemctl reload ssh
```

> **Service name:** on Debian the unit is `ssh` (not `sshd`). If `reload` isn't
> supported in your setup, `sudo systemctl restart ssh` also won't drop existing
> connections — but reload is the gentler choice.

## Test (from a NEW session, current one still open)

```sh
# New terminal on your Mac:
ssh ryan@<vps-ip>          # should log in with your key
ssh root@<vps-ip>          # should be REFUSED (PermitRootLogin no)
```

If `ryan` logs in cleanly, you're done — close the old session. If it fails,
go back to the session you kept open and either fix `99-hardening.conf` or remove
it (`sudo rm /etc/ssh/sshd_config.d/99-hardening.conf && sudo systemctl reload ssh`)
to revert instantly.

## Debian 13 caveat: socket activation (matters only if you change the port)

Debian 13 starts sshd via **socket activation** (`ssh.socket`) by default. The
auth settings above live in `sshd_config` and apply per-connection as normal —
no special handling needed. But `Port` and `ListenAddress` in `sshd_config` are
**ignored** under socket activation. Check which mode you're in:

```sh
systemctl is-enabled ssh.socket    # 'enabled' => socket-activated
```

If you want a non-standard port (optional — it cuts log noise but is
security-by-obscurity, not real protection), change it on the socket, not in
`sshd_config`:

```sh
sudo systemctl edit ssh.socket
# In the editor, add:
#   [Socket]
#   ListenStream=
#   ListenStream=2222
sudo systemctl daemon-reload
sudo systemctl restart ssh.socket
# Then open the new port in UFW BEFORE relying on it, and remove 22 only after
# you've confirmed login on the new port from a second session:
sudo ufw allow 2222/tcp
```

A better alternative to a custom port: restrict SSH to known source IPs at the
firewall (`sudo ufw allow from <your-ip> to any port 22 proto tcp`, then remove
the broad `OpenSSH` rule) or in the IONOS cloud firewall. That's actual
protection, not obscurity — but only do it from a stable IP you control.

## Rollback (if you ever get half-locked-out)

1. Open the **IONOS console / KVM** (out-of-band — works without SSH).
2. Log in, then remove the drop-in and reload:
   ```sh
   sudo rm -f /etc/ssh/sshd_config.d/99-hardening.conf
   sudo systemctl reload ssh
   ```
3. If fail2ban banned you, unban from the console:
   ```sh
   sudo fail2ban-client set sshd unbanip <your-ip>
   ```

## How this interacts with fail2ban

fail2ban (`scripts/harden-host.sh`) bans IPs that fail SSH auth repeatedly. With
`PasswordAuthentication no`, brute-force attempts are rejected up front, so
they're cheap — but bots still hammer the port, and fail2ban keeps the noise and
load down. The one risk fail2ban adds is banning *you* after a few fumbled key
attempts; the `ignoreip` whitelist in the pre-flight is what prevents that.
