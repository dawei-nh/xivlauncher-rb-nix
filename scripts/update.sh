#!/usr/bin/env bash
set -euo pipefail

readonly UPSTREAM_INPUT="xivlauncher-core-src"
readonly UPSTREAM_REPO="https://github.com/rankynbass/XIVLauncher.Core.git"
readonly PACKAGE="xivlauncher-rb"

log() {
  printf '[update] %s\n' "$*"
}

require() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'error: required command not found: %s\n' "$1" >&2
    exit 1
  fi
}

latest_release_tag() {
  git ls-remote --tags --refs "${UPSTREAM_REPO}" 'refs/tags/rb-v*' \
    | sed -n 's#.*refs/tags/\(rb-v[0-9][0-9.]*\)$#\1#p' \
    | sort -V \
    | tail -n 1
}

main() {
  require nix
  require git

  local tag
  tag="$(latest_release_tag)"
  if [[ -z "${tag}" ]]; then
    printf 'error: no stable rb-v release tags found in %s\n' "${UPSTREAM_REPO}" >&2
    exit 1
  fi

  log "locking ${UPSTREAM_INPUT} to upstream release ${tag}"
  nix flake lock --override-input "${UPSTREAM_INPUT}" "git+${UPSTREAM_REPO}?ref=refs/tags/${tag}&submodules=1"

  log "regenerating NuGet dependency lock"
  nix build ".#${PACKAGE}.fetch-deps"
  ./result deps.json
  rm -f result

  log "building ${PACKAGE}"
  nix build ".#${PACKAGE}"

  log "checking flake"
  nix flake check

  log "done"
}

main "$@"
