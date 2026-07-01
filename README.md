# vps-plausible-stack

Serve Plausible Analytics on the least expensive IONOS VPS tier running Debian 13. This should work for any Debian VPS with 2GB of RAM. Runs sensible security settings such as unattended upgrades and Fail2Ban. Enable SSH hardening by hand. Secrets are generated locally with `openssl` — no external vault.

> **Template repo — replace the placeholders before deploying.**
>
> - **Host + secrets in one step:** run `scripts/configure.sh` — it prompts for your
>   Plausible host and Caddy email, generates the runtime secrets with `openssl`, and
>   writes `.env`. The host flows through a single `DOMAIN` value, so nothing is
>   hand-edited. Re-running preserves the existing secrets.
> - `stats.yourdomain.example` → your Plausible host (only if you configure by hand
>   instead of the wizard)
> - Prefer to do it by hand? Copy `env.example` to `.env` and fill in the blanks;
>   the file lists the `openssl` recipe for each secret.
>
> Real secrets never live in git: `.env` is generated locally and is gitignored.
> See `DEPLOY.md` for the full walkthrough.

A direct-exposure, single-VPS Plausible stack for self-hosting [Plausible
Analytics](https://plausible.io/) behind [Caddy](https://caddyserver.com/) with
automatic HTTPS. Caddy is the only service with published ports (80/443); the
databases sit on an internal-only Docker network.

```
Browser → Caddy → Plausible        (stats.yourdomain.example)
Caddy   → Let's Encrypt (HTTP-01)   certificate issuance
```

## Requirements

Provision these on the VPS before you start — the repo does not install Docker or
create the login user:

- **Docker** (with Compose v2) and **`git`** installed
- A **non-root user with `sudo` + Docker access** whose SSH key logs in. Docs use
  `admin` as the example username — substitute your own.

## Quick start

See **`DEPLOY.md`** for the full walkthrough. In brief:

1. Configure host + secrets: `scripts/configure.sh` (prompts for host and Caddy
   email, generates secrets with `openssl`, and writes `.env`). Or copy `env.example`
   to `.env` and fill it in by hand.
2. Bootstrap the host (Debian 13 VPS): `scripts/bootstrap-plausible-stack.sh`
3. Harden the host: `scripts/harden-host.sh` (plus SSH per `docs/ssh-hardening.md`)
4. Deploy: `scripts/deploy-services.sh`
5. Smoke test: `curl -I https://<your-host>`

## Repo layout

- `compose.yml` — every service, network, and volume
- `Caddyfile` — routing, automatic HTTP-01 TLS
- `env.example` — reference schema for the runtime `.env`
- `scripts/` — bootstrap, deploy, hardening, and setup helpers
- `clickhouse/` — upstream low-resource configs (fetched by bootstrap; gitignored)
- `docs/` — checklist, SSH-hardening guide, and reasoning guardrails
- `CHANGES.md` — recorded decisions and their revisit triggers
- `AGENTS.md` / `CLAUDE.md` — agent behavior rules for this repo

## License

MIT — see `LICENSE`.
