# vps-plausible-stack

Serve Plausible Analytics on the least expensive IONOS VPS Tier running Debian 13. This should work for any Debian VPS with 2GB of RAM. Runs sensible security settings such as unattended upgrades and Fail2Ban. Enable SSH hardening by hand. Uses 1Password for secrets.

> **Template repo — replace the placeholders before deploying.**
>
> - **Host + secrets in one step:** run `scripts/configure.sh` — it prompts for your
>   Plausible host, Caddy email, and 1Password vault, seeds the vault, and writes
>   `.env`. The host flows through a single `DOMAIN` value, so nothing is hand-edited.
> - `stats.yourdomain.example` → your Plausible host (only if you configure by hand
>   instead of the wizard)
> - `Agentic Vault` → your 1Password vault. Both `scripts/seed-1password.sh` and
>   `scripts/generate-env-from-1password.sh` prompt for it (default `Agentic
>   Vault`) or take `VAULT=...`; use the **same** value for both so seeding and
>   injection target one vault. `config/.env.1pass` keeps `Agentic Vault` as its
>   built-in default; the generate script rewrites it when you override.
>
> Real secrets never live here: `.env` is generated from 1Password and is
> gitignored. See `DEPLOY.md` for the full walkthrough.

A direct-exposure, single-VPS Plausible stack for self-hosting [Plausible
Analytics](https://plausible.io/) behind [Caddy](https://caddyserver.com/) with
automatic HTTPS. Caddy is the only service with published ports (80/443); the
databases sit on an internal-only Docker network.

```
Browser → Caddy → Plausible        (stats.yourdomain.example)
Caddy   → Let's Encrypt (HTTP-01)   certificate issuance
```

## Quick start

See **`DEPLOY.md`** for the full walkthrough. In brief:

1. Configure host + secrets: `scripts/configure.sh` (prompts for host, Caddy email,
   and vault; seeds 1Password and writes `.env`). Or do the two steps by hand:
   `scripts/seed-1password.sh` then `scripts/generate-env-from-1password.sh`.
2. Bootstrap the host (Debian 13 VPS): `scripts/bootstrap-plausible-stack.sh`
3. Harden the host: `scripts/harden-host.sh` (plus SSH per `docs/ssh-hardening.md`)
4. Deploy: `scripts/deploy-services.sh`
5. Smoke test: `curl -I https://<your-host>`

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
