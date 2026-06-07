#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

config=".github/dependabot.yml"

test -f "$config"
grep -Fq "version: 2" "$config"
grep -Fq "package-ecosystem: github-actions" "$config"
grep -Fq "directory: /" "$config"
grep -Fq "interval: weekly" "$config"
grep -Fq "open-pull-requests-limit: 5" "$config"
