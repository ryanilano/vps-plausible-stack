# Launch Checklist — IONOS S-tier (Plausible only)

## Prerequisites

- [ ] Docker and `git` installed on the VPS
- [ ] A non-root user with `sudo` + Docker access (this guide uses `ryan` as the example)
- [ ] Key login as that user works — `ssh ryan@<vps-ip>`

## Host

- [ ] Update Debian 13
- [ ] Run `scripts/bootstrap-plausible-stack.sh` (swap, UFW, Docker log rotation, ClickHouse configs)
- [ ] Confirm UFW allows SSH, HTTP (80), HTTPS (443) only
- [ ] Confirm `/swapfile` active and `vm.swappiness=10`

## DNS and TLS

- [ ] Create grey-cloud (DNS-only) A record: `stats.yourdomain.example` → VPS IP
- [ ] Confirm it resolves to the VPS _before_ deploy (HTTP-01 needs it)
- [ ] Validate Caddyfile (`docker compose config`)

## Plausible

- [ ] `.env` has `DOMAIN`, `SECRET_KEY_BASE`, `TOTP_VAULT_KEY`, `POSTGRES_PASSWORD` (`BASE_URL` is derived from `DOMAIN` in compose)
- [ ] `.env` generated with `scripts/configure.sh` (prompts for host + Caddy email), or copied from `env.example` and filled in by hand
- [ ] `POSTGRES_PASSWORD` is URL-safe (hex, no `/ + =`) — it lands raw in `DATABASE_URL`
- [ ] Every value in `.env` is filled (no blanks)
- [ ] Deploy (`scripts/deploy-services.sh`); watch first ClickHouse migration for OOM
- [ ] `curl -I https://stats.yourdomain.example` returns 200
- [ ] Create Plausible user; keep `DISABLE_REGISTRATION=true`
- [ ] Enable TOTP in Plausible account settings

## Hardening

- [ ] Run `ADMIN_IP=<your-ip> scripts/harden-host.sh` (fail2ban + unattended-upgrades)
- [ ] Confirm `fail2ban-client status sshd` loads and your IP is in `ignoreip`
- [ ] Confirm `unattended-upgrade --dry-run` shows Debian security origin
- [ ] Apply SSH hardening per `docs/ssh-hardening.md` (manual; keep a session open)
- [ ] Confirm `ssh root@<vps-ip>` is refused and `ssh ryan@<vps-ip>` works

## Known gap

- [ ] Backups for Plausible Postgres + ClickHouse — still open; track in `CHANGES.md`
