# *Self-Hosted* — an educational comic

A 6-page literary comic that explains the **vps-plausible-stack** project: why you'd
self-host your own privacy-friendly website analytics, and what every moving part does.

**Tone:** deadpan and ironic — in the vein of Adrian Tomine and a New Yorker cartoon.
Not the cute version. The comedy is in the silence and the punchline.

- **Source:** this repo (`vps-plausible-stack`)
- **Audience:** curious adult / motivated newcomer
- **Pages:** 6
- **Cast:** Dana (tired indie dev, our POV) and Theo (deadpan self-hosting evangelist),
  plus the stack drawn as props — a doorman (Caddy/HTTPS), two filing clerks
  (Postgres + ClickHouse), a locksmith (hardening), a wall safe (1Password).

## Pages

1. The surveillance default (the problem)
2. Renting a VPS & self-hosting Plausible
3. Caddy + automatic HTTPS (the front door)
4. The internal-only databases (the back room)
5. Hardening + secrets (locks & keys)
6. Ownership vs. obscurity (the punchline)

## How to generate it

1. Open each `page-01.md` … `page-06.md` and paste its **Image Prompt** into an
   image model (ChatGPT/DALL·E, Midjourney, Gemini).
2. Save each result into `panels/` as `plausible-stack_page01.png`,
   `plausible-stack_page02.png`, … (zero-padded).
3. Optionally run the `manga-pdf-generator` skill to bundle the pages into a PDF.

> Prefer one paste-and-go prompt? See `../../CHATGPT-PROMPT.md` in the explainer
> folder for a single master prompt that produces all six pages in ChatGPT.
