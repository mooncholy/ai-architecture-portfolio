#!/usr/bin/env bash
# scripts/adr-new "adr name"
set -euo pipefail
dir=adr
title="$*"
slug=$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//;s/-$//')
last=$(ls "$dir" | grep -E '^[0-9]{4}-' | sort | tail -1 | cut -c1-4 || true)
n=$((10#${last:-0} + 1))
file="$dir/$(printf '%04d' "$n")-$slug.md"
sed -e "s|{{NUMBER}}|$n|" -e "s|{{TITLE}}|$title|" -e "s|{{DATE}}|$(date +%F)|" \
    "$dir/templates/template.md" > "$file"
echo "$file"