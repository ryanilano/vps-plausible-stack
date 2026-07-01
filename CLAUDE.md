# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Required reading order

This repo's own docs define how to work in it — read them before making changes:

1. `README.md` — what the stack does, components, and repo layout
2. `AGENTS.md` (mirrors `docs/reasoning-guardrails.md`) — agent behavior rules and
   reasoning guardrails for this repo
3. `CHANGES.md` — past decisions, *why*, and each one's revisit trigger. Don't
   silently reverse a recorded decision without checking its revisit trigger first.
4. `docs/` — deeper guides (checklist, SSH hardening, reasoning guardrails) if
   working on those areas specifically

## What this is

Infrastructure-as-config for a single VPS, not an application codebase. There is
no application source, build step, or test suite — everything here is Docker
Compose service definitions, a Caddyfile, and shell bootstrap/deploy/hardening
scripts.

## Commands

- Generate runtime secrets from 1Password: `scripts/generate-env-from-1password.sh`
  (or `op inject -i config/.env.1pass -o .env`)
- Seed the vault (first time, on your workstation): `scripts/seed-1password.sh`
- Host bootstrap (Debian 13 VPS only — Docker, swap, UFW, ClickHouse configs):
  `scripts/bootstrap-edge-stack.sh`
- Host hardening: `scripts/harden-host.sh` (fail2ban + unattended-upgrades); SSH
  by hand per `docs/ssh-hardening.md`
- Deploy: `scripts/deploy-services.sh` (`docker compose pull && up -d`, then smoke test)
- Smoke test: `curl -I https://stats.yourdomain.example`
- Health/diagnostics: `docker stats --no-stream`, `free -h`,
  `journalctl -k | grep -i oom`, restart counts via `docker ps`

There is no linter or test suite. Validate changes with `docker compose config`
(syntax check) and the smoke test against a real or staging VPS.

## Architecture

Direct-exposure single-VPS stack (~2 vCPU / 2 GB RAM), Debian 13, rootful Docker.
Caddy is the only service with published ports (80/443); the databases sit on an
internal-only Docker network (`plausible_internal`).

```
Browser → Caddy → Plausible        (stats.yourdomain.example)
Caddy   → Let's Encrypt (HTTP-01)   certificate issuance
```

- `compose.yml` defines every service, network, and volume. `mem_limit`s are
  ceilings, not reservations, sized to fit 2 GB total and backed by the swapfile
  bootstrap creates.
- `Caddyfile` is the routing config — stock Caddy, automatic HTTP-01, single host.
- `clickhouse/*.xml` are upstream low-resource configs pulled by bootstrap at the
  pinned Plausible CE tag — gitignored, not hand-edited.
- `config/.env.1pass` is the 1Password-backed env template (`op://` refs); the
  real `.env` is generated, gitignored, and never committed.

## Constraints to respect

- **Don't put an edge auth gate in front of Plausible.** It serves public
  ingestion (`/js/*`, `/api/event`); gating the host breaks stat collection
  without a fragile path-exemption list. Use Plausible's native TOTP. See
  `CHANGES.md`.
- Don't add published ports beyond 80/443 on Caddy; other services must stay
  reachable only over internal Docker networks.
- Keep this edge separate from any homelab box — homelab reachability is out of
  scope for this variant.
- Treat decisions in `CHANGES.md` as settled unless you have a documented reason
  and a revisit trigger — see `AGENTS.md`'s reasoning guardrails before reversing
  one.
