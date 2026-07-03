# Adding a site to this Plausible instance

Plausible CE is multi-site out of the box — this one VPS can collect analytics for
any number of domains with **no infrastructure change**. You only touch the
Plausible dashboard and the target site: register the domain, drop in the tracking
snippet, and (recommended) serve that snippet first-party so ad-blockers don't drop
your traffic.

Throughout, `STATS_HOST` means this instance's public host — the `DOMAIN` value in
`.env` (e.g. `stats.yourdomain.example`).

## 1. Register the site in Plausible

1. Log in at `https://STATS_HOST` with the owner account. `DISABLE_REGISTRATION=true`
   blocks new *account* signups only — adding sites to the existing account still
   works.
2. **Add a website** → enter the domain exactly as visitors see it (e.g.
   `example.com`, no scheme, no `www.` unless the site actually serves `www.`).
   This string is the site's identity in Plausible and must match `data-domain`
   in the snippet character-for-character.

## 2. Add the tracking snippet to your site

Drop this into the site's `<head>`. This is the standard Plausible snippet, pointed
straight at this instance:

```html
<script defer data-domain="example.com" src="https://STATS_HOST/js/script.js"></script>
```

- Replace `example.com` with the domain you registered in step 1 (they must match
  exactly) and `STATS_HOST` with this instance's host.
- **Plain HTML / most frameworks:** put the tag in `<head>`.
- **Next.js (App Router):** use `next/script` in `app/layout.tsx`:

  ```tsx
  import Script from "next/script";
  // inside <head> (or top of <body>):
  <Script
    defer
    data-domain="example.com"
    src="https://STATS_HOST/js/script.js"
    strategy="afterInteractive"
  />
  ```

This alone starts collecting data. **But** the `/js/script.js` path and `/api/event`
endpoint are trivially blocked by ad-blockers (see step 3), so a chunk of traffic
goes uncounted. To fix that, serve the snippet first-party — which changes only the
`src`.

## 3. (Recommended) Serve the snippet first-party

> **Why?** A standard `<script src="https://STATS_HOST/js/script.js">` is trivially
> blocked: filter lists (EasyPrivacy et al.) match on the `/js/script.js` path, the
> `/api/event` endpoint, and analytics-style subdomains — a custom `stats.` host does
> not evade them. Proxying those two paths through the site's own domain makes the
> requests indistinguishable from first-party traffic, so nothing is blocked and data
> is materially more complete.

Pick the recipe for your platform. Each one proxies `/js/script.js` and `/api/event`
through the site's own domain, then points the snippet's `src` at the **local** path.

### Vercel: `vercel.json`

```json
{
  "rewrites": [
    { "source": "/js/script.js", "destination": "https://STATS_HOST/js/script.js" },
    { "source": "/api/event",    "destination": "https://STATS_HOST/api/event" }
  ]
}
```

Replace `STATS_HOST` with the real host and deploy so the rewrites go live. Then
change the snippet's `src` from step 2 to the **local** path (`data-domain` stays):

```html
<script defer data-domain="example.com" src="/js/script.js"></script>
```

For Next.js, change the `src` on the `<Script>` tag the same way.

### Cloudflare: Worker in front of static assets

For a Cloudflare-hosted site (Pages, or a static Astro/Vite site deployed as a
Worker with static assets), a `vercel.json` rewrite has no equivalent — proxy with
a small Worker instead. This also handles Plausible CE's **newer script format**
(`pa-<random>.js` + `plausible.init()`), which bakes the *absolute* event endpoint
into the script body, so the Worker rewrites it to a relative path.

Add `main` + an assets binding to `wrangler.jsonc`:

```jsonc
{
  "name": "example-site",
  "main": "worker/index.ts",
  "assets": { "directory": "./dist", "binding": "ASSETS" }
}
```

`worker/index.ts` — serve the script first-party (rewriting the baked endpoint) and
proxy events, forwarding the real visitor IP:

```ts
const UPSTREAM = "https://STATS_HOST";
const SCRIPT_UPSTREAM = `${UPSTREAM}/js/pa-XXXXXXXX.js`; // the site's generated script
const SCRIPT_PATH = "/js/p.js";   // bland, first-party name
const EVENT_PATH  = "/api/event";

export default {
  async fetch(request: Request, env: { ASSETS: { fetch(r: Request): Promise<Response> } }) {
    const { pathname } = new URL(request.url);
    if ((request.method === "GET" || request.method === "HEAD") && pathname === SCRIPT_PATH) {
      const up = await fetch(SCRIPT_UPSTREAM);
      const body = (await up.text()).replaceAll(`${UPSTREAM}${EVENT_PATH}`, EVENT_PATH);
      return new Response(body, { headers: { "content-type": "application/javascript; charset=utf-8", "cache-control": "public, max-age=21600" } });
    }
    if (request.method === "POST" && pathname === EVENT_PATH) {
      const h = new Headers({ "content-type": request.headers.get("content-type") || "text/plain" });
      const ip = request.headers.get("cf-connecting-ip");
      if (ip) { h.set("x-forwarded-for", ip); h.set("x-real-ip", ip); }
      return fetch(`${UPSTREAM}${EVENT_PATH}`, { method: "POST", headers: h, body: await request.text() });
    }
    return env.ASSETS.fetch(request);
  },
};
```

Snippet for this variant (same-origin, no `data-domain` — the `pa-*.js` script
carries the site id):

```html
<script is:inline defer src="/js/p.js"></script>
```

If `/js/p.js` returns a static-asset 404 after deploy, the assets layer is winning
over the Worker — add `"run_worker_first": ["/js/p.js", "/api/event"]` to the
`assets` block.

## 4. Verify

- If you proxied (step 3): `curl -I https://example.com/js/script.js` → `200` (the
  proxy is serving it first-party, not a 404).
- Open the site, then watch Plausible **Realtime** for `example.com` — a live
  visitor should show within seconds.
- After a day, confirm the **Countries** report is populated. If it stays empty,
  the client IP isn't surviving the extra proxy hop: check that the proxy forwards
  `x-forwarded-for` (Vercel rewrites do) and that Caddy passes it upstream
  (`reverse_proxy` does by default).

That's it — no ports, secrets, `compose.yml`, or `Caddyfile` edits. Repeat per
domain; each site gets its own `data-domain` and its own proxy config.
