# vps-plausible-stack

Serve Plausible Analytics on the least expensive IONOS VPS Tier running Debian 13. This should work for any Debian VPS with 2GB of RAM. Runs sensible security settings such as unattended upgrades and Fail2Ban. Enable SSH hardening by hand. Uses 1Password for secrets.

> **Template repo — replace the placeholders before deploying.**
>
> - `stats.yourdomain.example` → your Plausible hostname
> - `Agentic Vault` → your 1Password vault (in `config/.env.1pass` and
>   `scripts/seed-1password.sh`, or pass `VAULT=...`)
>
> Real secrets never live here: `.env` is generated from 1Password and is
> gitignored. See `DEPLOY.md` for the full walkthrough.

A direct-exposure, single-VPS edge stack for self-hosting [Plausible
Analytics](https://plausible.io/) behind [Caddy](https://caddyserver.com/) with
automatic HTTPS. Caddy is the only service with published ports (80/443); the
databases sit on an internal-only Docker network.

```
Browser → Caddy → Plausible        (stats.yourdomain.example)
Caddy   → Let's Encrypt (HTTP-01)   certificate issuance
```

## Quick start

See **`DEPLOY.md`** for the full walkthrough. In brief:

1. Seed your 1Password vault: `scripts/seed-1password.sh`
2. Generate `.env`: `scripts/generate-env-from-1password.sh`
3. Bootstrap the host (Debian 13 VPS): `scripts/bootstrap-edge-stack.sh`
4. Harden the host: `scripts/harden-host.sh` (plus SSH per `docs/ssh-hardening.md`)
5. Deploy: `scripts/deploy-services.sh`
6. Smoke test: `curl -I https://stats.yourdomain.example`

## Repo layout

- `compose.yml` — every service, network, and volume
- `Caddyfile` — routing, automatic HTTP-01 TLS
- `config/.env.1pass` — 1Password-backed env template (`op://` refs)
- `scripts/` — bootstrap, deploy, hardening, and 1Password helpers
- `clickhouse/` — upstream low-resource configs (fetched by bootstrap; gitignored)
- `docs/` — checklist, SSH-hardening guide, and reasoning guardrails
- `CHANGES.md` — recorded decisions and their revisit triggers
- `AGENTS.md` / `CLAUDE.md` — agent behavior rules for this repo

## License

MIT — see `LICENSE`.
