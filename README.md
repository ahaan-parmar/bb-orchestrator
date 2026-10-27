# bb-orchestrator

A checkpoint-gated orchestrator for authorized web + API bug bounty work, built on Claude Code.

It is **not** another skill bundle. It is the controller layer that sits on top of one:
it reads engagement state, decides the next action by phase and surface type, acts, reads
the result, and loops — stopping hard before any active testing until you approve.

Knowledge comes from [claude-bughunter](https://github.com/elementalsouls/Claude-BugHunter)
(install separately, see below). This repo adds the orchestration brain plus a thin
refinement layer: scope enforcement in code, noise subtraction, surface routing,
multi-identity authz testing, deeper API/GraphQL hunting, and Intigriti-shaped reporting.

## The loop

```
read state  →  pick next action (phase + surface)  →  scope-guard check  →  act  →  update state  →  repeat
```

## Phases

| Phase | Name            | Mode        |
|-------|-----------------|-------------|
| 0     | Scope + mode    | auto        |
| 1     | Recon (wide)    | auto        |
| 2     | Map/rank/funnel | auto        |
| —     | **CHECKPOINT**  | you approve |
| 3     | Hunt (deep)     | gated       |
| 4     | Validate        | gated       |
| 5     | Report          | gated       |

Phases 0–2 are passive/safe and run unattended. The orchestrator then stops, shows you the
ranked surface + proposed hunt plan, and waits. Nothing active fires until you say go.

## Install (one step)

```bash
git clone <your-fork-or-this-repo> bb-orchestrator
cd bb-orchestrator
bash scripts/install.sh      # fetches claude-bughunter into .claude/ alongside our skills
```

That's it — one install. The script pulls the claude-bughunter knowledge layer into this
repo's `.claude/` so everything (their 58 hunt-* skills + our 8 orchestrator skills) lives in
one place. Refresh their skills anytime with `bash scripts/install.sh --update`.

Work **from this repo root** (`/orchestrate <target>`) so `engagements/` and the scope-guard
paths resolve.

Tools expected on PATH (Kali): `subfinder httpx katana nuclei dnsx`. Burp + MCP optional.
Anything missing, the orchestrator installs or skips.

claude-bughunter is fetched at install time, not bundled — see `ATTRIBUTION.md`.

## Run

```
/orchestrate <target>
```

## Our skill layer

| Skill              | Does                                                          |
|--------------------|--------------------------------------------------------------|
| orchestrator-loop  | the brain — state machine, phase sequencing, checkpoints     |
| scope-parser       | program scope text → structured scope.md                     |
| scope-guard        | **code-enforced** in/out check before every host is touched  |
| signal-funnel      | subtract noise, branch by surface type                       |
| surface-router     | map each surface → the right hunt skill(s)                   |
| auth-matrix        | multi/single-identity authz + IDOR replay                    |
| api-graphql-deep   | GraphQL/API hunting beyond the stock hunt-graphql            |
| intigriti-report   | Intigriti-format report, one per chain                       |

## Authorization

For assets you own or have written authorization to assess only. scope-guard refuses
anything not explicitly in-scope. Active phases may trip Anthropic's cyber safeguards unless
you are enrolled in the Cyber Verification Program: https://claude.com/form/cyber-use-case
