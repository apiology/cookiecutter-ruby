#!/usr/bin/env bash
set -euo pipefail
if (($# == 0)); then
  echo "usage: $0 <repo-dir> ..." >&2
  exit 64
fi
for repo in "$@"; do
  git -C "$repo" fetch origin main
  printf '%s\t%s\n' "$repo" "$(git -C "$repo" rev-parse --short origin/main)"
done
