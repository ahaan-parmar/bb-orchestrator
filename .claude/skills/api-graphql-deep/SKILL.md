---
name: api-graphql-deep
description: Deeper API and GraphQL hunting for bb-orchestrator, beyond the stock hunt-graphql skill — introspection mining, batching/alias abuse, resolver and mass-assignment testing, API versioning/shadow-endpoint discovery, JWT/OAuth edge cases. Use in the hunt phase for api and graphql surfaces. Wire in gqlpwn if available.
---

# api-graphql-deep

The niche-depth layer for API/GraphQL surfaces. Assumes `hunt-graphql`/`hunt-idor`/`hunt-jwt`
provide the base patterns; this goes further where API bugs actually hide.

## GraphQL

1. **Introspection mining** — if introspection is on, pull the full schema and *read it like a
   map*: find mutations that change state, admin-only-looking fields, types that reference
   other users/tenants, deprecated fields still resolving. The schema tells you where the
   authz boundaries should be — then auth-matrix tests whether they hold.
2. **Introspection off** — don't stop. Field suggestion ("did you mean …"), error-based field
   inference, persisted-query enumeration, known-type guessing from client JS.
3. **Batching & aliases** — send batched queries / aliased duplicate fields to bypass
   per-request rate limits and object-level checks; useful for brute-forcing IDs or 2FA/OTP
   where present (only within scope + rate rules).
4. **Resolver injection** — arguments flowing into DB/OS/template → SQLi/NoSQLi/SSTI/cmd via
   resolvers; test each argument, not just top-level params.
5. **Nested/circular queries** — depth/complexity abuse. DoS-adjacent — only if
   `allowed_techniques` permits, and only to the minimum that demonstrates the flaw, never to
   actual degradation.

## REST / JSON APIs

1. **Shadow & version discovery** — `/v1` vs `/v2` vs `/internal`; older versions often skip
   newer authz checks. Diff behavior across versions.
2. **Mass assignment** — add fields the UI never sends (`role`, `is_admin`, `verified`,
   `tenant_id`, `price`) to create/update bodies; see what sticks.
3. **Method & content-type tampering** — `GET`→`PUT`/`PATCH`/`DELETE`, `application/json` vs
   form vs XML (XXE via content-type switch), override headers (`X-HTTP-Method-Override`).
4. **BOLA/BFLA** — object + function level → hand to `auth-matrix` with the endpoint set.
5. **Spec mining** — swagger/openapi/postman collections in JS or on exposed paths enumerate
   the whole API surface, including undocumented endpoints.
6. **SSRF via API params** — url/callback/webhook/image fields; blind SSRF via collaborator.

## JWT / OAuth edges

- `alg:none`, key confusion (RS→HS), weak secret crack, `kid` injection/path traversal,
  expired-but-accepted, missing signature check.
- OAuth: `redirect_uri` validation gaps, state/CSRF on callback, token leakage via referer,
  scope upgrade.

## gqlpwn integration (optional)

If the user's `gqlpwn` is on PATH, use it for the mechanical GraphQL enumeration (schema dump,
batching, field brute) and feed its output back into state. Wire the command here when
confirmed installed:

```
# gqlpwn <endpoint> --schema --batch   →  parse into state.surfaces[].endpoints
```

## Discipline

Every request: scope-guard + rate_limit + forbidden_techniques. A→B method throughout — one
confirmed API bug → replay the pattern across every sibling endpoint and version. Impact-only:
a reachable, demonstrable harm, not a theoretical misconfiguration.

Candidates → `state.findings[]`.
