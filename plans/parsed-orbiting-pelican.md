# Plan — Fix DB-password URL bug + interactive host setup wizard

## Context

Two problems, one root theme: values that must be *filled in per host* are either
generated in a URL-unsafe form or hand-edited across many files.

1. **Plausible won't boot.** `DATABASE_URL` in `compose.yml` interpolates the
   Postgres password **raw** into a `postgres://…` URL. `seed-1password.sh` mints
   that password with `openssl rand -base64 32`, whose alphabet includes `/ + =`.
   When the password contains `//` (yours does), Ecto's URI parser reads
   everything after it as the path and dies:
   *"invalid URL … path should be a database name."* This is a latent bug that
   recurs on any deploy that draws an unlucky password.

2. **The host is hand-filled everywhere.** `stats.yourdomain.example` is
   duplicated across `Caddyfile`, `config/.env.1pass` (as `BASE_URL`), `compose.yml`,
   docs, and script echoes. There is no single source of truth and no guided
   first-run setup — so the operator edits several files by hand.

Intended outcome: a URL-safe DB password by construction, the domain entered
**once** through an interactive wizard, and a documented one-time rotation runbook
for the already-broken password sitting live in the vault + Postgres volume.

This mirrors an existing, recorded precedent: the **"1Password vault name"**
decision (`CHANGES.md:82`) parameterized a hand-edited value with the same
resolution order — *env var wins → TTY prompt → literal default kept in the
template so a bare `op inject` dry-run still resolves*. The domain follows suit.

---

## Part A — URL-safe DB password (bug fix)

- **`scripts/seed-1password.sh`** *(already edited this session)* — the `postgres
  password` item is now generated with `openssl rand -hex 32` (256 bits, alphabet
  `[0-9a-f]`, always URL-safe). base64 stays only for `secret key base` /
  `totp vault key`, which are passed as plain env vars, never inside a URL.

No change to `compose.yml:110` (`DATABASE_URL`) is needed once the password is
hex — leaving it un-encoded keeps parity with how Plausible's own upstream compose
ships it, and hex needs no encoding.

---

## Part B — Domain as a single source of truth (`DOMAIN`)

Introduce one variable, `DOMAIN` (bare host, e.g. `stats.example.com`), that feeds
both Plausible's `BASE_URL` and Caddy's site address. No file is hand-edited for
the host again.

- **`config/.env.1pass`** — replace line 6
  `BASE_URL=https://stats.yourdomain.example`
  with `DOMAIN=stats.yourdomain.example`.
  Keep the literal default (not a `${…}` token) so a bare `op inject -i
  config/.env.1pass` dry-run still resolves — this is the exact contract recorded
  in `CHANGES.md:89`.

- **`compose.yml:106`** — `BASE_URL: ${BASE_URL}` → `BASE_URL: https://${DOMAIN}`.
  Compose interpolates `${DOMAIN}` from the project-root `.env` (auto-loaded), so
  Plausible receives a fully-formed `BASE_URL`.

- **`Caddyfile:17`** — `stats.yourdomain.example {` → `{$DOMAIN:stats.yourdomain.example} {`.
  Caddy expands `{$DOMAIN}` at config-adaptation time from the caddy container's
  environment, which already loads `.env` via `env_file: [.env]` (`compose.yml:38`).
  The `:default` fallback keeps a bare `caddy` adapt from breaking.

- **`scripts/generate-env-from-1password.sh`** — add `DOMAIN` handling that mirrors
  the existing `VAULT` block:
  - `DEFAULT_DOMAIN="stats.yourdomain.example"` constant.
  - Resolve: `DOMAIN` env wins → else TTY prompt (default `DEFAULT_DOMAIN`).
  - Extend the existing `sed … | op inject` pipe (line 31) with a second
    substitution rewriting the placeholder host to the chosen `DOMAIN`, anchored to
    the value (`s#^DOMAIN=stats\.yourdomain\.example#DOMAIN=${DOMAIN}#`) so template
    comments aren't touched. Result `.env` then contains `DOMAIN=<host>`.
  - Echo the chosen domain alongside the vault line.

Net data flow: `.env` carries `DOMAIN=<host>` → Compose builds `BASE_URL` and passes
`DOMAIN` into the caddy container → Caddyfile expands it. One value, entered once.

---

## Part C — Interactive setup wizard (new `scripts/configure.sh`)

A first-run wizard that gathers everything the operator used to hand-fill, then
delegates to the existing scripts (which already accept `VAULT` / `CADDY_EMAIL`
env overrides — no logic duplicated).

Behavior:
1. Preconditions: `op` installed + `op whoami` signed in; `openssl` present
   (reuse the same guard style as the two existing scripts).
2. Prompt (each with a sensible default, skippable via pre-set env var):
   - **Domain / host** → `DOMAIN` (default `stats.yourdomain.example`)
   - **Caddy / Let's Encrypt email** → `CADDY_EMAIL` (no default; required)
   - **1Password vault** → `VAULT` (default `Agentic Vault`)
