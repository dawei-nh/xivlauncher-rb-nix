{ pkgs ? import <nixpkgs> { }
, xivlauncher-core-src ? builtins.fetchGit {
    url = "https://github.com/rankynbass/XIVLauncher.Core.git";
    ref = "RB-patched";
    submodules = true;
  }
}:

pkgs.callPackage ./package.nix { inherit xivlauncher-core-src; }
