# 🍃 *Self-Hosted* — A Manga Explainer

> A 6-page literary comic that explains **vps-plausible-stack** to a curious adult:
> why you'd self-host your own privacy-friendly analytics, and what every moving part does.
> Each page has the **story beat**, the **on-page captions/dialogue**, and a condensed
> **🎨 Image Prompt** you can drop into ChatGPT / DALL·E / Midjourney / Gemini.

This file is the quick index. The canonical, full-length per-page prompts live in
`manga/plausible-stack/page-01.md … page-06.md` — paste those for the best results.
Cast and continuity are defined in `manga/plausible-stack/character-sheet.md` and
`manga/plausible-stack/manifest.md`. For one paste-and-go prompt, see `CHATGPT-PROMPT.md`.

**Art direction (LOCKED — paste this once at the top of any image session):**
> Modern literary graphic-novel art in the vein of Adrian Tomine and New Yorker cover
> illustration. Clean ligne-claire linework, thin even ink weight, restrained and precise.
> Flat muted palette: dusty blues, ochre, olive, warm gray; soft print-like tones, no
> gradients, slight risograph texture. Naturalistic adult proportions, understated faces;
> quiet, deadpan, melancholic. Urban realism — apartments, laptops, fluorescent light,
> late-evening windows. Dry, ironic, observational comedy from composition and silence,
> not exaggeration. **Not** manga chibi, **not** cute, **not** shonen, **not** glossy 3D,
> **no** action lines. Lettering: clean typeset caption boxes and small naturalistic speech
> balloons, New-Yorker-style dry captions.

**The cast:**
- **Dana** — 34, indie dev who runs a blog almost nobody reads. Black bob with blunt bangs,
  tired eyes, round wire glasses, oversized olive cardigan, chipped ceramic mug, faint
  permanent frown. Our deadpan POV.
- **Theo** — 38, the friend who self-hosts everything and is quietly smug about it. Shaved
  head, stubble, heavy brows, faded blue mechanic jacket over a gray hoodie, carries a
  mechanical keyboard like a clipboard. Deadpan evangelist.
- **The stack, drawn as mundane props — never cute mascots:** **Caddy** = a tired doorman in
  a green coat who installs his own deadbolt (HTTPS). **Postgres & ClickHouse** = two silent
  filing clerks in a windowless back office (ClickHouse works suspiciously fast).
  **Hardening** = an unglamorous locksmith changing the locks at 2 a.m. **1Password** = a
  small wall safe.

---

## Page 1 — The Surveillance Default

**Beat:** Ordinary analytics quietly watches Dana's visitors. Establish the problem and her
deadpan unease — she wants honest numbers without a stranger in the room.

**Text:**
- Caption (open): *Dana ran a blog. Eleven people read it. She wanted to know which eleven.*
- Caption: *Free analytics. You only pay with everyone who visits.*
- Dana (deadpan, into her mug): *"So Google watches my visitors… so I can watch my visitors."*
- Caption (close): *There had to be a version of this that didn't involve a stranger in the room.*

> 🎨 **Image Prompt:** [Tomine/New Yorker art direction above.] Six-panel page. A cramped,
> tidy-but-worn apartment at night; one laptop, a window of city lights, a dead plant on the
> sill. Dana alone, lit by the screen. A generic analytics dashboard shows a giant cheerful
> "Accept all cookies?" banner, drawn like a small bureaucratic eviction notice taped to the
> glass. In one symbolic beat, a second taller shadow in a suit joins hers on the wall — the
> unseen third party — and she hasn't noticed. She closes the laptop halfway, unreassured.

---

## Page 2 — Renting a VPS (Self-Hosting)

**Beat:** Theo's fix — rent a small remote computer and run your own analytics on it instead
of borrowing Google's. Introduce what a VPS is, and Plausible as the app you move in.

**Text:**
- Dana: *"I want my stats without the surveillance."* — Theo, flat: *"Then host it yourself."*
- Caption: *A VPS is a small computer you rent in a data center. Yours alone, somewhere across town.*
- Caption: *Two cores. Two gigabytes of memory. The cheapest unit in the building.* ($5/month)
- Caption: *Plausible: it counts visits. No cookies, nothing personal, nobody else in the room.*
- Caption (close): *She had rented a small dark room across the internet. Now she had to make it secure.* — Theo: *"That's the long part."*

> 🎨 **Image Prompt:** [Art direction above.] Six-panel page. A fluorescent-lit café: Dana
> across from Theo, who sets his mechanical keyboard down like a briefcase and slides over a
> napkin sketch of a tiny apartment building far away. Cut to a bare rented studio across
> town — single bulb, one window, a "$5 / month" price tag on the door. Dana peers in: *"It's
> empty."* A clean diagram appears as graffiti on the wall: a box labeled **VPS** with a
> smaller box inside, **Plausible — the analytics app.** Dana stands in the empty room with
> her mug, considering it.

---

## Page 3 — Caddy & Automatic HTTPS (The Front Door)

**Beat:** One public-facing front door that encrypts traffic and gets its own lock (a TLS
certificate) for free, automatically. Teach what the browser padlock actually means.

**Text:**
- Caption: *Only one door faces the street. Everything else is sealed.* (brass plaque: "PORT 80 / 443 — DELIVERIES & GUESTS ONLY")
- Caption: *Caddy answers the door. He's the only part of the building the public ever touches.*
- Caption: *On his own, he requests a certificate from Let's Encrypt and installs the lock — that lock is HTTPS.* — Caddy, flat: *"Renews itself, too."*
- Caption: *HTTPS: the message is sealed in transit, and the lock proves the door is really yours.*
- Dana: *"So the padlock in the browser bar is… him."* — Caddy, deadpan: *"It's me."*

