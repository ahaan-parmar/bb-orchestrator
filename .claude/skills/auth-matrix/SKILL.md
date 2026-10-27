---
name: auth-matrix
description: Multi- and single-identity authorization testing for bb-orchestrator — replays ranked endpoints across available test identities to find BOLA/IDOR, BFLA/function-level authz, privilege escalation, and missing-auth. Use in the hunt phase for any authz/RBAC class. Degrades gracefully from 2 accounts to 1 to 0; honors program account rules.
---

# auth-matrix

Authz bugs are a **state** problem, not a knowledge one: you need the same requests sent as
different identities and the responses compared. This skill holds the identities and runs the
replay. It's the highest-paying, least-automated class — and the reason the orchestrator holds
session state at all.

## Identities (Phase 0 input)

`state.identities[] = [{label, role, token_ref}]`. Tokens/cookies live in
`engagements/<target>/.secrets` (gitignored); state holds only the ref.

Reality of managed programs: the in-app account is often bound to your platform alias email,
so you may only have **one**. The skill scales to what you have:

| Identities | What it runs |
|-----------:|--------------|
| **2+** | full horizontal (A↔B same role) + vertical (low→high) authz; cleanest PoC |
| **1**  | authenticated-vs-no-auth replay; IDOR via object-ID swap (your IDs ±/guessed); param/role tampering in your own requests; forced browsing to privileged paths as a normal user |
| **0**  | pre-auth only: endpoints that should require auth but don't |

On any 1-account finding, flag `needs_second_identity: true` and note that a program-provided
or collaborator second account would turn it into a clean two-user PoC. Ask the program for a
second test account when the brief allows it.

## The replay

1. Build the request set from `hunt_plan` surfaces: each endpoint + method + your legitimately
   obtained object IDs.
2. For each endpoint, send it as **each identity** (and as no-auth). scope-guard checks every
   request. Honor `rate_limit`.
3. Compare responses:
   - **BOLA/IDOR** — identity X receives data belonging to identity Y (or to an object ID that
     isn't X's). 200 + other user's data = signal.
   - **BFLA** — low-priv identity successfully invokes a high-priv function (admin action,
     another tenant's mutation).
   - **Privilege escalation** — role/tenant parameter tampering changes what you can reach.
   - **Missing auth** — no-auth request succeeds on an endpoint that requires a session.
4. Minimize impact: read-only confirmation, your own/controlled objects, no bulk pulls of real
   user data. Capture the minimal diff as evidence.

## A→B cluster hunting (apply here)

A confirmed IDOR on one endpoint is a *signal*: immediately test every sibling endpoint with
the same object-reference pattern. One real BOLA usually means the authz layer is weak across
a whole controller — that's the chain, and it's one report, not ten.

## GraphQL field-level authz

For graphql surfaces: run each query/mutation as each identity; a field or mutation resolving
for an identity that shouldn't see it is field-level BOLA/BFLA. Pair with `api-graphql-deep`.

## Account-rule compliance

Creating test accounts obeys `state.scope.account_rules`: respect caps, tag accounts with the
required researcher alias, don't exceed the allowed number. If rules forbid extra accounts,
stay single-identity.

## Output

Candidates → `state.findings[]` with `class` (bola/bfla/privesc/missing-auth), the identity
pair that proved it, minimal evidence ref, and `needs_second_identity` where relevant.
