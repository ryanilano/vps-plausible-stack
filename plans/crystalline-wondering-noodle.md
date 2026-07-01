# Plan — Slim bootstrap: Docker + git + non-root user become prerequisites

## Context

Running `scripts/bootstrap-plausible-stack.sh` on a real VPS hit repeated problems in
its two heaviest sections: the **Docker CE apt install** (keyring, repo line, and the
`download.docker.com` policy check are brittle across host states) and the separate
**`create-deploy-user.sh`** user-provisioning step. Both are things a competent operator
already has or can do once, and neither is core to *this* repo's job (Compose + Caddy +
ClickHouse config + deploy scripts).

The fix: stop provisioning Docker and the login user from the repo. Document them as
**prerequisites** — "Docker and git installed, operating as a non-root user with sudo +
Docker access" — and have bootstrap only do the stack-specific host prep. Docs use
`ryan` as the concrete example username (replacing `deploy`).

Out of scope (noted, not done): the 1Password secrets workflow feels heavier than a
single-VPS stack needs — tracked as an open gap in `CHANGES.md` to revisit later.

## Decisions (confirmed with user)

- **Keep** the `docker`-group add (`usermod -aG docker $USER`) and the
  `/etc/docker/daemon.json` log-rotation + restart. Only the *install* is removed.
- **Delete** `scripts/create-deploy-user.sh`. A non-root sudo user is a prerequisite.
- Generalize `deploy` → `ryan` as the example username across docs.

## Changes

### 1. `scripts/bootstrap-plausible-stack.sh`
- Replace the "Base packages + Docker CE" block (lines 12–33) with:
  - A **preflight check** that `docker` and `git` are present, erroring clearly if not
    (mirror the existing `exit 1` error style already used at lines 29–33):
    ```sh
    for cmd in docker git; do
      command -v "$cmd" >/dev/null 2>&1 || {
        echo "ERROR: '$cmd' not found. Install Docker and git first (see README Requirements)." >&2
        exit 1; }
    done
    ```
  - A minimal apt step for what the script *itself* still needs: `sudo apt update` +
    `sudo apt install -y ufw ca-certificates` (drops `curl`/`gnupg` — those were
    Docker-keyring only; `git` is now a prerequisite).
- **Keep** unchanged: `usermod -aG docker "$USER"` (line 36), swap (38–47), log
  rotation (49–53), UFW (55–62), working tree (64), ClickHouse config fetch (67–72,
  still pinned to `v3.2.1`, still uses `git`).
- Update the closing echo (75–79): drop the "Docker" framing; keep "log out/in so the
  docker group applies".

### 2. Delete `scripts/create-deploy-user.sh`

### 3. `DEPLOY.md`
- Expand the "Assumptions" block with a **Prerequisites** bullet: Docker + git
  installed; you operate as a non-root user with sudo + Docker access (example `ryan`);
  your SSH key already logs that user in.
- Remove step **2 "Create the deploy user (as root)"**; renumber 3–8 → 2–7.
- Bootstrap step: `ssh deploy@` → `ssh ryan@`; drop "Docker," from the inline
  comment (now "4 GB swap, UFW 22/80/443, log rotation, ClickHouse configs").

### 4. `docs/checklist.md`
- Add a **Prerequisites** section at top (Docker + git installed; non-root sudo user
  with Docker access, example `ryan`).
- Line 6: replace "Create deploy user (`scripts/create-deploy-user.sh`)…" with a
  confirm-key-login line for the existing user.
- Line 7: drop the Docker-install mention from the bootstrap description.
- Line 34: `ssh deploy@` → `ssh ryan@`.

### 5. `docs/ssh-hardening.md`
- Environment note (8–9): drop "created by `scripts/create-deploy-user.sh`"; describe a
  non-root user, example `ryan`, and say "substitute your username".
- Replace `deploy` → `ryan` at the example sites (lines 21, 48 `AllowUsers`, 74, 78).

### 6. `scripts/harden-host.sh`
- Header comment (line 14): "as the deploy user" → "as your non-root user (e.g. `ryan`)".

### 7. `README.md`
- Add a short **Requirements** note near Quick start: Docker + git installed on the
  VPS; a non-root user with sudo + Docker access.

### 8. `CLAUDE.md`
- Host-bootstrap command description (~line 33): drop "Docker" from the install list
  (bootstrap no longer installs it).

### 9. `CHANGES.md` (record the decision + the deferred note)
- New entry: **"Docker + a non-root user are prerequisites, not provisioned here."**
  Why (bootstrap install block + `create-deploy-user.sh` were brittle on real VPSes);
  what bootstrap still does (preflight, swap, UFW, Docker log rotation, docker-group
  add, ClickHouse fetch); trade-off (operator installs Docker/git + creates their user
  first); revisit trigger (want turnkey provisioning → restore from git history).
- Update the existing **"Rootful Docker"** entry to note the repo no longer *installs*
  Docker — it only relies on group membership.
- Add to **Open gap**: 1Password coupling is heavier than this single-VPS stack needs;
  revisit a simpler secret-provisioning path. (Tracked, not addressed.)

## Notes / guardrails checked
- The Plausible-pin decision (`CHANGES.md` ~L76) lists four files that bump together
  incl. `bootstrap-plausible-stack.sh`; bootstrap **keeps** the `-b v3.2.1` ClickHouse
  clone, so that contract is intact.
- No `compose.yml` / `Caddyfile` / `config/` changes.

## Verification
- `bash -n scripts/bootstrap-plausible-stack.sh` (syntax) and confirm
  `scripts/create-deploy-user.sh` is gone.
- `grep -rn "create-deploy-user\|deploy@" --include=*.md --include=*.sh .` returns
  nothing (all references cleaned / renamed to `ryan`).
- Dry-run the preflight: temporarily hide docker on PATH → script exits with the clear
  error; with docker+git present it proceeds.
- On a fresh/staging Debian 13 VPS (as `ryan`, Docker+git pre-installed): run bootstrap
  → swap active, UFW 22/80/443, `/etc/docker/daemon.json` present, ClickHouse XMLs
  fetched; then `scripts/deploy-services.sh` + `curl -I https://$DOMAIN`.
