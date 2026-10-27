---
name: surface-router
description: Maps each classified surface (api/graphql/webapp/infra) to the hunt skills and vuln classes that apply, building the hunt_plan for a bb-orchestrator engagement. Use after signal-funnel, before the checkpoint. Routes to claude-bughunter hunt-* skills plus this repo's auth-matrix and api-graphql-deep.
---

# surface-router

Pick the right pages of the playbook per surface. You don't rewrite the 58 hunt-* classes —
you decide which fire where. Output a `hunt_plan[]` the human approves at the checkpoint.

## Routing table

Classes marked → route to a `claude-bughunter` `hunt-<x>` skill unless noted `[ours]`.

### graphql
- introspection abuse, query batching, alias-based brute force, deep/nested query DoS*,
  field-level authz (BOLA/BFLA), injection through resolvers, info disclosure
- → `hunt-graphql` + **`api-graphql-deep` [ours]** + **`auth-matrix` [ours]** for field authz
- *DoS only if `allowed_techniques` permits and never at damaging volume

### api
- BOLA/IDOR, BFLA (function-level authz), mass assignment, injection (SQLi/NoSQL/cmd),
  SSRF, auth bypass / JWT flaws, rate-limit / business-logic, secrets in responses
- → `hunt-idor`, `hunt-ssrf`, `hunt-sqli`, `hunt-jwt`/`hunt-oauth`, mass-assignment patterns
  + **`auth-matrix` [ours]** for BOLA/BFLA + **`api-graphql-deep` [ours]** for API-specific depth

### webapp
- XSS (reflected/stored/DOM), SQLi, SSTI, CSRF, open-redirect, file upload, XXE,
  path traversal/LFI, CORS, clickjacking-with-impact, business logic
- → `hunt-xss`, `hunt-sqli`, `hunt-ssti`, `hunt-csrf`, `hunt-open-redirect`, `hunt-file-upload`,
  `hunt-xxe`, `hunt-lfi`, `hunt-cors`
- **RBAC/authz** across roles → **`auth-matrix` [ours]**

### infra
- subdomain takeover, exposed panels/dashboards, exposed secrets/env, misconfig,
  CORS, cache poisoning, S3/bucket exposure
- → relevant `hunt-*` / enterprise skills; keep impact-focused (no hygiene-only noise)

## Build the hunt_plan

For each surface in `state.ranked[]` (high→low), emit:

```json
{
  "surface": "api.acme.com/graphql",
  "type": "graphql",
  "score": 9,
  "classes": [
    {"class": "graphql-introspection", "skill": "api-graphql-deep"},
    {"class": "field-authz-bola",      "skill": "auth-matrix"},
    {"class": "resolver-injection",    "skill": "hunt-graphql"}
  ]
}
```

Order classes within a surface by expected payoff and by the **A→B signal method**: lead with
the class most likely to produce a *signal* bug that reveals siblings to chain.

## Guardrails baked into routing

- Drop any class whose technique is in `forbidden_techniques` (e.g. no brute-force module if
  banned; no automated scanning classes if the program bans automation).
- Every surface in the plan has already passed scope-guard (it came from in-scope recon) — but
  the hunt phase re-checks each concrete request anyway.

## Output

Write `state.hunt_plan[]`. This is the object shown at the checkpoint for approval/editing.
Nothing in the plan executes until `checkpoint_cleared = true`.
