# 🎨 One paste-and-go ChatGPT prompt for the comic

This file gives you **one master prompt** to paste into ChatGPT (image generation) to
produce the *Self-Hosted* comic in the Adrian-Tomine / New-Yorker style — deadpan,
ironic, not cute.

> **How to use it**
> 1. Paste **Block A** once to set the style and cast (ChatGPT will remember it in the chat).
> 2. Then paste each **page prompt** from `manga/plausible-stack/page-01.md … page-06.md`,
>    one message at a time. Because Block A is in context, every page stays consistent.
>
> Or, if you just want **one single image fast**, skip the per-page files and paste
> **Block B** below — it renders the whole story as one 6-panel page.

---

## Block A — paste first (style + cast lock)

```
You are illustrating a six-page literary comic called "Self-Hosted." Keep the style
and characters IDENTICAL across every page I ask for. Do not make it cute.

STYLE (use for every image, verbatim):
Modern literary graphic-novel art in the vein of Adrian Tomine and New Yorker cover
illustration. Clean ligne-claire linework, thin even ink weight, restrained and
precise. Flat muted color palette: dusty blues, ochre, olive, warm gray; soft
print-like tones, no glossy rendering, no gradients, slight risograph texture.
Naturalistic adult proportions and understated faces; quiet, deadpan, melancholic.
Urban realism — apartments, laptops, fluorescent light, late-evening windows. Dry,
ironic, observational comedy that comes from composition and silence, not
exaggeration. Clean typeset caption boxes and small naturalistic speech balloons with
New-Yorker-style dry captions. NOT manga chibi, NOT cute, NOT shonen, NOT glossy 3D,
NOT action lines.

RECURRING CAST (draw them the same every time):
- DANA, 34: black bob with blunt bangs, tired eyes, round wire glasses, oversized
  olive cardigan over a white tee, chipped ceramic mug, faint permanent frown.
- THEO, 38: shaved head, dark stubble beard, heavy eyebrows, calm half-lidded face,
  faded blue mechanic jacket over a gray hoodie, carries a mechanical keyboard like a
  clipboard.
- Supporting props drawn as realistic adults/objects, never mascots: a tired green-
  coated doorman (HTTPS), two silent gray-cardiganed filing clerks (the databases),
  an unglamorous locksmith (security), a small wall safe (the password manager).

Confirm you've got it, then wait for me to send each page.
```

---

## Block B — the all-in-one single-image version (whole story, one page)

Paste this on its own if you want one image instead of six:

```
Create a single six-panel literary comic page titled "Self-Hosted."

STYLE: Modern literary graphic-novel art in the vein of Adrian Tomine and New Yorker
cover illustration. Clean ligne-claire linework, thin even ink weight. Flat muted
palette: dusty blues, ochre, olive, warm gray; soft risograph texture, no gradients,
no gloss. Naturalistic deadpan adults, urban realism, late-evening apartment light.
Dry, ironic, New-Yorker-cartoon humor from composition and silence. NOT cute, NOT
chibi, NOT shonen, NOT 3D. Typeset caption boxes and small speech balloons.

CHARACTER: DANA, 34 — black bob with blunt bangs, round wire glasses, oversized olive
cardigan, chipped mug, faint frown.

The six panels, left-to-right, top-to-bottom:
1. Dana alone at a laptop at night, city dark behind the window. Caption: "Dana ran a
   blog. Eleven people read it. She wanted to know which eleven."
2. Her screen shows a generic analytics dashboard with a giant "Accept all cookies?"
   banner drawn like a small eviction notice. Caption: "Free analytics. You pay with
   everyone who visits."
3. A bare $5-a-month rented studio apartment across town, one bulb, one window.
   Caption: "So she rented a small computer across the internet — a VPS — and hosted
   the analytics herself."
4. The front door of that building, where a tired green-coated doorman installs his
   own brass deadbolt. Caption: "One guarded door. The lock — HTTPS — installs and
   renews itself."
5. A windowless back office where two silent filing clerks keep the records, sealed
   off from the street. Caption: "The data lives in a room with no door to the
   outside."
6. Dana back at her laptop, looking at a clean private dashboard reading "Visitors
   today: 1 (you)." Deadpan. Caption: "Private. Secure. Entirely hers. It said one."

Muted, quiet, ironic. Leave room for the lettering.
```

---

### Tips for great results in ChatGPT
- Generate **one page per message** (Block A method) for the most consistent faces.
- If a page drifts cute or glossy, reply: *"redo, flatter color, thinner lines, more
  deadpan, Adrian Tomine, less cute."*
- Ask for the **same characters** by name each time ("Dana and Theo as established").
- Want a printable booklet after? Save each image as
  `manga/plausible-stack/panels/plausible-stack_page01.png` … `page06.png` and run the
  `manga-pdf-generator` skill.
