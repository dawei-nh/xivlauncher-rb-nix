# xivlauncher-rb-nix

Nix flake packaging for [rankynbass/XIVLauncher.Core](https://github.com/rankynbass/XIVLauncher.Core), also known as XIVLauncher-RB.

The package follows the newest stable upstream `rb-v*` release tag and fetches submodules so the shared `FFXIVQuickLauncher` sources are available during the .NET build.

## Usage

The package installs the `xivlauncher-rb` executable and the `XIVLauncher-RB`
desktop entry. The launcher itself runs through Nixpkgs' `steam-run` FHS
runtime, matching the upstream Nixpkgs `xivlauncher` package.

Run directly for quick testing:

```bash
nix run github:dawei-nh/xivlauncher-rb-nix
```

Install into a profile:

```bash
nix profile install github:dawei-nh/xivlauncher-rb-nix
```

Install on NixOS from another flake:

```nix
{
  inputs.xivlauncher-rb-nix.url = "github:dawei-nh/xivlauncher-rb-nix";

  outputs = { nixpkgs, xivlauncher-rb-nix, ... }:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.hostname = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ({ ... }: {
            environment.systemPackages = [
              xivlauncher-rb-nix.packages.${system}.default
            ];
          })
        ];
      };
    };
}
```

Install with Home Manager:

```nix
{
  home.packages = [
    xivlauncher-rb-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
```

If you use the overlay with your own `pkgs` import, allow Steam's runtime
packages because the `steam-run` wrapper depends on unfree Steam components:

```nix
{ lib, ... }: {
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "steam"
      "steam-original"
      "steam-run"
      "steam-runtime"
      "steam-unwrapped"
    ];
}
```

Then add the overlay package normally:

```nix
{
  nixpkgs.overlays = [
    xivlauncher-rb-nix.overlays.default
  ];

  environment.systemPackages = [
    pkgs.xivlauncher-rb
  ];
}
```

### Runtime notes

The flake's package outputs import Nixpkgs with a narrow unfree predicate for
the Steam runtime names required by `steam-run`. If you consume
`packages.${system}.default` directly, no additional `allowUnfree` setting is
needed for this package. If you use the overlay with your own `pkgs`, your own
Nixpkgs import controls unfree evaluation, so add the predicate shown above.

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
