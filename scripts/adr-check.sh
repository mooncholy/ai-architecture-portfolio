#!/usr/bin/env bash
# Fails if an ADR is missing a required section or still has TODO / {{ }} placeholders.
set -uo pipefail
required=("## Status" "## Context" "## Considered options" "## Trade-offs" "## Decision" "## Consequences" "## Revisit when")
fail=0
for f in adr/[0-9][0-9][0-9][0-9]-*.md; do
  [ -e "$f" ] || continue
  for h in "${required[@]}"; do
    grep -qiF -- "$h" "$f" || { echo "$f: missing section '$h'"; fail=1; }
  done
  grep -nE 'TODO|\{\{' "$f" | sed "s|^|$f:|" && fail=1
done
[ $fail -eq 0 ] && echo "ADRs OK"
exit $fail