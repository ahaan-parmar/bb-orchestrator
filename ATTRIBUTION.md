# Attribution

The hunting knowledge layer is **claude-bughunter** by Sachin Sharma (ElementalSoul):
https://github.com/elementalsouls/Claude-BugHunter

- Code (MIT), content/skills (CC BY 4.0).
- `scripts/install.sh` fetches it from the upstream repo at install time into `.vendor/`.
  It is **not** redistributed inside this repo.
- The `hunt-*` skills, their methodology, and payload/pattern libraries referenced by
  `surface-router` are Sachin Sharma / claude-bughunter's work, used under CC BY 4.0.

The orchestrator layer (orchestrator-loop, scope-parser, scope-guard, signal-funnel,
surface-router, auth-matrix, api-graphql-deep, intigriti-report) is original to this repo.
