{ pkgs ? import <nixpkgs> { }
, xivlauncher-core-src ? builtins.fetchGit {
    url = "https://github.com/rankynbass/XIVLauncher.Core.git";
    ref = "refs/tags/rb-v1.4.0.7";
    submodules = true;
  }
}:

pkgs.callPackage ./package.nix { inherit xivlauncher-core-src; }
