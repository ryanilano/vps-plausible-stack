# Adding a site to this Plausible instance

Plausible CE is multi-site out of the box — this one VPS can collect analytics for
any number of domains with **no infrastructure change**. You only touch the
Plausible dashboard and the target site. This guide uses a Vercel-hosted site as
the example; the dashboard step is identical for any host.

Throughout, `STATS_HOST` means this instance's public host — the `DOMAIN` value in
`.env` (e.g. `stats.yourdomain.example`).

## 1. Register the site in Plausible

1. Log in at `https://STATS_HOST` with the owner account. `DISABLE_REGISTRATION=true`
   blocks new *account* signups only — adding sites to the existing account still
   works.
2. **Add a website** → enter the domain exactly as visitors see it (e.g.
   `example.com`, no scheme, no `www.` unless the site actually serves `www.`).
   This string is the site's identity in Plausible and must match `data-domain`
   below character-for-character.

## 2. Send events — use a first-party proxy

Serve Plausible's script and event endpoint from the site's **own** domain. This is
the only reliable way to keep ad-blockers from dropping traffic.

> **Why not the plain snippet?** A standard `<script src="https://STATS_HOST/js/script.js">`
> is trivially blocked: filter lists (EasyPrivacy et al.) match on the `/js/script.js`
> path, the `/api/event` endpoint, and analytics-style subdomains — a custom `stats.`
> host does not evade them. Proxying those two paths through the site's own domain
> makes the requests indistinguishable from first-party traffic, so nothing is
> blocked and data is materially more complete.

### Vercel: `vercel.json`

```json
{
  "rewrites": [
    { "source": "/js/script.js", "destination": "https://STATS_HOST/js/script.js" },
    { "source": "/api/event",    "destination": "https://STATS_HOST/api/event" }
  ]
}
```

Replace `STATS_HOST` with the real host. Deploy so the rewrites go live.

### The snippet

Note `src` is the **local** path now, not the VPS URL:

```html
<script defer data-domain="example.com" src="/js/script.js"></script>
```

**Next.js (App Router)** — add to `app/layout.tsx`:

```tsx
import Script from "next/script";
// inside <head> (or top of <body>):
<Script
  defer
  data-domain="example.com"
  src="/js/script.js"
  strategy="afterInteractive"
/>
```

Plain HTML / other frameworks: drop the `<script>` tag in `<head>`.

## 3. Verify

- `curl -I https://example.com/js/script.js` → `200` (the proxy is serving it
  first-party, not a 404).
- Open the site, then watch Plausible **Realtime** for `example.com` — a live
  visitor should show within seconds.
- After a day, confirm the **Countries** report is populated. If it stays empty,
  the client IP isn't surviving the extra proxy hop: check that the proxy forwards
  `x-forwarded-for` (Vercel rewrites do) and that Caddy passes it upstream
  (`reverse_proxy` does by default).

That's it — no ports, secrets, `compose.yml`, or `Caddyfile` edits. Repeat step 1
per domain; each site gets its own `data-domain` and its own proxy config.
