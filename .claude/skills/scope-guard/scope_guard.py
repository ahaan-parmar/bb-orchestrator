#!/usr/bin/env python3
"""
scope-guard: the code-enforced in/out check. Run BEFORE any tool touches any host.

Exit code 0 = ALLOW, 1 = BLOCK. Prints a one-line verdict + reason.
Conservative: out wins, maybe is blocked, unknown is blocked. Wildcards cover subdomains
of the listed apex only and are never widened to siblings/partners.

Usage:
    python3 scope_guard.py --state engagements/acme.com/state.json --host api.acme.com
    python3 scope_guard.py --state <state.json> --url https://api.acme.com/graphql
    echo -e "a.acme.com\\nb.evil.com" | python3 scope_guard.py --state <state.json> --stdin

Filtering a list (keep only allowed, one per line):
    python3 scope_guard.py --state <state.json> --stdin --filter
"""
import argparse
import json
import sys
from urllib.parse import urlparse


def host_of(target: str) -> str:
    t = target.strip()
    if "://" in t:
        t = urlparse(t).hostname or ""
    else:
        t = t.split("/")[0].split(":")[0]
    return t.lower().rstrip(".")


def matches_wildcard(host: str, pattern: str) -> bool:
    # "*.acme.com" matches foo.acme.com and foo.bar.acme.com, NOT acme.com itself,
    # NOT acme.com.evil.com, NOT acme-partner.com.
    p = pattern.lower().lstrip(".")
    if p.startswith("*."):
        base = p[2:]
        return host == base or host.endswith("." + base)  # apex+subs if listed as *.x
    return host == p


def exact_or_sub(host: str, entry: str) -> bool:
    e = entry.lower().rstrip(".")
    if e.startswith("*."):
        return matches_wildcard(host, e)
    # exact host, or a subdomain of an explicitly listed domain
    return host == e or host.endswith("." + e)


def verdict(host: str, scope: dict):
    if not host:
        return False, "empty/unparseable host"
    # 1. OUT always wins
    for o in scope.get("out", []):
        if exact_or_sub(host, o):
            return False, f"explicitly out-of-scope (matches {o})"
    # 2. MAYBE is blocked until resolved
    for m in scope.get("maybe", []):
        if exact_or_sub(host, m):
            return False, f"ambiguous/maybe — blocked until confirmed (matches {m})"
    # 3. explicit IN
    for i in scope.get("in", []):
        if exact_or_sub(host, i):
            return True, f"in-scope (matches {i})"
    # 4. wildcard IN
    for w in scope.get("wildcards", []):
        if matches_wildcard(host, w):
            return True, f"in-scope via wildcard ({w})"
    # 5. unknown → blocked
    return False, "not in any in-scope list — blocked by default"


def load_scope(state_path: str) -> dict:
    with open(state_path) as f:
        return json.load(f).get("scope", {})


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--state", required=True)
    ap.add_argument("--host")
    ap.add_argument("--url")
    ap.add_argument("--stdin", action="store_true")
    ap.add_argument("--filter", action="store_true",
                    help="with --stdin: print only allowed hosts, suppress verdicts")
    args = ap.parse_args()
    scope = load_scope(args.state)

    targets = []
    if args.host:
        targets.append(args.host)
    if args.url:
        targets.append(args.url)
    if args.stdin:
        targets.extend(line for line in sys.stdin.read().splitlines() if line.strip())

    if not targets:
        print("no target given", file=sys.stderr)
        sys.exit(2)

    any_block = False
    for t in targets:
        h = host_of(t)
        allowed, reason = verdict(h, scope)
        if args.filter:
            if allowed:
                print(h)
            else:
                any_block = True
            continue
        tag = "ALLOW" if allowed else "BLOCK"
        print(f"{tag}  {h}  — {reason}")
        if not allowed:
            any_block = True

    sys.exit(1 if any_block else 0)


if __name__ == "__main__":
    main()
