---
name: intigriti-report
description: Draft a submission-ready report per validated finding-chain for a bb-orchestrator engagement, shaped for Intigriti (CVSS + impact narrative + clean repro), with H1/Bugcrowd variants. Use in the report phase, after validation. One report per chain, impact-first, evidence redacted.
---

# intigriti-report

Turn validated chains into reports that get paid. One report per `chain_id`, not per bug.
Never auto-submit — write drafts, surface them, the user submits.

## Preconditions

Only validated findings (`status: validated`, demonstrated impact). Hygiene/theoretical were
already dropped in Phase 4. If nothing survived, say so plainly — no padding.

## Report structure (Intigriti)

```markdown
# <Clear, specific title — vuln + asset + impact>

## Summary
2–3 sentences: what the bug is, where, and the concrete impact.

## Severity
- CVSS 3.1 vector + score
- Intigriti severity tier (map, note if program rubric overrides CVSS)
- Business impact in one line (what an attacker attains)

## Affected asset(s)
- Exact in-scope host(s)/endpoint(s). Confirm each is in scope.

## Steps to reproduce
1. Minimal, numbered, copy-pasteable. Clean account(s), no extra access.
2. Include exact requests/responses — REDACTED (no live cookies, tokens, PII).
3. For authz chains: show identity A request → identity B's data returned.

## Proof
- Minimal evidence (redacted screenshots / request-response). Enough to confirm, no more.

## Impact
- The full attack scenario to attacker-attainable harm. "Could" is not impact — show the chain.

## Remediation
- Specific, actionable fix for this class.

## Chain (if applicable)
- A→B→C: how the signal bug and siblings combine into the reported impact.
```

## Platform variants

- **h1** — same shape; HackerOne severity + CVSS; weakness (CWE) field.
- **bugcrowd** — VRT-aware: map to the exact VRT entry; if VRT default under-rates demonstrated
  impact, argue the upgrade in the severity section with the impact evidence (VRT defaults
  auto-downgrade real bugs — pre-empt it).

## Evidence hygiene (enforced)

Before writing any request/response/screenshot into a report: strip session cookies, auth
tokens, API keys, and any real user PII. Use placeholders. A report that leaks a live token or
victim PII is a liability, not proof.

## Quality bar

- Title names the impact, not the class ("Account takeover via …", not "IDOR found").
- Repro works from a clean state with only the access the report claims.
- Severity justified against both CVSS and the program rubric.
- Dedup check vs prior public disclosures before submission (note any overlap).

## Output

Write `engagements/<target>/findings/reports/<chain_id>.md`. List drafts for the user. Stop.
