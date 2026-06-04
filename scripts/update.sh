#!/usr/bin/env bash
set -euo pipefail

readonly UPSTREAM_INPUT="xivlauncher-core-src"
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

main() {
  require nix

  log "updating ${UPSTREAM_INPUT} in flake.lock"
  nix flake lock --update-input "${UPSTREAM_INPUT}"

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
