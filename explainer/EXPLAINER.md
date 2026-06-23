# Your Own Analytics, On Your Own Server 🍃

### What this repo gives you, in one sentence

A copy-paste recipe to run **your own private website analytics** on a **cheap ~$5/month server** — no Google, no cookie banners, no selling your visitors' data.

---

## The problem it solves

Most websites use **Google Analytics**. In exchange for "free" stats, you hand Google a full record of everyone who visits your site. That means:

- 🍪 Annoying cookie-consent popups you're legally required to show
- 🕵️ Your visitors get tracked across the web
- 📉 Ad-blockers silently break your stats anyway
- 🔒 You don't actually *own* your data — Google does

## The alternative this builds

**Plausible Analytics** — a lightweight, privacy-friendly stats dashboard. Same useful numbers (visitors, top pages, where they came from), but:

- ✅ No cookies, no consent banner needed
- ✅ Visitors stay anonymous — nothing personal is stored
- ✅ The data lives on **your** server, not a corporation's
- ✅ A tiny script that loads ~45× faster than Google Analytics

Plausible normally costs a monthly subscription. This repo runs the **free, self-hosted version** instead.

---

## What's actually in the box

Think of it like a pre-built **flat-pack furniture kit** for a server. You bring a blank rented computer ("a VPS"), and this kit has all the instructions and parts:

| Part | Plain-English job |
|------|-------------------|
| **Caddy** | The front door & security guard. Handles web traffic and gets you a free 🔒 HTTPS padlock automatically. |
| **Plausible** | The actual analytics dashboard you log into. |
| **PostgreSQL** | A filing cabinet for your account & site settings. |
| **ClickHouse** | A super-fast filing cabinet built for counting page views. |
| **Scripts** | The "assembly instructions" — they set up, secure, and launch everything for you. |
| **1Password** | The locked safe where your passwords live (they never get written into the code). |

Only the **front door (Caddy)** is exposed to the internet. The filing cabinets are locked in a back room nobody outside can reach.

---

## How it works (the 10-second version)

```
   A visitor lands on your website
                │
                ▼
   ┌─────────────────────────┐
   │   🔒 Caddy (front door)  │  ← free auto-HTTPS
   └─────────────────────────┘
                │
                ▼
   ┌─────────────────────────┐
   │   📊 Plausible dashboard │  ← you log in here
   └─────────────────────────┘
                │
         ┌──────┴──────┐
         ▼             ▼
   🗄️ Postgres    ⚡ ClickHouse
   (settings)     (the counting)
```

---

## Why it's a nice piece of work

- **Cheap by design.** Tuned to fit the *smallest, least expensive* server tier (2 CPU / 2 GB RAM). Adds extra "swap" memory so it never falls over during setup.
- **Secure by default.** Auto-installs security updates, blocks brute-force login attempts (Fail2Ban), and keeps the databases off the public internet entirely.
- **Secrets stay secret.** Passwords are pulled from 1Password at deploy time — they're never committed into the project files.
- **No lock-in.** It's plain Docker config and shell scripts. You can read every line and it's all yours.

---

## Who is this for?

- 🧑‍💻 A developer who wants honest stats for their blog or side project
- 🏢 A small business that doesn't want to leak customer data to ad networks
- 🔐 Anyone who believes *"if it's about my visitors, it should live on my machine."*

> **TL;DR** — It's a tidy, security-conscious starter kit that turns a $5 rented server into your own private Google-Analytics-replacement, with the padlock and the locks already figured out.
