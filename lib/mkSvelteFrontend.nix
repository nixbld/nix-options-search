{ pkgs, lib ? pkgs.lib }:
{
  src ? ../svelte-frontend,
  optionsData ? {
    "25.11" = null;
    "unstable" = null;
  },
  pname ? "nix-options-search-frontend",
  version ? "0.1.0",
  npmDepsHash,
}:
let
  dataFiles = lib.mapAttrsToList (ver: path:
    if path == null then null else {
      name = "options-${ver}.json";
      value = path;
    }
  ) optionsData;

  preparedSrc = pkgs.runCommand "${pname}-src" {} ''
    cp -r ${src} $out
    chmod -R u+w $out
    mkdir -p $out/public/data
    ${lib.concatStringsSep "\n" (lib.filter (s: s != "") (map (entry:
      if entry == null then "" else "cp ${entry.value} $out/public/data/${entry.name}"
    ) dataFiles))}
  '';
in
pkgs.buildNpmPackage {
  inherit pname version npmDepsHash;
  src = preparedSrc;

  npmBuildScript = "build";

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r dist/* $out/
    runHook postInstall
  '';
}