> 🎨 **Image Prompt:** [Art direction above.] Six-panel page. The front entrance of the studio
> building as the "front door" of the whole stack, street at dusk. **Caddy** — a tired doorman
> in a green coat, realistic, not cute — stands at the only door and, unprompted, screws a
> heavy brass deadbolt onto it himself. A split diagram: an "http" letter travels as a
> readable postcard anyone can read; an "https" letter travels inside a sealed, padlocked
> envelope. Dana watches from the sidewalk, mildly impressed despite herself. Pull back: one
> lit, guarded door; everything behind it dark and private, a faint glow from a back room.

---

## Page 4 — The Internal Databases (The Back Room)

**Beat:** Postgres and ClickHouse live in a windowless back office on an internal-only
network — never reachable from the internet. Teach the idea of a private network.

**Text:**
- Caption: *Behind Caddy, two clerks do the actual record-keeping. There is no door from this room to the street.*
- Caption: *Postgres keeps the boring, important paperwork: your login, your site list.*
- Caption: *ClickHouse only counts. Built to add up millions of visits without breaking a sweat.*
- Caption: *They share a private hallway. The outside world can't even find the door.* (wall labeled "no internet access")
- Dana, flat: *"There's no way in here from outside."* — ClickHouse, not looking up: *"Correct."*
- Caption (close): *The data lived in a room with no windows. Which was, she admitted, the nicest thing anyone had done for it.*

> 🎨 **Image Prompt:** [Art direction above.] Six-panel page. A windowless interior back
> office behind the front door — fluorescent hum, filing cabinets, one internal door that
> does **not** lead outside. **Postgres** and **ClickHouse** as two silent middle-aged filing
> clerks in identical gray cardigans and sleeve garters; ClickHouse stamps a towering stack
> of identical forms at blurring speed (a single restrained motion-blur on one hand — never
> manga speed-lines). A wall diagram: "Caddy (public)" linked to an "internal network" box
> holding "Plausible / Postgres / ClickHouse," a thick wall labeled "no internet access"
> around the inner three. Dana looks for a window; there isn't one. She quietly closes the
> interior door.

---

## Page 5 — Hardening & Secrets (Locks & Keys)

**Beat:** A server online is probed constantly. Fail2Ban bans the persistent, unattended
upgrades replace the locks overnight, and 1Password keeps passwords out of the code.

**Text:**
- Caption: *The moment a server is online, strangers start trying the door. Constantly. Forever.*
- Caption: *Fail2Ban watches. Try the wrong key too many times— —and you're locked out. Banned. Next.*
- Caption: *Unattended upgrades: the building quietly replaces its own locks the night a flaw is found.* — Theo: *"You don't even wake up for it."*
- Caption: *Secrets go in the safe. Never written into the building's blueprints.* — Theo, flat: *"Anyone can read the blueprints. That's the whole idea of sharing them."*
- Caption (close): *Keys in the safe. Locks that change themselves. A door that bans the persistent. It was, finally, boring. Boring was the goal.*

> 🎨 **Image Prompt:** [Art direction above.] Six-panel page. The studio building at 2 a.m.,
> quiet street. A long, patient line of anonymous figures in identical coats files up to the
> front door, each trying the handle once and moving on; a counter clicks "failed login…
> failed login…". An unglamorous **locksmith** in coveralls (Fail2Ban + hardening) bars one
> figure and bolts the door in their face, then swaps a worn lock for a fresh one while
> everyone sleeps. Inside, Dana goes to slap a password on a sticky note; Theo's hand stops
> her and points at a small wall safe labeled **1Password**. She closes the safe; the key is
> pulled only at the moment it's needed, then gone.

---

## Page 6 — Ownership vs. Obscurity (The Punchline)

**Beat:** Recap and central irony. Dana now owns her analytics completely, privately,
securely — and the dashboard reports almost nobody visits. A deadpan New Yorker bookend.

**Text:**
- Caption: *Her front door, her back room, her keys. All hers.*
- Caption: *No banner. No stranger in the room. Nothing about anyone, except that they came.*
- Dashboard: *Visitors today: 1 (you)* — beat panel, silence.
- Theo: *"Private. Secure. Entirely yours."* — Dana: *"It says one."*
- Theo, flat: *"Nobody can see your numbers but you."* — Dana: *"There don't appear to be any."*
- Caption (close): *She had built a perfect, private, well-defended record of being almost completely alone online. It was the most honest thing she owned.*

> 🎨 **Image Prompt:** [Art direction above.] Six-panel page. Back in Dana's apartment, late
> evening — **same window and dead plant as Page 1**, a deliberate bookend. A recap strip of
> three tiny vignettes: the green-coated doorman with his deadbolt, the windowless back
> office, the little wall safe. Dana opens her own clean Plausible dashboard — no cookie
> banner — showing one immaculate honest number: "Visitors today: 1 (you)." She and Theo
> stare at it, neither smiling. Final wide shot mirroring Page 1: Dana alone at the laptop,
> city dark behind the window — but this time only **one** shadow on the wall. Hers.

---

## How to use this file

1. Paste the **Art direction (LOCKED)** block into your image generator first.
2. Then paste each page's **🎨 Image Prompt** one at a time to get all 6 pages — or, for the
   full verbatim prompts (with the style block restated inline for memoryless models), open
   `manga/plausible-stack/page-01.md … page-06.md`.
3. Add the **Text / dialogue** into the caption boxes and balloons yourself, or ask the model
   to include it.
4. Save renders into `manga/plausible-stack/panels/` as `plausible-stack_page01.png …
   _page06.png` (zero-padded). Stack the 6 pages top-to-bottom for the complete comic. 🍃
