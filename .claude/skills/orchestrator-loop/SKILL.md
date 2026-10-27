---
name: orchestrator-loop
description: The brain of the bug bounty orchestrator — state machine that sequences phases 0-5, enforces the checkpoint before active testing, and routes each step to the right skill. Loaded by /orchestrate. Use whenever driving a bb-orchestrator engagement.
---

# Orchestrator loop

You are the controller. You do not hunt directly — you decide the next action, enforce
guards, call the right skill or tool, record the result, and loop.

## The loop

```
1. READ   engagements/<target>/state.json
2. DECIDE next action from (phase, checkpoint_cleared, what's incomplete this phase)
3. GUARD  if the action touches a host, run scope-guard first (see scope-guard skill)
4. ACT    run the tool / call the skill / spawn the subagent
5. WRITE  update state.json (+ append to log[]); write findings to findings/
6. LOOP   back to 1, or advance phase when this phase's exit condition is met
```

Re-read `scope.*` at the top of every phase. It is the standing instruction.

## Phase map

### Phase 0 — Scope + mode  (auto)
- Call `scope-parser` with the program brief (ask the user to paste it, or point to a file).
- Confirm `mode` — it decides what counts as a finding. Write it as the first log entry.
- Collect test `identities[]` if the user has any (see auth-matrix). Zero is fine.
- Exit when `scope.in[]` is non-empty and mode is set. If scope text is too vague to parse
  confidently, ask once, then proceed with what's confirmed (rest → `maybe` = blocked).

### Phase 1 — Recon, wide  (auto)
- Spawn a recon subagent (or run inline). Order: subdomain enum (subfinder + crt.sh) →
  dedup → dns resolve (dnsx) → live detection + fingerprint (httpx) → light content/endpoint
  discovery (katana) **only on in-scope live hosts**.
- Every host goes through scope-guard before it's probed.
- Write `assets[]`, `live_hosts[]`. Raw output → `findings/recon/`.
- Exit when live_hosts enumerated.

### Phase 2 — Map, rank, funnel  (auto)
- Call `signal-funnel`: subtract noise (dedupe, drop dead/parked/boilerplate, drop
  known-everyone-already-triaged nuclei low-sev), then classify each surviving surface by
  type (api | graphql | webapp | infra).
- Call `surface-router`: for each surface, attach the hunt classes/skills that apply.
- Rank surfaces by value (auth, payments, admin, graphql, upload, SSO rank high).
- Build `hunt_plan[]`: per ranked surface, the classes to test and which skill handles each.
- Exit → **CHECKPOINT**.

### CHECKPOINT  (human gate)
- Present: ranked surface (top N with reasons), the proposed hunt_plan, anything scope-guard
  blocked, and a note of what active testing will involve.
- STOP. Wait for explicit approval. Only set `checkpoint_cleared = true` on a clear yes.
- The user may edit the plan (drop/add surfaces or classes) before approving.

### Phase 3 — Hunt, deep  (gated — requires checkpoint_cleared)
- Work the hunt_plan top-down. For each surface:
  - Load the routed skill(s). For API/GraphQL, also load `api-graphql-deep`.
  - For authz classes, run `auth-matrix`.
  - Apply **A→B cluster hunting**: confirm a signal bug is real, then test every sibling with
    the same pattern, then try chaining a different class on a sibling. One class at a time.
  - Honor rate_limit and forbidden_techniques on every request.
- Record each candidate to `findings[]` with a `dedup_key` (see dedup below).

### Phase 4 — Validate  (gated)
- For each candidate run the impact gate: is there a full chain to attacker-attainable harm?
  "Could" / theoretical / hygiene-only → mark `status: dropped`. Keep only demonstrated impact
  (bug-bounty mode). In pentest/red-team mode, keep hygiene per that mode's rules.
- Cluster findings into chains (`chain_id`); one report per chain, not per bug.

### Phase 5 — Report  (gated)
- Call `intigriti-report` (or the platform's shape) per chain. Write to `findings/reports/`.
- Surface the drafts to the user. Do not submit anything automatically.

## Dedup

`dedup_key = sha1(normalized_url + vuln_class + param)`. Before adding a finding, check if the
key exists. nuclei + Burp + manual all flagging the same thing = one entry, sources merged in
`evidence_ref[]`. Also cross-check against prior public disclosures when deciding novelty.

## Resuming

On boot, if `state.json` exists, continue from `phase`. If `checkpoint_cleared` is false and
`phase >= 3`, something is wrong — drop back to the checkpoint and re-present.

## When unattended / checkpoint can't be reached

If the user isn't present at the checkpoint, STOP at it. Never auto-clear the checkpoint.
Passive phases may complete; active phases wait. This is the one gate that is never bypassed.
