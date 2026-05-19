{
  description = "Public Nix building blocks for module option docs and option search sites";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-25_11.url = "github:nixos/nixpkgs/nixos-25.11";
  };

  outputs = { nixpkgs, nixpkgs-25_11, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs25 = nixpkgs-25_11.legacyPackages.${system};

      mkModuleDocs = import ./lib/mkModuleDocs.nix;
      mkOptionSearchSite = import ./lib/mkOptionSearchSite.nix;
      mkSvelteFrontend = import ./lib/mkSvelteFrontend.nix;
      mkOptionsData = import ./lib/mkOptionsData.nix;

      nixosModulesUnstable = import (pkgs.path + "/nixos/modules/module-list.nix");
      nixosModules25 = import (pkgs25.path + "/nixos/modules/module-list.nix");

      docsUnstable = (mkModuleDocs { inherit pkgs; }) {
        modules = nixosModulesUnstable;
        class = "nixos";
      };

      docs25 = (mkModuleDocs { pkgs = pkgs25; }) {
        modules = nixosModules25;
        class = "nixos";
      };

      dataUnstable = (mkOptionsData { inherit pkgs; }) {
        moduleDocs = docsUnstable;
        releaseName = "unstable";
      };

      data25 = (mkOptionsData { inherit pkgs; }) {
        moduleDocs = docs25;
        releaseName = "25.11";
      };
    in
    {
      lib = {
        mkModuleDocs = mkModuleDocs;
        mkOptionSearchSite = mkOptionSearchSite;
        mkNamespaceFilter = import ./lib/mkNamespaceFilter.nix { inherit pkgs; };
        mkSvelteFrontend = mkSvelteFrontend;
        mkOptionsData = mkOptionsData;
      };

      packages.${system} = {
        svelte-frontend =
          (mkSvelteFrontend { inherit pkgs; }) {
            npmDepsHash = "sha256-MiK7O2dV35Ro1shjtrcnRinVS/31yKGTl5Jlfg+Po+M=";
          };

        svelte-frontend-with-data =
          (mkSvelteFrontend { inherit pkgs; }) {
            npmDepsHash = "sha256-MiK7O2dV35Ro1shjtrcnRinVS/31yKGTl5Jlfg+Po+M=";
            optionsData = {
              "25.11" = "${data25}/options-25.11.json";
              unstable = "${dataUnstable}/options-unstable.json";
            };
          };
      };

      formatter.${system} = pkgs.nixfmt;
    };
}
