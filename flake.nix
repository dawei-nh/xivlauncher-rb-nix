{
  description = "Nix flake for XIVLauncher-RB (rankynbass/XIVLauncher.Core)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    xivlauncher-core-src = {
      url = "git+https://github.com/rankynbass/XIVLauncher.Core.git?ref=refs/tags/rb-v1.4.0.7&submodules=1";
      flake = false;
    };
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , xivlauncher-core-src
    }:
    let
      overlay = final: prev: {
        xivlauncher-rb = final.callPackage ./package.nix {
          inherit xivlauncher-core-src;
        };

        xivlauncher-core = final.xivlauncher-rb;
      };
    in
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfreePredicate = pkg:
            builtins.elem (nixpkgs.lib.getName pkg) [
              "steam"
              "steam-original"
              "steam-run"
              "steam-runtime"
              "steam-unwrapped"
            ];
          overlays = [ overlay ];
        };
      in
      {
        packages = {
          default = pkgs.xivlauncher-rb;
          xivlauncher-rb = pkgs.xivlauncher-rb;
          xivlauncher-core = pkgs.xivlauncher-core;
        };

        apps = {
          default = flake-utils.lib.mkApp { drv = pkgs.xivlauncher-rb; };
          xivlauncher-rb = flake-utils.lib.mkApp { drv = pkgs.xivlauncher-rb; };
          xivlauncher-core = flake-utils.lib.mkApp { drv = pkgs.xivlauncher-core; };
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            gh
            jq
            nixfmt-rfc-style
            dotnetCorePackages.sdk_10_0
          ];
        };
      })
    // {
      overlays.default = overlay;
    };
}
