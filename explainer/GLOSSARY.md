# Glossary — plain-English terms used in this project 🍃

Every piece of jargon in this repo, explained like you've never seen a server.
Ordered roughly from "the big picture" down to "the small parts."

---

## The big ideas

**VPS (Virtual Private Server)**
A computer you rent in a data center, by the month, that's *yours alone*. It's
"virtual" because one big physical machine is sliced into many independent virtual
ones — you get a slice. This project targets the cheapest tier: **2 vCPU, 2 GB RAM,
~$5/month**. Think: renting a small studio apartment across town that's always on.

**Self-hosting**
Running software on a machine *you* control instead of paying a company to run it
for you. The trade: more control and privacy, in exchange for being the one
responsible for keeping it secure and online.

**Debian 13**
The operating system on the VPS — a popular, stable, free version of Linux. It's the
"bare apartment" the rest of the stack moves into.

**The stack / edge stack**
"Stack" = the whole set of programs that work together to make one thing run.
"Edge" = it sits at the *edge* of the internet, directly facing the public, with no
other company's service in front of it ("direct-exposure").

---

## What it actually runs

**Plausible Analytics**
The star of the show: a lightweight, privacy-friendly website-stats dashboard. It
tells you visitor counts, top pages, and referrers **without cookies** and **without
storing anything personal** — so you don't need a cookie-consent banner. It's the
open-source alternative to Google Analytics. This repo runs the free, self-hosted
**Community Edition**.

**Analytics**
Just "website statistics" — how many people visited, which pages, where they came
from.

**Cookies / cookie banner**
A cookie is a small file a site stores in your browser to recognize you later.
Tracking cookies are why you see "Accept all cookies?" popups everywhere. Plausible
uses none, so the banner isn't needed.

---

## The front door

**Caddy**
The web server that sits at the front. It's the **only** part of the stack the public
internet can reach. It receives every visitor and passes them to Plausible.

**Reverse proxy**
What Caddy *does*: it stands in front of another program (Plausible) and forwards
requests to it. Like a receptionist who takes all callers and routes them to the
right desk — visitors never talk to the desk directly.

**HTTPS**
The secure version of HTTP, the language browsers and websites speak. The "S" is for
*Secure*. It does two things: (1) **encrypts** the traffic so nobody in between can
read it, and (2) **proves** the site is really who it claims to be. It's the 🔒
padlock in your browser's address bar.

**TLS / SSL**
The actual lock-and-key technology *behind* the HTTPS padlock. (TLS is the modern
name; SSL is the old name people still say out of habit.) When you read "terminates
TLS," it means "Caddy is the thing that handles the encryption."

**Certificate (TLS certificate)**
A digital "ID card" that proves your domain is yours, which is what makes the padlock
trustworthy. Browsers refuse to show the lock without a valid one.

**Let's Encrypt**
A free, automated service that *issues* those certificates. Caddy asks it for one and
renews it automatically — no money, no manual steps.

**HTTP-01 (challenge)**
The method Caddy uses to prove to Let's Encrypt that you really control the domain:
Let's Encrypt sends a request to your site over **port 80**, and Caddy answers it.
(That's why port 80 must be open and your domain must point at the VPS *before* the
first deploy.) The alternative, DNS-01, isn't used here to keep things simple.

**Domain / hostname**
The human-friendly address, e.g. `stats.yourdomain.example`. A **DNS A record** is
the setting at your domain registrar that points that name at your VPS's IP address.

**Port (80 / 443)**
A numbered "door" on a server for a specific kind of traffic. **Port 80** is plain web
(HTTP), **port 443** is secure web (HTTPS). In this stack, *only* these two doors are
open to the public — everything else is sealed.

---

## The back room (databases)

**Database**
A program that stores and organizes data so it can be saved and searched. This stack
uses two, each for a different job.

**PostgreSQL ("Postgres")**
A general-purpose database. Here it holds the "boring but important" records: your
account, login, and site settings.

