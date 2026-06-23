# Manifest — *Self-Hosted* (an educational comic)

- **Title:** *Self-Hosted*
- **Source:** `vps-plausible-stack` repo (this project) — self-hosting Plausible Analytics on a low-cost Debian VPS behind Caddy, with internal-only databases, host hardening, and 1Password-managed secrets.
- **Topic slug:** `plausible-stack`
- **Audience:** Motivated newcomer / curious adult. Assumes you've heard of "websites" and "Google Analytics" but not the infrastructure underneath.
- **Depth:** Conceptual. Teaches what each moving part *is* and *why it exists*, not how to type the commands.

## Style preset (LOCKED)

**Custom — "Literary indie-comics / editorial-cartoon deadpan."** Not the cute version. Restated verbatim in every page prompt.

```
Style:
Modern literary graphic-novel art in the vein of understated ligne-claire indie / alternative comics and editorial-cartoon
cover illustration.
Clean ligne-claire linework, thin even ink weight, restrained and precise.
Flat muted color palette: dusty blues, ochre, olive, warm gray; soft print-like
tones, no glossy rendering, no gradients, slight risograph texture.
Naturalistic adult proportions and understated faces; quiet, deadpan, melancholic.
Urban realism — apartments, laptops, fluorescent light, late-evening windows.
Dry, ironic, observational comedy. Comedy comes from composition and silence,
not exaggeration.
Not manga chibi. Not cute. Not shonen. Not glossy 3D. Not action lines.
Lettering: clean typeset caption boxes and small naturalistic speech balloons,
dry, understated editorial captions.
```

## Core concepts (dependency order)

1. The surveillance default — why ordinary web analytics is a privacy problem.
2. The escape hatch — renting a **VPS** and self-hosting Plausible (what a VPS is).
3. The front door — **Caddy** and automatic **HTTPS** (what HTTPS / TLS is).
4. The back room — internal-only **Postgres + ClickHouse** databases (private network).
5. Locks & keys — **host hardening** (Fail2Ban, auto-updates) and **1Password** secrets.
6. The punchline — she owns all her data now. Almost nobody visits. (central irony)

## Page table

| # | Concept | Narrative purpose | Visual metaphor | Status |
|---|---------|-------------------|-----------------|--------|
| 1 | Surveillance default | Problem | A cookie-consent banner as a tiny eviction notice | prompt-ready |
| 2 | VPS + self-hosting | Mechanism (intro) | Renting an empty studio apartment across town | prompt-ready |
| 3 | Caddy + HTTPS | Mechanism | A doorman who installs his own deadbolt | prompt-ready |
| 4 | Internal databases | Mechanism / tradeoff | Two filing clerks in a windowless back office | prompt-ready |
| 5 | Hardening + secrets | Consequence / safety | A locksmith; keys kept in a safe, never on the desk | prompt-ready |
| 6 | Ownership vs. obscurity | Recap + irony | A pristine dashboard reading "1 visitor (you)" | prompt-ready |
