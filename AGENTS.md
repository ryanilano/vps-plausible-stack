# AGENTS.md

## Purpose

A small public VPS that serves Plausible Analytics, documented and automated
for direct operator execution on a Debian 13 VPS.

## System goals

- Serve Plausible at `stats.yourdomain.example` (public; Plausible's own login + TOTP)
- Use Caddy as the reverse proxy and TLS endpoint (automatic HTTP-01)
- Fit a 2 GB VPS

## Design principles

1. Keep scope narrow (Plausible only).
2. Prefer operational simplicity over feature completeness.
3. Keep this edge separate from any homelab/Proxmox host.
4. Protect Plausible with its native TOTP, not an edge gate — it serves public
   ingestion paths that an edge gate would break.

## Environment assumptions

- Debian 13
- Docker Engine from the official Docker repository (rootful)
- A small VPS: ~2 vCPU / 2 GB / 80 GB (e.g. IONOS VPS Linux S)
- Cloudflare-managed DNS, grey-cloud (DNS-only) A record

## Current launch decisions

- Include at launch: Plausible only.
- Defer: a protected dashboard (Heimdall behind Tinyauth, which fits 2 GB), or
  the full identity build (Authentik) — that's the separate **M+** variant.

## Documentation expectations

- Output Markdown whenever possible
- Keep sections clearly named
- Prefer copy-paste-ready commands
- Use separate files for overview, operations, checklist, and configuration
- Keep examples aligned with the single current host and VPS size

## Configuration expectations

- `stats.yourdomain.example` is for Plausible only and is deliberately public
- Caddy uses automatic HTTP-01 (stock image, single host) — no custom build, no
  DNS token

## Operational expectations

- Include health checks where practical
- Monitor memory, disk, and restart loops
- Assume RAM is constrained (2 GB); ClickHouse is the pressure point and the
  first-migration OOM risk

## Preferred output style

- Concise but complete
- Structured for a homelab operator
- Practical over theoretical
- Safe defaults for launch

## Reasoning guardrails

- Broken ≠ wrong. Fix the implementation before discarding a sound approach; a
  misconfigured setup isn't a reason to switch approaches.
- A label isn't a verdict. Don't carry "blocker/risky/problem" forward as
  settled — re-derive each recommendation from specifics.
- Judge against the roadmap, not just launch simplicity. "Simpler now" is wrong
  if it forecloses deferred/planned work (e.g. the deferred dashboard, or a later
  move to the M+ build). If it does, say so; don't default to it.
- Show the trade-off. State what the rejected option gives up (security,
  reversibility, future plans). Recommend clearly, leave the override to me.
- Flag reversals and assumptions. If changing an earlier call, say what changed
  it. If a choice hinges on an unsure direction, ask — don't take the easy path.

Before recommending, check:
1. Approach wrong, or just the implementation?
2. Conflicts with anything deferred/planned?
3. What does the option I'm *not* picking give up?
4. Reversing an earlier call — did I say why?
