# state.json schema

The orchestrator's single source of truth. Read at the start of every loop iteration,
written after every action. One per engagement, at `engagements/<target>/state.json`.

| Field | Type | Meaning |
|-------|------|---------|
| `target` | str | root target, e.g. `acme.com` |
| `created` | ISO8601 | engagement start |
| `mode` | enum | `bug-bounty` \| `pentest` \| `red-team` — decides what counts as a finding |
| `platform` | str | `intigriti` \| `h1` \| `bugcrowd` \| `private` — report shape |
| `phase` | int | 0–5, current phase |
| `checkpoint_cleared` | bool | has the human approved the hunt plan — gates phases 3+ |
| `scope.in[]` | str[] | hosts/patterns explicitly in-scope |
| `scope.out[]` | str[] | explicitly out-of-scope |
| `scope.maybe[]` | str[] | ambiguous — **treated as BLOCKED** until resolved |
| `scope.wildcards[]` | str[] | e.g. `*.acme.com`; matched literally, never widened |
| `scope.rate_limit` | str\|null | program's stated rate, honored by throttle |
| `scope.allowed_techniques[]` | str[] | e.g. `automated-scanning` if explicitly permitted |
| `scope.forbidden_techniques[]` | str[] | e.g. `brute-force`, `dos`, `social-engineering` |
| `scope.account_rules` | str\|null | caps / alias-tagging rules for test accounts |
| `scope.safe_harbor` | str\|null | disclosure terms note |
| `identities[]` | obj[] | test accounts: `{label, role, token_ref}` — token stored out-of-band, never raw here |
| `assets[]` | str[] | all discovered subdomains/hosts |
| `live_hosts[]` | obj[] | `{host, status, tech[], title}` from httpx |
| `surfaces[]` | obj[] | `{host, type: api\|graphql\|webapp\|infra, endpoints[]}` |
| `ranked[]` | obj[] | post-funnel: `{surface, score, reasons[]}` high→low |
| `hunt_plan[]` | obj[] | proposed per-surface classes to test — shown at checkpoint |
| `findings[]` | obj[] | `{dedup_key, chain_id, class, surface, status, impact, evidence_ref}` |
| `log[]` | obj[] | `{ts, phase, action, result}` audit trail incl. every scope-guard BLOCK |

**Secrets rule:** tokens/cookies for test identities are never written raw into state.json.
Store them in `engagements/<target>/.secrets` (gitignored); state holds only `token_ref`.
