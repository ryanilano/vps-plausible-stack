# CHANGES — Decision log (small VPS, Plausible only)

Decisions recorded with rationale and a revisit trigger, so future sessions
don't re-litigate or silently reverse them. Change them deliberately, not by
drifting back to a "simpler" default.

This is the **Plausible-only** variant: Plausible at `stats.yourdomain.example`, public,
with its own login. No Authentik, no dashboard, no second domain. The full
identity/dashboard build is the separate **M+** variant.

## HTTP-01 on stock Caddy, not DNS-01 + a custom build
- Why: a single public host. HTTP-01 with the stock Caddy image needs no DNS
  token, no plugin build, and no wildcard.
- **Not a reversal:** the M+ build deliberately uses DNS-01 for its wildcard /
  private-redesign roadmap. None of that exists here, so HTTP-01 is correct for
  *this* variant — it is not "simplifying back" against M+'s recorded call.
- Trade-off: needs port 80 reachable and the A record resolving at issuance time
  (DNS-01 needs neither); no wildcard; the host name appears in CT logs; won't
  survive a move to a private/non-public host.
- Revisit if: you add a host that can't do HTTP-01, want a wildcard, or take the
  host private → move to the custom-Caddy DNS-01 model (effectively the M+ build).

## Direct exposure, grey-cloud DNS (no Cloudflare proxy/tunnel)
- Why: the VPS has a public IP; real client IPs reach Plausible (accurate
  counts/geo), and Cloudflare stays out of the analytics path.
- Trade-off: the VPS IP is public; protection rests on the host firewall + Caddy,
  with no WAF/DDoS in front.
- Revisit if: you want Cloudflare's WAF/DDoS (orange-cloud, restrict inbound to
  CF ranges).

## Plausible protected by its own TOTP, not an edge auth gate
- Why: Plausible serves **public, unauthenticated ingestion** — the tracking
  script under `/js/*` and the event endpoint `/api/event`, hit by anonymous
  visitors across the internet. An edge gate (Tinyauth, Authentik, anything) over
  the whole host breaks stat collection unless you maintain a path-exemption
  list — a fragile, version-coupled bypass the stack avoids. Plausible already
  has login + TOTP (provisioned via `TOTP_VAULT_KEY`).
- Trade-off: Plausible keeps its own account (no SSO); MFA enrolment is a manual
  per-user step.
- Revisit if: you want SSO/passkeys in front of Plausible — then edge-gate it
  **with** `/js/*` + `/api/event` exempted, accepting the maintenance, and verify
  the exemption set against your Plausible version.

## Caddy certs in a named volume, not a host bind mount
- Why: HTTP-01 certs are cheap to re-issue, so there's little reason to keep them
  as host files; a named volume avoids host-side cert management.
- Trade-off: certs aren't trivially rsync-able (they're regenerable, so minor).
- Revisit if: you want certs in a backup set, or move to DNS-01.

## 2 GB sizing
- `mem_limit`s are ceilings, not reservations; a 4 GB swapfile (`swappiness=10`)
  absorbs spikes — swap deliberately exceeds RAM on this box. ClickHouse is capped
  and tuned via the upstream low-resource configs. The **first ClickHouse
  migration** is the OOM risk to watch.

## Rootful Docker (operator in the docker group)
- Caveat: docker-group membership is root-equivalent.
- The repo no longer *installs* Docker (see the prerequisites decision below); it
  only adds the operator to the `docker` group in bootstrap.
- Revisit if: privilege separation matters → rootless Docker.

## Docker + a non-root user are prerequisites, not provisioned here
- Why: bootstrap's Docker-CE apt install (keyring, repo line, `download.docker.com`
  policy check) and the separate `create-deploy-user.sh` were the two most
  failure-prone steps on real VPSes, and neither is core to this repo (Compose +
  Caddy + ClickHouse config + deploy scripts). The stack now assumes **Docker and
  `git` are installed** and you operate as a **non-root user with `sudo` + Docker
  access** (docs use `admin` as the example). `create-deploy-user.sh` is deleted.
- What bootstrap still does: preflight-checks `docker`/`git` exist, then swap, UFW,
  Docker log rotation, `docker`-group add, and the version-pinned ClickHouse config
  fetch (still uses `git`).
- Trade-off: the operator must install Docker/git and create their user beforehand;
  the repo is no longer turnkey from a bare root shell.
- Revisit if: you want turnkey provisioning again → restore the Docker-CE install
  block and `create-deploy-user.sh` from git history (removed in this change).

## Host hardening
- `fail2ban` bans SSH brute-forcers via the **UFW** action (coexists with the
  firewall) using the **systemd** journal backend; `ignoreip` whitelists your
  admin IP (anti-lockout).
- `unattended-upgrades` applies **Debian security** updates only; Docker CE is
  blacklisted (deliberate pin); auto-reboot off.
- SSH hardening is **manual** (`docs/ssh-hardening.md`) so a script can't lock
  you out — note the Debian 13 socket-activation caveat there.

## Plausible pinned to an exact patch (v3.2.1)
- Why: reproducible deploys need an exact tag, and upstream does not backport
  fixes — so the pin must be moved deliberately, not left to drift. v3.2.1 is the
  current patch: it removes the `/storybook` endpoint (CVE-2026-8467 /
  GHSA-55hg-8qxv-qj4p, RCE as the app user) and makes the ClickHouse low-memory
  settings actually apply — the latter matters on this 2 GB box.
- Trade-off: patch pinning means no automatic security uptake. Each upgrade is a
  manual bump in **four files** (`compose.yml`, `scripts/bootstrap-plausible-stack.sh`,
  `DEPLOY.md`, `clickhouse/README.md`) plus a re-fetch of the ClickHouse XMLs,
  which are version-locked to the tag.
