# Notes — *Self-Hosted*

## Assumptions made
- Worked from the repo's own files (`README.md`, `compose.yml`, `Caddyfile`, `CLAUDE.md`).
- Dana's "eleven readers" and the final "1 visitor (you)" are invented for the irony,
  not claims about the software. They dramatize the *obscurity* tension, not a defect.

## Concepts deliberately compressed or omitted (kept off-page to protect pacing)
- **HTTP-01 vs DNS-01** certificate challenges — Page 03 simplifies to "Caddy requests
  a certificate and installs the lock." A sequel page could cover why port 80 must be
  reachable at issuance time.
- **The swapfile / memory tuning** (4 GB swap to absorb the ClickHouse first-migration
  spike on a 2 GB box) — a strong candidate for a bonus "moving day" page.
- **Docker / Compose** as the orchestration layer — implied by "move in what you want"
  on Page 02 but never named, to avoid jargon.
- **TOTP / Plausible's native login** — the reason there's no edge auth gate; a possible
  sequel beat on "why the doorman doesn't check IDs — the dashboard does that itself."

## Possible sequel pages
- *Moving Day* — the bootstrap script, swap, and the scary first ClickHouse migration.
- *Why the door stays simple* — the recorded decision NOT to put an auth gate in front
  of Plausible (it serves public ingestion); maps to `CHANGES.md`.

## Visual metaphors considered and rejected
- Cute mascots (a mango, anthropomorphic padlocks) — explicitly rejected per art
  direction; replaced with realistic deadpan props (doorman, clerks, locksmith, safe).
- A heist framing — too energetic for the literary-comics register; kept it domestic and quiet.

## Continuity reminders for the artist
- Page 06 is a deliberate **bookend** of Page 01: same apartment, window, dead plant —
  but one shadow instead of two. Keep those elements consistent.
- ClickHouse is the only "fast" element; suggest speed with restraint (a single blurred
  hand), never with manga speed-lines.
