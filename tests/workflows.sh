#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

update_workflow=".github/workflows/update-upstream.yml"
ci_workflow=".github/workflows/ci.yml"
legacy_merge_workflow=".github/workflows/auto-merge-upstream-update.yml"

test -f "$update_workflow"
test -f "$ci_workflow"
test ! -f "$legacy_merge_workflow"

grep -Fq 'GH_TOKEN: ${{ github.token }}' "$update_workflow"
grep -Fq 'gh pr merge "$pr" --auto --squash --delete-branch' "$update_workflow"
! grep -Rq "UPDATE_BOT_TOKEN" .github README.md

! grep -Fq "push:" "$ci_workflow"
grep -Fq "Allow GitHub Actions to create and approve pull requests" README.md
grep -Fq "Allow auto-merge" README.md