**ClickHouse**
A specialized database built to count and add up *huge* numbers of events extremely
fast. Here it stores every page-view. It's the "spiky" one — it can briefly demand a
lot of memory, which is why the setup adds extra swap (see below).

**Internal network / `plausible_internal`**
A private hallway connecting the programs *inside* the server, with **no connection
to the internet at all**. The databases live here, so the outside world can't even
find their door — only Plausible (inside) can reach them.

---

## How it's packaged & run

**Docker**
A tool that packages a program plus everything it needs into a self-contained
"container," so it runs the same anywhere. Each service here (Caddy, Plausible, the
databases) runs in its own container.

**Container**
One running, isolated package created by Docker. Like a shipping container: sealed,
standardized, stackable.

**Docker Compose / `compose.yml`**
A single file that describes *all* the containers, how they connect, and their
limits — so you can start the whole stack with one command. `compose.yml` is this
project's master blueprint.

**Image (e.g. `caddy:2-alpine`)**
The template a container is created from — like a frozen snapshot of a program ready
to run. "alpine" just means a tiny, minimal version.

**`mem_limit`**
A ceiling on how much memory a container is *allowed* to use, set so all of them
together fit inside the VPS's 2 GB.

**Swap / swapfile**
Spare "overflow" memory borrowed from disk for when RAM runs out. This stack
deliberately creates a large swapfile so the box survives ClickHouse's memory spike
during first-time setup instead of crashing.

**Volume**
A storage area Docker keeps *outside* the container, so your data survives when a
container is restarted or upgraded. Your stats live in volumes.

---

## Keeping it safe

**Host hardening**
General term for "making the server harder to break into." This repo's
`harden-host.sh` sets up the two below.

**Fail2Ban**
A bouncer that watches for repeated failed login attempts and temporarily **bans**
the offending source. Stops automated password-guessing attacks.

**Unattended upgrades**
Automatic installation of security updates, so known holes get patched (often
overnight) without you having to remember.

**SSH / SSH hardening**
**SSH** is the secure remote "command line" you use to log into the server. *Hardening*
it means locking that login down — e.g. keys instead of passwords. Done by hand here,
per `docs/ssh-hardening.md`.

**TOTP (Two-factor / 2FA)**
"Time-based One-Time Password" — the rotating 6-digit code from an authenticator app.
Plausible has this built in for its own login, which is why this stack does **not**
add a separate login gate in front of it.

---

## Secrets & configuration

**Secret**
Any sensitive value — a password, an API key, an encryption key. The golden rule:
secrets must **never** be written into files that get shared or committed to git.

**1Password**
The password manager this project uses as the "safe" where secrets live. At deploy
time the real values are pulled *from* the safe — they're never typed into the repo.

**`.env` file**
A plain file of `KEY=value` settings a program reads at startup. Here it holds the
real secrets — so it is **generated** from 1Password and **gitignored** (never
committed).

**`.env.1pass` (template)**
A *safe-to-share* version of the `.env` file. Instead of real secrets it contains
`op://...` references — pointers that say "fetch this value from 1Password." Running
the generate script turns this template into the real `.env`.

**gitignored**
Listed in `.gitignore`, meaning git is told to **ignore** that file so it's never
accidentally committed/shared. Real secrets are always gitignored.

**Bootstrap / deploy / smoke test**
- **Bootstrap** (`bootstrap-edge-stack.sh`): one-time setup of the fresh server
  (installs Docker, makes the swapfile, fetches configs).
- **Deploy** (`deploy-services.sh`): pull the latest container images and start
  everything (`docker compose pull && up -d`).
- **Smoke test**: a quick check that it's alive — here, `curl -I https://stats.yourdomain.example`
  to confirm the site responds.

---

> **Rule of thumb for reading this repo:** *Caddy is the only door. The databases are
> in a windowless back room. The secrets are in a safe. Everything else is just
> plumbing to make those three things true.*
