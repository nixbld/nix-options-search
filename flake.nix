{
  description = "Public Nix building blocks for module option docs and option search sites";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-25_11.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-26_05.url = "github:nixos/nixpkgs/nixos-26.05";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager-25_11.url = "github:nix-community/home-manager/release-25.11";
    home-manager-26_05.url = "github:nix-community/home-manager/release-26.05";
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ethereumNix = {
      url = "github:nix-community/ethereum.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    microvmNix = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agentspace = {
      url = "github:shazow/agentspace";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gitHooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-25_11, nixpkgs-26_05, home-manager, home-manager-25_11, home-manager-26_05, impermanence, ethereumNix, nixvim, microvmNix, agentspace, gitHooks, devenv, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs25 = nixpkgs-25_11.legacyPackages.${system};
      pkgs26 = nixpkgs-26_05.legacyPackages.${system};

      mkModuleDocs = import ./lib/mkModuleDocs.nix;
      mkOptionSearchSite = import ./lib/mkOptionSearchSite.nix;
      mkNamespaceFilter = import ./lib/mkNamespaceFilter.nix { inherit pkgs; };
      mkSvelteFrontend = import ./lib/mkSvelteFrontend.nix;
      mkOptionsData = import ./lib/mkOptionsData.nix;
      mkMergeOptionsData = import ./lib/mkMergeOptionsData.nix;

      mkGitHubDeclarationPrefixes = specs:
        builtins.listToAttrs (map (spec: {
          name = "file://${builtins.unsafeDiscardStringContext spec.input.outPath}/";
          value = "https://github.com/${spec.repo}/blob/${spec.rev or spec.input.sourceInfo.rev or "main"}/";
        }) specs);

      commonDeclarationPrefixes = {
        "file://${builtins.unsafeDiscardStringContext self.outPath}/" = "https://github.com/nixbld/nix-options-search/blob/main/";
      };

      nixosModulesUnstable = import (pkgs.path + "/nixos/modules/module-list.nix");
      nixosModules25 = import (pkgs25.path + "/nixos/modules/module-list.nix");
      nixosModules26 = import (pkgs26.path + "/nixos/modules/module-list.nix");

      docsNixosUnstable = (mkModuleDocs { inherit pkgs; }) {
        modules = nixosModulesUnstable;
        class = "nixos";
      };

      docsNixos25 = (mkModuleDocs { pkgs = pkgs25; }) {
        modules = nixosModules25;
        class = "nixos";
      };

      docsNixos26 = (mkModuleDocs { pkgs = pkgs26; }) {
        modules = nixosModules26;
        class = "nixos";
      };

      homeManagerOptionsUnstable = "${home-manager.packages.${system}.docs-json}/share/doc/home-manager/options.json";
      homeManagerOptions25 = "${home-manager-25_11.packages.${system}.docs-json}/share/doc/home-manager/options.json";
      homeManagerOptions26 = "${home-manager-26_05.packages.${system}.docs-json}/share/doc/home-manager/options.json";

      docsImpermanenceUnstable = (mkModuleDocs { inherit pkgs; }) {
        modules = [ impermanence.nixosModules.impermanence ];
        class = "nixos";
        # Impermanence reuses the NixOS module system, so filter to its own option tree.
        filterOption = mkNamespaceFilter {
          includeNamespaces = [
            [ "environment" "persistence" ]
            [ "home" "persistence" ]
          ];
        };
      };

      docsEthereumNixUnstable = (mkModuleDocs { inherit pkgs; }) {
        modules = [ ethereumNix.nixosModules.default ];
        class = "nixos";
        # ethereum.nix ships many NixOS modules; keep only the ethereum.* subtree.
        filterOption = mkNamespaceFilter {
          includeNamespaces = [ [ "services" "ethereum" ] ];
        };
      };

      docsNixvimUnstable = (mkModuleDocs { inherit pkgs; }) {
        modules = [ nixvim.nixosModules.nixvim ];
        class = "nixos";
        # nixvim exposes a shared programs.nixvim subtree; use the packaged options.json.
        filterOption = mkNamespaceFilter {
          includeNamespaces = [ [ "programs" "nixvim" ] ];
          excludeExactNamespaces = [ [ "programs" "nixvim" ] ];
        };
      };

      docsMicrovmNixUnstable = (mkModuleDocs { inherit pkgs; }) {
        modules = [ microvmNix.nixosModules.microvm ];
        class = "nixos";
        # microvm.nix options live under the microvm.* namespace.
        filterOption = mkNamespaceFilter {
          includeNamespaces = [ [ "microvm" ] ];
        };
      };

      docsAgentSpaceUnstable = (mkModuleDocs { inherit pkgs; }) {
        modules = [
          agentspace.inputs.microvm.nixosModules.microvm
          agentspace.inputs.home-manager.nixosModules.home-manager
          agentspace.nixosModules.default
        ];
        class = "nixos";
        filterOption = path: _:
          builtins.length path > 0 && builtins.head path == "agentspace";
      };

      dataNixosUnstable = (mkOptionsData { inherit pkgs; }) {
        moduleDocs = docsNixosUnstable;
        releaseName = "unstable";
        sourceName = "NixOS";
        declarationUrlPrefixes = commonDeclarationPrefixes // mkGitHubDeclarationPrefixes [
          { input = nixpkgs; repo = "NixOS/nixpkgs"; }
        ];
      };

      dataNixos25 = (mkOptionsData { inherit pkgs; }) {
        moduleDocs = docsNixos25;
        releaseName = "25.11";
        sourceName = "NixOS";
        declarationUrlPrefixes = commonDeclarationPrefixes // mkGitHubDeclarationPrefixes [
          { input = nixpkgs-25_11; repo = "NixOS/nixpkgs"; }
        ];
      };

      dataNixos26 = (mkOptionsData { inherit pkgs; }) {
        moduleDocs = docsNixos26;
        releaseName = "26.05";
        sourceName = "NixOS";
        declarationUrlPrefixes = commonDeclarationPrefixes // mkGitHubDeclarationPrefixes [
          { input = nixpkgs-26_05; repo = "NixOS/nixpkgs"; }
        ];
      };

      dataHomeManagerUnstable = (mkOptionsData { inherit pkgs; }) {
        optionsJSONFile = homeManagerOptionsUnstable;
        releaseName = "unstable";
        sourceName = "Home Manager";
        declarationUrlPrefixes = commonDeclarationPrefixes // mkGitHubDeclarationPrefixes [
          { input = home-manager; repo = "nix-community/home-manager"; }
          { input = home-manager.inputs.nixpkgs; repo = "NixOS/nixpkgs"; }
        ];
      };

      dataHomeManager25 = (mkOptionsData { inherit pkgs; }) {
        optionsJSONFile = homeManagerOptions25;
        releaseName = "25.11";
        sourceName = "Home Manager";
        declarationUrlPrefixes = commonDeclarationPrefixes // mkGitHubDeclarationPrefixes [
          { input = home-manager-25_11; repo = "nix-community/home-manager"; }
          { input = home-manager-25_11.inputs.nixpkgs; repo = "NixOS/nixpkgs"; }
        ];
      };

      dataHomeManager26 = (mkOptionsData { inherit pkgs; }) {
        optionsJSONFile = homeManagerOptions26;
        releaseName = "26.05";
        sourceName = "Home Manager";
        declarationUrlPrefixes = commonDeclarationPrefixes // mkGitHubDeclarationPrefixes [
          { input = home-manager-26_05; repo = "nix-community/home-manager"; }
          { input = home-manager-26_05.inputs.nixpkgs; repo = "NixOS/nixpkgs"; }
        ];
      };

      dataImpermanenceUnstable = (mkOptionsData { inherit pkgs; }) {
        moduleDocs = docsImpermanenceUnstable;
        releaseName = "unstable";
        sourceName = "Impermanence";
        declarationUrlPrefixes = commonDeclarationPrefixes // mkGitHubDeclarationPrefixes [
          { input = impermanence; repo = "nix-community/impermanence"; }
        ];
      };

      dataMicrovmNixUnstable = (mkOptionsData { inherit pkgs; }) {
        moduleDocs = docsMicrovmNixUnstable;
        releaseName = "unstable";
        sourceName = "microvm.nix";
        declarationUrlPrefixes = commonDeclarationPrefixes // mkGitHubDeclarationPrefixes [
          { input = microvmNix; repo = "microvm-nix/microvm.nix"; }
        ];
      };

      dataEthereumNixUnstable = (mkOptionsData { inherit pkgs; }) {
        moduleDocs = docsEthereumNixUnstable;
        releaseName = "unstable";
        sourceName = "ethereum.nix";
        declarationUrlPrefixes = commonDeclarationPrefixes // mkGitHubDeclarationPrefixes [
          { input = ethereumNix; repo = "nix-community/ethereum.nix"; }
        ];
      };

      dataNixvimUnstable = (mkOptionsData { inherit pkgs; }) {
        optionsJSONFile = "${nixvim.packages.${system}.options-json}/share/doc/nixos/options.json";
        releaseName = "unstable";
        sourceName = "Nixvim";
        declarationUrlPrefixes = commonDeclarationPrefixes // mkGitHubDeclarationPrefixes [
          { input = nixvim; repo = "nix-community/nixvim"; }
        ];
      };

      dataAgentSpaceUnstable = (mkOptionsData { inherit pkgs; }) {
        moduleDocs = docsAgentSpaceUnstable;
        releaseName = "unstable";
        sourceName = "AgentSpace";
        declarationUrlPrefixes = commonDeclarationPrefixes // mkGitHubDeclarationPrefixes [
          { input = agentspace; repo = "shazow/agentspace"; }
          { input = agentspace.inputs.microvm; repo = "microvm-nix/microvm.nix"; }
          { input = agentspace.inputs.home-manager; repo = "nix-community/home-manager"; }
        ];
        declarationUrlOverrides = {
          "https://github.com/nixbld/nix-options-search/blob/main/lib/mkModuleDocs.nix" = "https://github.com/shazow/agentspace/blob/${agentspace.sourceInfo.rev}/sandbox-qemu.nix";
          "https://github.com/microvm-nix/microvm.nix/blob/${agentspace.inputs.microvm.sourceInfo.rev}/nixos-modules/microvm/options.nix" = "https://github.com/shazow/agentspace/blob/${agentspace.sourceInfo.rev}/sandbox-qemu.nix";
        };
      };

      docsDevenvUnstable = (mkModuleDocs { inherit pkgs; }) {
        modules = [ (devenv.modules + /top-level.nix) ];
        class = "devenv";
        specialArgs = {
          self = devenv;
          inputs = { "git-hooks" = gitHooks; };
        };
      };

      dataDevenvUnstable = (mkOptionsData { inherit pkgs; }) {
        moduleDocs = docsDevenvUnstable;
        releaseName = "unstable";
        sourceName = "devenv";
        declarationUrlPrefixes = commonDeclarationPrefixes // mkGitHubDeclarationPrefixes [
          { input = devenv; repo = "cachix/devenv"; }
          { input = gitHooks; repo = "cachix/git-hooks.nix"; }
        ];
      };

      svelteFrontend = (mkSvelteFrontend { inherit pkgs; }) {
        npmDepsHash = "sha256-MiK7O2dV35Ro1shjtrcnRinVS/31yKGTl5Jlfg+Po+M=";
        basePath = "/";
        optionsDatasets = [ ];
      };

      svelteFrontendWithData = (mkSvelteFrontend { inherit pkgs; }) {
        npmDepsHash = "sha256-MiK7O2dV35Ro1shjtrcnRinVS/31yKGTl5Jlfg+Po+M=";
        basePath = "/";
        optionsDatasets = [
          { source = "NixOS"; version = "unstable"; path = "${dataNixosUnstable}/options-unstable.json"; }
          { source = "NixOS"; version = "25.11"; path = "${dataNixos25}/options-25.11.json"; }
          { source = "NixOS"; version = "26.05"; path = "${dataNixos26}/options-26.05.json"; }
          { source = "Home Manager"; version = "unstable"; path = "${dataHomeManagerUnstable}/options-unstable.json"; }
          { source = "Home Manager"; version = "25.11"; path = "${dataHomeManager25}/options-25.11.json"; }
          { source = "Home Manager"; version = "26.05"; path = "${dataHomeManager26}/options-26.05.json"; }
          { source = "Impermanence"; version = "unstable"; path = "${dataImpermanenceUnstable}/options-unstable.json"; }
          { source = "microvm.nix"; version = "unstable"; path = "${dataMicrovmNixUnstable}/options-unstable.json"; }
          { source = "ethereum.nix"; version = "unstable"; path = "${dataEthereumNixUnstable}/options-unstable.json"; }
          { source = "Nixvim"; version = "unstable"; path = "${dataNixvimUnstable}/options-unstable.json"; }
          { source = "AgentSpace"; version = "unstable"; path = "${dataAgentSpaceUnstable}/options-unstable.json"; }
          { source = "devenv"; version = "unstable"; path = "${dataDevenvUnstable}/options-unstable.json"; }
        ];
      };

      svelteFrontendWithDataPages = (mkSvelteFrontend { inherit pkgs; }) {
        npmDepsHash = "sha256-MiK7O2dV35Ro1shjtrcnRinVS/31yKGTl5Jlfg+Po+M=";
        basePath = "/nix-options-search/";
        optionsDatasets = [
          { source = "NixOS"; version = "unstable"; path = "${dataNixosUnstable}/options-unstable.json"; }
          { source = "NixOS"; version = "25.11"; path = "${dataNixos25}/options-25.11.json"; }
          { source = "NixOS"; version = "26.05"; path = "${dataNixos26}/options-26.05.json"; }
          { source = "Home Manager"; version = "unstable"; path = "${dataHomeManagerUnstable}/options-unstable.json"; }
          { source = "Home Manager"; version = "25.11"; path = "${dataHomeManager25}/options-25.11.json"; }
          { source = "Home Manager"; version = "26.05"; path = "${dataHomeManager26}/options-26.05.json"; }
          { source = "Impermanence"; version = "unstable"; path = "${dataImpermanenceUnstable}/options-unstable.json"; }
          { source = "microvm.nix"; version = "unstable"; path = "${dataMicrovmNixUnstable}/options-unstable.json"; }
          { source = "ethereum.nix"; version = "unstable"; path = "${dataEthereumNixUnstable}/options-unstable.json"; }
          { source = "Nixvim"; version = "unstable"; path = "${dataNixvimUnstable}/options-unstable.json"; }
          { source = "AgentSpace"; version = "unstable"; path = "${dataAgentSpaceUnstable}/options-unstable.json"; }
          { source = "devenv"; version = "unstable"; path = "${dataDevenvUnstable}/options-unstable.json"; }
        ];
      };

      serveSvelteFrontend = pkgs.writeShellApplication {
        name = "serve-svelte-frontend";
        runtimeInputs = [ pkgs.static-web-server ];
        text = ''
          exec static-web-server --root ${svelteFrontendWithData} --port 4445
        '';
      };
    in
    {
      lib = {
        mkModuleDocs = mkModuleDocs;
        mkOptionSearchSite = mkOptionSearchSite;
        mkNamespaceFilter = mkNamespaceFilter;
        mkSvelteFrontend = mkSvelteFrontend;
        mkOptionsData = mkOptionsData;
        mkMergeOptionsData = mkMergeOptionsData;
      };

      packages.${system} = {
        svelte-frontend = svelteFrontend;
        svelte-frontend-with-data = svelteFrontendWithData;
        svelte-frontend-with-data-pages = svelteFrontendWithDataPages;
        serve-svelte-frontend = serveSvelteFrontend;
      };

      apps.${system}.serve-svelte-frontend = {
        type = "app";
        program = "${serveSvelteFrontend}/bin/serve-svelte-frontend";
      };

      formatter.${system} = pkgs.nixfmt;
    };
}
