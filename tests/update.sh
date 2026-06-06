#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/bin"

cat > "$tmpdir/bin/git" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

if [[ "$*" != "ls-remote --tags --refs https://github.com/rankynbass/XIVLauncher.Core.git refs/tags/rb-v*" ]]; then
  printf 'unexpected git args: %s\n' "$*" >&2
  exit 1
fi

cat <<'TAGS'
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa	refs/tags/rb-v1.4.0.7
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb	refs/tags/rb-v1.4.0.8-beta1
cccccccccccccccccccccccccccccccccccccccc	refs/tags/rb-v1.4.0.8
dddddddddddddddddddddddddddddddddddddddd	refs/tags/rb-v1.4.0.9-rc1
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee	refs/tags/rb-v1.4.0.10
TAGS
SCRIPT

cat > "$tmpdir/bin/nix" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$*" >> "$NIX_CALLS"

case "$*" in
  "flake lock --override-input xivlauncher-core-src git+https://github.com/rankynbass/XIVLauncher.Core.git?ref=refs/tags/rb-v1.4.0.10&submodules=1") ;;
  "build .#xivlauncher-rb.fetch-deps")
    cat > result <<'RESULT'
#!/usr/bin/env bash
set -euo pipefail
printf '[]\n' > "$1"
RESULT
    chmod +x result
    ;;
  "build .#xivlauncher-rb") ;;
  "flake check") ;;
  *)
    printf 'unexpected nix args: %s\n' "$*" >&2
    exit 1
    ;;
esac
SCRIPT

chmod +x "$tmpdir/bin/git" "$tmpdir/bin/nix"

export PATH="$tmpdir/bin:$PATH"
export NIX_CALLS="$tmpdir/nix-calls"

cd "$tmpdir"
"$repo_root/scripts/update.sh"

expected='flake lock --override-input xivlauncher-core-src git+https://github.com/rankynbass/XIVLauncher.Core.git?ref=refs/tags/rb-v1.4.0.10&submodules=1
build .#xivlauncher-rb.fetch-deps
build .#xivlauncher-rb
flake check'

actual="$(cat "$NIX_CALLS")"
if [[ "$actual" != "$expected" ]]; then
  printf 'unexpected nix calls:\n%s\n' "$actual" >&2
  exit 1
fi

: > "$NIX_CALLS"
UPDATE_VERIFY=0 "$repo_root/scripts/update.sh"

expected_without_verify='flake lock --override-input xivlauncher-core-src git+https://github.com/rankynbass/XIVLauncher.Core.git?ref=refs/tags/rb-v1.4.0.10&submodules=1
build .#xivlauncher-rb.fetch-deps'

actual="$(cat "$NIX_CALLS")"
if [[ "$actual" != "$expected_without_verify" ]]; then
  printf 'unexpected nix calls without verification:\n%s\n' "$actual" >&2
  exit 1
fi
