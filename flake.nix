{
  description = "A custom multi-machine home manager setup";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Known-good nixpkgs revision: quarto 1.8.26 + pandoc 3.1.11.1.
    # Current nixos-unstable ships quarto 1.9.37 which expects pandoc 3.8+,
    # but the pandoc in the same nixpkgs is only 3.7.0.2.
    nixpkgs-quarto-pin.url = "github:nixos/nixpkgs/15f4ee454b1dce334612fa6843b3e05cf546efab";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur.url = "github:nix-community/NUR";
    nixgl = { url = "github:nix-community/nixGL"; inputs.nixpkgs.follows = "nixpkgs"; };
    niri = { url = "github:sodiboo/niri-flake"; inputs.nixpkgs.follows = "nixpkgs"; };
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.noctalia-qs.follows = "noctalia-qs";
    };
    noctalia-qs = { url = "github:noctalia-dev/noctalia-qs"; inputs.nixpkgs.follows = "nixpkgs"; };
    snippets-ls = { url = "github:quantonganh/snippets-ls"; inputs.nixpkgs.follows = "nixpkgs"; };
    bookokrat = { url = "github:bugzmanov/bookokrat"; inputs.nixpkgs.follows = "nixpkgs"; };
    dots-local = { url = "path:../dots-local"; };
  };

  outputs = { self, nixpkgs, nixpkgs-quarto-pin, home-manager, nur, nixgl, niri, noctalia, noctalia-qs, snippets-ls, bookokrat, dots-local, ... } @ inputs:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
        externalOverlay = final: prev: {
           external.snippets-ls = snippets-ls.packages.${prev.stdenv.hostPlatform.system}.snippets-ls;
           external.bookokrat = bookokrat.packages.${prev.stdenv.hostPlatform.system}.default.overrideAttrs (oldAttrs: {
             doCheck = false;
           });
           external.quarkdown = prev.callPackage ./pkgs/quarkdown.nix {};
           # Known-good pairing from pinned nixpkgs: quarto 1.8.26 + pandoc 3.1.11.1
           quarto = inputs.nixpkgs-quarto-pin.legacyPackages.${prev.stdenv.hostPlatform.system}.quarto;
           pandoc = inputs.nixpkgs-quarto-pin.legacyPackages.${prev.stdenv.hostPlatform.system}.pandoc;
         };
      tuning = import ./modules/flake/package-tuning.nix { inherit lib dots-local; };
      
      # Alien package helpers (need to be available early for imports)
      alien = import ./modules/flake/alien-package-specs.nix { 
          inherit lib dots-local; 
      };

      mkProfile = { profileName, optimized ? false, tunePackages ? {} }:
        let
          tuneOverlay = tuning.mkTuneOverlay tunePackages ./modules;
          overlays = [
            nur.overlays.default
            niri.overlays.niri
            noctalia-qs.overlays.default
            externalOverlay
          ]  ++ (lib.optional (tuneOverlay != null) tuneOverlay);
          
          pkgs' = import nixpkgs (if optimized then { 
            localSystem = { inherit system; gcc.arch = "znver5"; gcc.tune = "znver5"; }; 
            config.allowUnfree = true; inherit overlays; 
          } else { 
            config.allowUnfree = true; inherit system overlays; 
          });

          baseModules = [
            { _module.args.pkgs = lib.mkForce pkgs'; }
            noctalia.homeModules.default
            ./modules/core
            ./modules/core/dots-local.nix
            ./modules/core/nix-tools.nix
            ./modules/core/scripts.nix
            ./modules/core/alien-packages.nix
            ./modules/core/tune-support.nix
            ./profiles/${profileName}/home.nix
            {
              home.username = dots-local.username;
              home.homeDirectory = dots-local.homeDirectory;
              programs.bash.enable = true;
              targets.genericLinux.enable = true;
            }
          ];

          # Gutter Eval to capture clean HM bashrc/profile
          gutterEval = home-manager.lib.homeManagerConfiguration {
            pkgs = pkgs';
            modules = baseModules;
            extraSpecialArgs = { inherit inputs pkgs' alien; };
          };

        in
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgs';
          modules = baseModules ++ [
            ./modules/core/nixon.nix
          ];
          extraSpecialArgs = { 
            inherit inputs pkgs' alien; 
            bashrcDerivation = gutterEval.config.home.file.".bashrc".source;
            profileDerivation = gutterEval.config.home.file.".profile".source;
          };
        };

      profileDefinitions = {
        work = { tunePackages = {}; };
        priv = {
          tunePackages = {
            ripgrep.enable = true; fd.enable = true;
            # niri.enable = true;  # Disabled - RUSTFLAGS conflict
            noctalia-qs.enable = true; ghostty.enable = true; tesseract.enable = true;
          };
        };
      };

      allConfigs = lib.concatLists (lib.mapAttrsToList (name: cfg: [
        { name = name; value = mkProfile { profileName = name; optimized = false; tunePackages = cfg.tunePackages; }; }
        { name = "${name}-opt"; value = mkProfile { profileName = name; optimized = true; tunePackages = cfg.tunePackages; }; }
      ]) profileDefinitions);

    in {
      homeConfigurations = builtins.listToAttrs allConfigs;
    };
}
