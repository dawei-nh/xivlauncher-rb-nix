# xivlauncher-rb-nix

Nix flake packaging for [rankynbass/XIVLauncher.Core](https://github.com/rankynbass/XIVLauncher.Core), also known as XIVLauncher-RB.

The package follows the newest stable upstream `rb-v*` release tag and fetches submodules so the shared `FFXIVQuickLauncher` sources are available during the .NET build.

## Usage

Run directly:

```bash
nix run github:dawei-nh/xivlauncher-rb-nix
```

Install into a profile:

```bash
nix profile install github:dawei-nh/xivlauncher-rb-nix
```

Use from another flake:

```nix
{
  inputs.xivlauncher-rb-nix.url = "github:dawei-nh/xivlauncher-rb-nix";

  outputs = { nixpkgs, xivlauncher-rb-nix, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [ xivlauncher-rb-nix.packages.${system}.default ];
      };
    };
}
```

## Package outputs

- `packages.x86_64-linux.default`
- `packages.x86_64-linux.xivlauncher-rb`
- `packages.x86_64-linux.xivlauncher-core`

The installed executable is `xivlauncher-rb`.

## Development

```bash
nix develop
nix flake lock
nix build .#xivlauncher-rb
```

### Regenerating NuGet dependencies

`buildDotnetModule` needs a checked-in NuGet dependency file. Regenerate the dependency set with:

```bash
nix build .#xivlauncher-rb.fetch-deps
./result deps.json
nix build .#xivlauncher-rb
```

Repeat this whenever upstream changes its NuGet dependency graph.

## Updating upstream

The flake tracks the upstream source as a flake input named `xivlauncher-core-src`. To update it to the newest stable `rb-v*` release tag:

```bash
./scripts/update.sh
```

That script updates the upstream source lock, regenerates NuGet dependencies, and verifies the package build when Nix is available.

### Automated updates

GitHub Actions checks for upstream updates nightly. When a newer stable `rb-v*` release tag is available, the workflow opens or updates an `automation/update-xivlauncher-rb` pull request with refreshed `flake.lock` and `deps.json`.

The update workflow uses `UPDATE_VERIFY=0 ./scripts/update.sh` so it only updates lock files. The pull request CI workflow is the validation gate and runs the package build before GitHub auto-merges the update PR.

For fully automatic update PRs, enable the repository settings named `Allow GitHub Actions to create and approve pull requests` and `Allow auto-merge`. The workflow uses the built-in `GITHUB_TOKEN`; no bot token is required.
