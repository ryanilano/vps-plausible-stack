# CHANGES — Decision log (S-tier, Plausible only)

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
- Revisit if: privilege separation matters → rootless Docker.

## Host hardening
- `fail2ban` bans SSH brute-forcers via the **UFW** action (coexists with the
  firewall) using the **systemd** journal backend; `ignoreip` whitelists your
  admin IP (anti-lockout).
- `unattended-upgrades` applies **Debian security** updates only; Docker CE is
  blacklisted (deliberate pin); auto-reboot off.
- SSH hardening is **manual** (`docs/ssh-hardening.md`) so a script can't lock
  you out — note the Debian 13 socket-activation caveat there.

## Open gap
- **Backups** — no strategy yet for Plausible Postgres + ClickHouse (logical
  dumps, not file copies). Tracked, not solved.
