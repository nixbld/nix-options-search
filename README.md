# nix-options-search

Reusable Nix building blocks for:

- `lib.mkModuleDocs`
- `lib.mkOptionSearchSite`
- `lib.mkNamespaceFilter`
- `lib.mkSvelteFrontend`
- `lib.mkOptionsData`
- `lib.mkMergeOptionsData`
- examples under `./examples`

## Usage

```nix
{
  inputs.nix-options-search.url = "github:nixbld/nix-options-search";

  outputs = { nixpkgs, nix-options-search, ... }:
  let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    mkModuleDocs = nix-options-search.lib.mkModuleDocs { inherit pkgs; };
    mkOptionSearchSite = nix-options-search.lib.mkOptionSearchSite { inherit pkgs; };
    mkNamespaceFilter = nix-options-search.lib.mkNamespaceFilter;
    docs = mkModuleDocs {
      modules = [ ./module.nix ];
      class = "nixos";
      filterOption = mkNamespaceFilter {
        includeNamespaces = [ "myNamespace" ];
      };
    };
  in {
    packages.x86_64-linux.site = mkOptionSearchSite {
      moduleDocs = docs;
      releaseName = "my-project";
    };
  };
}
```

## Svelte frontend package

This flake now exposes:

- `packages.x86_64-linux.svelte-frontend`
- `packages.x86_64-linux.svelte-frontend-with-data`

And a reusable builder (one JSON per `<source>-<version>` dataset):

```nix
mkSvelteFrontend = nix-options-search.lib.mkSvelteFrontend { inherit pkgs; };
frontend = mkSvelteFrontend {
  npmDepsHash = "sha256-MiK7O2dV35Ro1shjtrcnRinVS/31yKGTl5Jlfg+Po+M=";
  optionsDatasets = [
    { source = "NixOS"; version = "unstable"; path = ./nixos-unstable.json; }
    { source = "NixOS"; version = "25.11"; path = ./nixos-25.11.json; }
    { source = "Home Manager"; version = "unstable"; path = ./home-manager-unstable.json; }
  ];
};
```

The flake also exposes an app to serve the built frontend on port `4445`:

```bash
nix run .#serve-svelte-frontend
```

## Attribution

Frontend design inspired by [search.nixos.org](https://search.nixos.org).
