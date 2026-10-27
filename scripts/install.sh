#!/usr/bin/env bash
# bb-orchestrator installer — pulls the claude-bughunter knowledge layer into THIS repo's
# .claude/ so it's one install, one place. Our orchestrator skills sit alongside their
# hunt-* skills; the surface-router references them by name.
#
# Usage:
#   bash scripts/install.sh            # first install / add bughunter skills
#   bash scripts/install.sh --update   # re-pull latest bughunter skills
#
# claude-bughunter is CC-BY-4.0 (content) / MIT (code) by Sachin Sharma.
# This script fetches it at install time (not redistributed here). Attribution: see ATTRIBUTION.md.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENDOR_DIR="$REPO_ROOT/.vendor/claude-bughunter"
SKILLS_DST="$REPO_ROOT/.claude/skills"
CMDS_DST="$REPO_ROOT/.claude/commands"
UPSTREAM="https://github.com/elementalsouls/Claude-BugHunter.git"

command -v git >/dev/null || { echo "git is required"; exit 1; }

echo "[*] bb-orchestrator installer"
echo "    repo: $REPO_ROOT"

# 1. fetch / update claude-bughunter
if [ -d "$VENDOR_DIR/.git" ]; then
  if [ "${1:-}" = "--update" ]; then
    echo "[*] updating claude-bughunter ..."
    git -C "$VENDOR_DIR" pull --ff-only
  else
    echo "[*] claude-bughunter already fetched (use --update to refresh)"
  fi
else
  echo "[*] fetching claude-bughunter ..."
  git clone --depth 1 "$UPSTREAM" "$VENDOR_DIR"
fi

# 2. copy their skills + commands into our .claude (by name, so router refs resolve)
echo "[*] linking knowledge layer into .claude/ ..."
mkdir -p "$SKILLS_DST" "$CMDS_DST"

copied_skills=0
if [ -d "$VENDOR_DIR/skills" ]; then
  for d in "$VENDOR_DIR"/skills/*/; do
    [ -d "$d" ] || continue
    name="$(basename "$d")"
    # never overwrite OUR skills with an upstream one of the same name
    if [ -d "$REPO_ROOT/.claude/skills/$name" ] && [ ! -e "$SKILLS_DST/$name/.from-bughunter" ]; then
      if [ "$name" = "orchestrator-loop" ] || [ "$name" = "scope-parser" ] || \
         [ "$name" = "scope-guard" ] || [ "$name" = "signal-funnel" ] || \
         [ "$name" = "surface-router" ] || [ "$name" = "auth-matrix" ] || \
         [ "$name" = "api-graphql-deep" ] || [ "$name" = "intigriti-report" ]; then
        echo "    skip (ours): $name"
        continue
      fi
    fi
    rm -rf "${SKILLS_DST:?}/$name"
    cp -r "$d" "$SKILLS_DST/$name"
    touch "$SKILLS_DST/$name/.from-bughunter"
    copied_skills=$((copied_skills+1))
  done
fi

copied_cmds=0
if [ -d "$VENDOR_DIR/commands" ]; then
  for f in "$VENDOR_DIR"/commands/*.md; do
    [ -f "$f" ] || continue
    base="$(basename "$f")"
    [ "$base" = "orchestrate.md" ] && { echo "    skip (ours): orchestrate.md"; continue; }
    cp "$f" "$CMDS_DST/$base"
    copied_cmds=$((copied_cmds+1))
  done
fi

echo "[+] done: $copied_skills bughunter skills + $copied_cmds commands linked"
echo "[+] your orchestrator skills: orchestrator-loop, scope-parser, scope-guard,"
echo "    signal-funnel, surface-router, auth-matrix, api-graphql-deep, intigriti-report"
echo
echo "    Run from this repo root so engagements/ and scope-guard paths resolve:"
echo "      /orchestrate <target>"
