# Launch Checklist — IONOS S-tier (Plausible only)

## Host

- [ ] Update Debian 13
- [ ] Create deploy user (`scripts/create-deploy-user.sh`), confirm key login
- [ ] Run `scripts/bootstrap-edge-stack.sh` (Docker, swap, UFW, log rotation, ClickHouse configs)
- [ ] Confirm UFW allows SSH, HTTP (80), HTTPS (443) only
- [ ] Confirm `/swapfile` active and `vm.swappiness=10`

## DNS and TLS

- [ ] Create grey-cloud (DNS-only) A record: `stats.yourdomain.example` → VPS IP
- [ ] Confirm it resolves to the VPS _before_ deploy (HTTP-01 needs it)
- [ ] Validate Caddyfile (`docker compose config`)

## Plausible

- [ ] `.env` has `BASE_URL`, `SECRET_KEY_BASE`, `TOTP_VAULT_KEY`, `POSTGRES_PASSWORD`
- [ ] `.env` generated with `scripts/generate-env-from-1password.sh` (prompts for vault; same one you seeded)
- [ ] Dry run resolves every line — `op inject -i config/.env.1pass` (default vault) or the generate script (overridden vault)
- [ ] Deploy (`scripts/deploy-services.sh`); watch first ClickHouse migration for OOM
- [ ] `curl -I https://stats.yourdomain.example` returns 200
- [ ] Create Plausible user; keep `DISABLE_REGISTRATION=true`
- [ ] Enable TOTP in Plausible account settings

## Hardening

- [ ] Run `ADMIN_IP=<your-ip> scripts/harden-host.sh` (fail2ban + unattended-upgrades)
- [ ] Confirm `fail2ban-client status sshd` loads and your IP is in `ignoreip`
- [ ] Confirm `unattended-upgrade --dry-run` shows Debian security origin
- [ ] Apply SSH hardening per `docs/ssh-hardening.md` (manual; keep a session open)
- [ ] Confirm `ssh root@<vps-ip>` is refused and `ssh deploy@<vps-ip>` works

## Known gap

- [ ] Backups for Plausible Postgres + ClickHouse — still open; track in `CHANGES.md`
