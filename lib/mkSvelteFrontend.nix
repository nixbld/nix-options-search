{ pkgs, lib ? pkgs.lib }:
{
  src ? ../svelte-frontend,
  optionsDatasets ? [ ],
  basePath ? "/",
  pname ? "nix-options-search-frontend",
  version ? "0.1.0",
  npmDepsHash,
}:
let
  datasetEntries = map (d: d // {
    file = "${lib.toLower (builtins.replaceStrings [" "] ["-"] d.source)}-${d.version}.json";
  }) optionsDatasets;

  uiConfig = pkgs.writeText "${pname}-ui-config.json" (builtins.toJSON {
    datasets = map (d: {
      inherit (d) source version file;
    }) datasetEntries;
  });

  preparedSrc = pkgs.runCommand "${pname}-src" {} ''
    cp -r ${src} $out
    chmod -R u+w $out
    mkdir -p $out/public/data
    cp ${uiConfig} $out/public/data/ui-config.json
    ${lib.concatStringsSep "\n" (map (d: "cp ${d.path} $out/public/data/${d.file}") datasetEntries)}
  '';
in
pkgs.buildNpmPackage {
  inherit pname version npmDepsHash;
  src = preparedSrc;

  VITE_BASE = basePath;
  npmBuildScript = "build";

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r dist/* $out/
    runHook postInstall
  '';
}