3. Confirm the collected values back to the user before doing anything.
4. Run `scripts/seed-1password.sh` with `VAULT` + `CADDY_EMAIL` exported
   (non-interactive; it already **skips** existing items, so re-runs are safe).
5. Run `scripts/generate-env-from-1password.sh` with `VAULT` + `DOMAIN` exported
   → writes `.env`.
6. Print next steps (`scripts/deploy-services.sh`, smoke test at
   `https://$DOMAIN`).

Idempotent and re-runnable: seeding skips existing vault items; generate-env
overwrites `.env`. `set -Eeuo pipefail` like the siblings.

---

## Part D — Docs & decision log

- **`DEPLOY.md`** — point first-time setup at `scripts/configure.sh`; note the host
  is entered once via `DOMAIN`; keep `stats.yourdomain.example` only as an example.
  Add the **DB-password rotation runbook** (Part E) as a labeled subsection.
- **`docs/checklist.md`** — line 19 `.env has BASE_URL …` → `.env has DOMAIN …`;
  reference the wizard for the A-record / host step.
- **`README.md`** — mention `scripts/configure.sh` as the first-run entry point in
  the commands/setup section.
- **Cosmetic host echoes** (optional, low-risk): `scripts/deploy-services.sh:24`
  smoke-test line can source `DOMAIN` from `.env` and print the real URL;
  comments in `Caddyfile:5` / `compose.yml:6` / `bootstrap-edge-stack.sh:77` left
  as illustrative examples.
- **`CHANGES.md`** — add two entries with rationale + revisit trigger, matching the
  house format:
  1. *"DB password is hex, not base64 — it lands in a URL."* Revisit if the
     password stops being interpolated into `DATABASE_URL`.
  2. *"Domain parameterized via `DOMAIN`, resolved like the vault name."* Cross-
     reference the vault decision; revisit if the host moves off `.env`-driven
     config.

---

## Part E — DB password rotation runbook (documented, not executed)

The broken password is already live in the vault **and** baked into the Postgres
data volume (Postgres initialized with it on first boot). Fixing the generator
does not touch either. These steps go into `DEPLOY.md`; **you** run them on the
host (they need your `op` session + Docker, which this environment can't reach).
Plausible never passed *"Starting repos"*, so there is **no Plausible data to
lose**.

```bash
# 1. Replace the bad password in 1Password with a URL-safe (hex) one
op item edit "Plausible" --vault "Agentic Vault" \
  "postgres password[password]=$(openssl rand -hex 32)"

# 2. Regenerate .env
scripts/generate-env-from-1password.sh          # or scripts/configure.sh

# 3. Drop the Postgres volume (init'd with the old password; no data yet)
docker compose down
docker volume ls | grep plausible_db_data       # confirm exact prefixed name first
docker volume rm vps-edge-stack-s_plausible_db_data

# 4. Redeploy — Postgres re-inits with the new password; Plausible connects
scripts/deploy-services.sh
```

> Volume prefix note: Compose project name is `vps-edge-stack-s` (`compose.yml:1`),
> so the volume is `vps-edge-stack-s_plausible_db_data` — **not** the directory
> name. The runbook says to confirm with `docker volume ls` before `rm`.

---

## Files touched

| File | Change |
|------|--------|
| `scripts/seed-1password.sh` | ✅ done — hex DB password |
| `config/.env.1pass` | `BASE_URL=…` → `DOMAIN=stats.yourdomain.example` |
| `compose.yml` | `BASE_URL: https://${DOMAIN}` |
| `Caddyfile` | site address → `{$DOMAIN:stats.yourdomain.example}` |
| `scripts/generate-env-from-1password.sh` | add `DOMAIN` resolve + sed substitution |
| `scripts/configure.sh` | **new** interactive wizard |
| `DEPLOY.md`, `docs/checklist.md`, `README.md`, `CHANGES.md` | docs + decisions + rotation runbook |

---

## Verification

No test suite exists; validate as the repo prescribes (`CLAUDE.md`):

1. **Env template dry-run** (no host, no Docker): with `op` signed in,
   `DOMAIN=stats.test.example VAULT="Agentic Vault" scripts/generate-env-from-1password.sh`
   → inspect `.env`: `DOMAIN=stats.test.example`, `POSTGRES_PASSWORD` is 64 hex
   chars (no `/ + =`).
2. **Compose syntax + interpolation:** `docker compose config` → confirm
   `BASE_URL: https://stats.test.example` and the caddy service shows `DOMAIN` in
   its env; `DATABASE_URL` has a clean hex password.
3. **Wizard path:** run `scripts/configure.sh`, accept/enter values, confirm it
   seeds (or skips) vault items and writes `.env` with the entered domain.
4. **On a real/staging VPS:** `scripts/deploy-services.sh`, then
   `curl -I https://$DOMAIN` → expect the cert to issue and Plausible to answer
   (no Ecto URL crash in `docker compose logs plausible`).
```
