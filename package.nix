{ lib
, stdenv
, buildDotnetModule
, dotnetCorePackages
, copyDesktopItems
, makeDesktopItem
, makeWrapper
, aria2
, zstd
, steam
, sdl3
, libdecor
, libsecret
, glib
, gnutls
, libunwind
, gst_all_1
, xivlauncher-core-src
, useSteamRun ? true
}:

let
  version = lib.trim (builtins.readFile (xivlauncher-core-src + "/version.txt"));
in
buildDotnetModule rec {
  pname = "xivlauncher-rb";
  inherit version;

  src = xivlauncher-core-src;

  nativeBuildInputs = [
    copyDesktopItems
    makeWrapper
  ];

  buildInputs = with gst_all_1; [
    gstreamer
    gst-plugins-base
    gst-plugins-good
    gst-plugins-bad
    gst-plugins-ugly
    gst-libav
  ];

  projectFile = "src/XIVLauncher.Core/XIVLauncher.Core.csproj";
  nugetDeps = ./deps.json;

  # Keep this pinned intentionally: XIVLauncher.Core is sensitive to .NET SDK
  # version drift, and upstream currently requires a recent .NET 10 SDK.
  dotnet-sdk = with dotnetCorePackages; sdk_10_0 // {
    inherit (sdk_9_0) packages targetPackages;
  };

  dotnetFlags = [
    "-p:BuildHash=${version}"
    "-p:PublishSingleFile=false"
  ];

  executables = [ "XIVLauncher.Core" ];

  postPatch = ''
    substituteInPlace lib/FFXIVQuickLauncher/src/XIVLauncher.Common/Game/Patch/Acquisition/Aria/AriaPatchAcquisition.cs \
      --replace-fail 'ariaPath = "aria2c"' 'ariaPath = "${aria2}/bin/aria2c"'
  '';

  postInstall = ''
    mkdir -p "$out/share/pixmaps"
    cp src/XIVLauncher.Core/Resources/logo.png "$out/share/pixmaps/xivlauncher-rb.png"
  '';

  postFixup =
    lib.optionalString useSteamRun (
      let
        steam-run =
          (steam.override {
            extraPkgs = pkgs: [ pkgs.libunwind ];
            extraProfile = ''
              unset TZ
            '';
          }).run;
      in
      ''
        substituteInPlace "$out/bin/XIVLauncher.Core" \
          --replace-fail 'exec' 'exec ${steam-run}/bin/steam-run'
      ''
    )
    + ''
    wrapProgram "$out/bin/XIVLauncher.Core" \
      --prefix PATH : "${lib.makeBinPath [ aria2 zstd ]}" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ libunwind ]}" \
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "$GST_PLUGIN_SYSTEM_PATH_1_0"

    makeWrapper "$out/bin/XIVLauncher.Core" "$out/bin/xivlauncher-rb" \
      --prefix PATH : "${lib.makeBinPath [ aria2 zstd ]}" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ libunwind ]}" \
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "$GST_PLUGIN_SYSTEM_PATH_1_0"

    # The aria2 reference can be mangled as UTF-16LE by the .NET publish step,
    # which makes it invisible to Nix's automatic reference scanner.
    mkdir -p "$out/nix-support"
    echo ${aria2} >> "$out/nix-support/depends"
  '';

  runtimeDeps = [
    sdl3
    libdecor
    libsecret
    glib
    gnutls
    libunwind
  ];

  desktopItems = [
    (makeDesktopItem {
      name = "xivlauncher-rb";
      exec = "xivlauncher-rb";
      icon = "xivlauncher-rb";
      desktopName = "XIVLauncher-RB";
      comment = meta.description;
      categories = [ "Game" ];
      startupWMClass = "XIVLauncher.Core";
    })
  ];

  passthru = {
    updateScript = ./scripts/update.sh;
  };

  meta = {
    description = "Custom XIVLauncher-RB launcher for Final Fantasy XIV";
    homepage = "https://github.com/rankynbass/XIVLauncher.Core";
    license = lib.licenses.gpl3Only;
    maintainers = [ ];
    mainProgram = "xivlauncher-rb";
    platforms = [ "x86_64-linux" ];
  };
}
