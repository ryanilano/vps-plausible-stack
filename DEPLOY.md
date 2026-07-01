# DEPLOY.md — S-tier (Plausible only)

A one-sitting walkthrough to deploy the S-tier Plausible stack to a fresh IONOS VPS S,
driven from your Mac over SSH. Follow the steps in order.

## Assumptions / decisions baked in (correct these if wrong)

- **Scope:** Plausible only. No Authentik, no dashboard, no `homelab.example`. Adding
  a protected dashboard (Heimdall + Tinyauth) is the documented *growth* path,
  not part of this deploy.
- **Host:** a *fresh* IONOS VPS Linux **S** (2 vCPU / 2 GB / 80 GB), Debian 13.
- **Prerequisites (you provide these):** Docker and `git` are already installed, and
  you operate as a **non-root user with `sudo` + Docker access** whose SSH key already
  logs in. This guide uses `ryan` as the example username — substitute your own. The
  repo does not install Docker or create the user.
- **TLS:** stock Caddy + automatic **HTTP-01** (single public host). This means
  the A record must resolve and port 80 must be open *before* first deploy.
- **Plausible** pinned at **v3.2.1**; ClickHouse XMLs are fetched to match.
- **Caddy certs** live in a named Docker volume (`caddy_data`).

Each step is tagged **[you]** (only you can do it — needs the box, your accounts,
or a decision) or **[script]** (an artifact does it).

---

## 1. [you] Cloudflare DNS record

Create a **grey-cloud (DNS-only)** A record: `stats.yourdomain.example` → VPS IP. HTTP-01
needs this resolving at issuance time, and grey-cloud so the challenge reaches
your origin rather than Cloudflare.

## 2. [script] Bootstrap the host (as your non-root user)

```sh
git clone <repo-url> ~/vps-plausible-stack && cd ~/vps-plausible-stack
./scripts/bootstrap-plausible-stack.sh        # 4 GB swap, UFW 22/80/443, Docker log rotation, ClickHouse configs
exit && ssh ryan@<vps-ip>               # re-login so the docker group applies
```

## 3. [you/script] Generate `.env` and deploy

```sh
./scripts/configure.sh                   # prompts for host + Caddy email; generates secrets with openssl
./scripts/deploy-services.sh             # pull + up + smoke tests
```

`configure.sh` prompts for the **host** (default `stats.yourdomain.example`, or
pass `DOMAIN=...`) and the Caddy email (or pass `CADDY_EMAIL=...`), then mints the
runtime secrets with `openssl` and writes `.env`. The host is one value: it drives
Plausible's `BASE_URL` and Caddy's site address — no file is hand-edited for it.
Re-running preserves existing secrets. Prefer to do it by hand? Copy `env.example`
to `.env` and fill in the blanks (each secret's `openssl` recipe is in the file).

First boot is the risky moment — watch the ClickHouse migration in a 2nd session:
```sh
watch -n2 'free -h; echo; docker stats --no-stream'
```

## 4. [you] Verify

```sh
curl -I https://stats.yourdomain.example          # 200 once Plausible is up and the cert issued
```
Cert not issuing? `docker compose logs -f caddy` — usually DNS not yet resolving
or port 80 not reachable.

## 5. [script + you] Harden the host

```sh
ADMIN_IP=<your-ip> ./scripts/harden-host.sh   # fail2ban + unattended-upgrades
```
Then apply **SSH hardening by hand** following `docs/ssh-hardening.md` — keep
a session open and test in a second one. Do this last so a misstep can't block
the rest of the deploy.

## 6. [you] Lock down Plausible

Open `https://stats.yourdomain.example`, create your user, keep `DISABLE_REGISTRATION=true`,
and enable **TOTP** in account settings (the stack already provides
`TOTP_VAULT_KEY`). That's the auth story for S-tier.

---

## Day-2

- Redeploy after changes: `git pull` on the VPS, regenerate/edit `.env` if needed,
  re-run `./scripts/deploy-services.sh`.
- Health: `docker stats --no-stream`, `free -h`, `journalctl -k | grep -i oom`.

### Rotate the Postgres password

The DB password is interpolated raw into `DATABASE_URL`, so it must be URL-safe —
`scripts/configure.sh` mints it as hex for that reason. If a pre-hex password
(base64, containing `/ + =`) is still in your `.env`, Plausible crashes at boot
with *"invalid URL … path should be a database name."* Rotate it:

```sh
# 1. Set a URL-safe (hex) password in .env
sed -i "s#^POSTGRES_PASSWORD=.*#POSTGRES_PASSWORD=$(openssl rand -hex 32)#" .env

# 2. Drop the Postgres volume — it was initialized with the old password.
#    Safe ONLY if Plausible never migrated (no analytics data yet).
docker compose down
docker volume ls | grep plausible_db_data       # confirm the exact name first
docker volume rm vps-plausible-stack_plausible_db_data

# 3. Redeploy — Postgres re-inits with the new password; Plausible connects
scripts/deploy-services.sh
```

> The volume is prefixed with the Compose project name (`vps-plausible-stack`, see
> `compose.yml`), giving `vps-plausible-stack_plausible_db_data`. If you already
> have real Plausible data, **dump it first** — dropping the volume is destructive.

## Open gap

**Backups** — still no strategy for Plausible Postgres + ClickHouse (logical
dumps, not file copies). Track it in `CHANGES.md`; the stack isn't "done" without it.