- Revisit if: a newer CE release ships (security or ClickHouse-tuning fixes) →
  bump all four spots together and re-clone the XMLs at the new tag.

## Secrets generated locally with `openssl`; 1Password removed
- Why: every secret here — `SECRET_KEY_BASE`, `TOTP_VAULT_KEY`, `POSTGRES_PASSWORD` —
  is a **machine-generated random** created during setup and consumed only by this
  one box. 1Password wasn't guarding a shared credential; it generated a random
  value, stored it, and handed it back to the same script. So `op` bought nothing
  and cost a CLI + signin dependency, a vault-name matching footgun (see the
  superseded decision below), and an access-blocked `op://` template. Setup now runs
  through a single `scripts/configure.sh` that mints secrets with `openssl` and
  writes `.env`; `env.example` documents the schema for the by-hand path.
- What changed: `scripts/seed-1password.sh` and
  `scripts/generate-env-from-1password.sh` are deleted (folded into `configure.sh`);
  `config/.env.1pass` is deleted (replaced by `env.example`).
- Idempotency: re-running `configure.sh` **preserves** existing secrets in `.env`
  (it never rotates `POSTGRES_PASSWORD`, which is bound to the initialized DB volume).
- Trade-off: no central vault — no cross-machine secret sharing, no rotation audit
  trail. Secrets live only in the box's gitignored `.env`; all three are regenerable
  **except** `POSTGRES_PASSWORD` once the DB volume exists (rotating it means the
  volume drop in `DEPLOY.md`). Back up `.env` if you don't want to reprovision.
- Revisit if: you go multi-host, need to share secrets across machines, or want
  centralized rotation → reintroduce a vault (restore the deleted scripts +
  template from git history).

## 1Password vault name: interactive, one source of truth for both scripts
- **SUPERSEDED** by "Secrets generated locally with `openssl`" above — 1Password is
  gone, so this footgun no longer exists. Kept for history; its revisit trigger
  ("or move secrets off 1Password") is what fired.
- Why: the vault was overridable when *seeding* (`VAULT=...`) but hardcoded in the
  template `config/.env.1pass`, so seeding into a non-default vault left injection
  reading `op://Agentic Vault/...` and failing silently. Both `seed-1password.sh`
  and `generate-env-from-1password.sh` now resolve the vault the same way — `VAULT`
  env wins, else prompt on a TTY, default `Agentic Vault` — and the generate script
  rewrites the template's vault segment to match.
- Why the template keeps a literal default (not `op://${VAULT}/...`): a bare
  `op inject -i config/.env.1pass` dry run (documented in `DEPLOY.md` and
  `docs/checklist.md`) must resolve out of the box. A `${VAULT}` token would break
  that, since `op inject` does not expand shell variables.
- Trade-off: the default vault name (`Agentic Vault`) still ships in the template
  and scripts; a raw `op inject` dry run only works for that default (an overridden
  vault must dry-run via the generate script).
- Revisit if: you rename the default vault (change `DEFAULT_VAULT` in both scripts
  **and** the `op://` refs in the template together), or move secrets off 1Password.

## Postgres password is hex, not base64 — it lands raw in a URL
- Why: `compose.yml` interpolates `POSTGRES_PASSWORD` **unencoded** into
  `DATABASE_URL` (`postgres://postgres:<pw>@…/plausible`). base64 (`openssl rand
  -base64`) emits `/ + =`; a `/` makes Ecto's URI parser read the rest as the path
  and crash with *"path should be a database name."* `scripts/configure.sh` mints
  it with `openssl rand -hex 32` (256 bits, alphabet `[0-9a-f]`, always URL-safe).
  `secret key base` / `totp vault key` stay base64 — they are plain env vars, never
  inside a URL.
- Trade-off: hex is longer per bit than base64 (cosmetic here).
- Revisit if: `DATABASE_URL` stops being built by raw interpolation (e.g. the
  password moves to a percent-encoded field or a separate `PGPASSWORD`), *or* you
  rotate an existing base64 password — see the rotation runbook in `DEPLOY.md`.

## Host parameterized via `DOMAIN`, resolved like the vault name
- Why: the host (`stats.yourdomain.example`) was hand-edited across the `Caddyfile`,
  `config/.env.1pass` (`BASE_URL`), and docs. It now lives in one variable, `DOMAIN`
  (bare host), carried in `.env`: compose derives `BASE_URL: https://${DOMAIN}` and
  Caddy's site address is `{$DOMAIN:…}` (read from the container env via
  `env_file: [.env]`). `scripts/configure.sh` resolves `DOMAIN` — env wins → TTY
  prompt → literal default — and writes it to `.env` alongside host + email + secrets.
- Note: this decision predates the 1Password removal above, which retired the
  "literal default so a bare `op inject` dry run resolves" contract this originally
  cited. `env.example` still ships a literal default `DOMAIN` for the by-hand path,
  but only as documentation now — no `op inject` step depends on it.
- Trade-off: the host now reaches Caddy through `.env` + `env_file`; a `caddy`
  config adapt outside compose needs `DOMAIN` set (the `{$DOMAIN:default}` fallback
  covers it).
- Revisit if: you move the host off `.env`-driven config, or add a second public
  host (the single-address Caddy block assumes one).

## Open gap

- **Backups** — no strategy yet for Plausible Postgres + ClickHouse (logical
  dumps, not file copies). Tracked, not solved.
- ~~**1Password coupling**~~ — **resolved**: dropped 1Password for local `openssl`
  generation via `scripts/configure.sh`. See "Secrets generated locally with
  `openssl`" above.
