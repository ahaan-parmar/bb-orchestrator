---
name: signal-funnel
description: Phase 2 of bb-orchestrator — subtract recon noise instead of adding output, then classify each surviving surface by type (api/graphql/webapp/infra). Use after recon, before surface-router, to turn a big asset list into a small high-signal ranked set a human can reason about.
---

# signal-funnel

The core insight: automation's job here is **subtraction, not addition**. Everyone runs the
same subfinder→httpx→nuclei pipe against the same public programs within hours of launch.
Volume ≠ findings. Output "everything NOT interesting, removed" — leave a dense, high-signal
list. Then branch by surface type, because one flow against everything misses whole bug
classes.

## Input

`state.live_hosts[]` (from recon) + any raw nuclei/katana output in `findings/recon/`.

## Step 1 — Subtract noise

Remove, logging counts of what was dropped:

- **Dead/parked/boilerplate** — non-200 with no auth surface, default vendor landing pages,
  parked domains, CDN-only edges with nothing behind them.
- **Dupes** — same app behind multiple hostnames (same title + tech + response hash) → keep
  one canonical, note aliases.
- **Known-noise nuclei lows** — the misconfig/info-disclosure class every automated hunter has
  already flagged and every program has already dismissed (permissive CSP alone, missing
  security headers alone, version banners, open redirect on a static edge with no impact
  path). These are NOT findings in bug-bounty mode — drop from the ranked set (keep raw for
  reference only).
- **Static-only hosts** — pure marketing/docs with no auth, no input, no API, no state.

Do not remove: anything with auth, input handling, an API, admin/internal naming, upload,
payment, SSO/OAuth, GraphQL, or unusual/non-standard tech. When unsure, keep.

## Step 2 — Classify each survivor by surface type

Tag every remaining surface in `state.surfaces[]` with `type`:

- **graphql** — `/graphql`, `/graphiql`, `/v1/graphql`, Apollo/Hasura fingerprints, GraphQL
  content-types, introspection responses.
- **api** — REST/JSON endpoints, `/api/`, `/v1..v3/`, swagger/openapi specs, mobile backends,
  gRPC-web, JSON always-on.
- **webapp** — server-rendered or SPA with HTML forms, sessions, classic parameters.
- **infra** — panels, dashboards, mail, VPN edges, buckets, dev tooling exposed.

A host can carry multiple surfaces (a webapp with an API) — record each separately; they get
routed to different hunt classes.

## Step 3 — Rank

Score each surface high→low by value signals:

- high: auth/login, payments/checkout, admin/internal, GraphQL with introspection on, file
  upload, SSO/OAuth, account/tenant boundaries, anything handling other users' data.
- mid: general authenticated functionality, user-content, search, webhooks.
- low: read-only public endpoints with no state.

Write `state.ranked[]` = `[{surface, type, score, reasons[]}]`, high first.

## Output

- `state.surfaces[]` (typed), `state.ranked[]` (scored), noise-drop counts in `state.log[]`.
- A short human summary: "N live → M after funnel; types: a api / b graphql / c webapp / d
  infra; top 3: …". This is what the checkpoint shows.

Hand off to `surface-router`.
