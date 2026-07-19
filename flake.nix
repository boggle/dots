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

      # Formal, typed dots-local schema. Evaluates the raw dots-local flake
      # output against modules/dots-local/schema.nix, giving every field a
      # documented default. `dotsLocal` (the evaluated config) is passed to
      # all Home Manager modules via extraSpecialArgs below, alongside (not
      # instead of) `inputs`, since some non-dots-local inputs (niri,
      # noctalia, nixgl, ...) are still read directly.
      # `dots-local` (the flake input) carries flake-introspection metadata
      # alongside its actual data fields (_type, inputs, outPath, outputs,
      # rev, sourceInfo, ...) - these must be stripped before handing it to
      # evalModules, which otherwise tries to validate them as declared
      # options and fails ("The option `_type' does not exist").
      dotsLocalData = builtins.removeAttrs dots-local [
        "_type" "inputs" "lastModified" "lastModifiedDate" "narHash"
        "outPath" "outputs" "rev" "revCount" "shortRev" "sourceInfo"
        "submodules" "dirtyRev" "dirtyShortRev"
      ];

      dotsLocalEval = lib.evalModules {
        # Wrapped as `{ config = dotsLocalData; }` (rather than passed
        # bare) to make the intent explicit to evalModules: these are
        # config values, not a module function.
        modules = [ ./modules/dots-local/schema.nix { config = dotsLocalData; } ];
      };
      dotsLocal = dotsLocalEval.config;

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
      tuning = import ./modules/flake/package-tuning.nix { inherit lib dotsLocal; };
      
      # Alien package helpers (need to be available early for imports)
      alien = import ./modules/flake/alien-package-specs.nix { 
          inherit lib dotsLocal; 
      };

      # Global-scope tuning packages, keyed by dotsLocal.profile - the same
      # value that modules/composition.nix uses to pick a
      # contexts/<profile>.nix bundle. Add an entry here if a new context
      # needs specific global-scope tuning.
      tunePackagesByContext = {
        priv = {
          ripgrep.enable = true; fd.enable = true;
          # niri.enable = true;  # Disabled - RUSTFLAGS conflict
          noctalia-qs.enable = true; ghostty.enable = true; tesseract.enable = true;
        };
        work = {};
      };
      tunePackages = tunePackagesByContext.${dotsLocal.profile} or {};

      # Just an optimized/baseline build-perf axis - everything
      # context-specific is resolved internally from dotsLocal by
      # modules/composition.nix itself.
      mkHomeConfig = { optimized ? false }:
        let
          tuneOverlay = tuning.mkTuneOverlay tunePackages ./modules;
          overlays = [
            nur.overlays.default
            niri.overlays.niri
            noctalia-qs.overlays.default
            externalOverlay
          ]  ++ (lib.optional (tuneOverlay != null) tuneOverlay)
             ++ dotsLocal.extraOverlays;
          
          pkgs' = import nixpkgs (if optimized then { 
            # Parametrized from dotsLocal.march, so the -opt build targets
            # this machine's actual configured architecture.
            localSystem = { inherit system; gcc.arch = dotsLocal.march; gcc.tune = dotsLocal.march; }; 
            config.allowUnfree = true; inherit overlays; 
          } else { 
            config.allowUnfree = true; inherit system overlays; 
          });

          baseModules = [
            { _module.args.pkgs = lib.mkForce pkgs'; }
            noctalia.homeModules.default
            ./modules/composition.nix
            {
              home.username = dotsLocal.username;
              home.homeDirectory = dotsLocal.homeDirectory;
              programs.bash.enable = true;
              targets.genericLinux.enable = true;
            }
          ] ++ dotsLocal.extraModules;

          # Gutter Eval to capture clean HM bashrc/profile
          gutterEval = home-manager.lib.homeManagerConfiguration {
            pkgs = pkgs';
            modules = baseModules;
            extraSpecialArgs = { inherit inputs pkgs' alien dotsLocal; };
          };

        in
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgs';
          modules = baseModules ++ [
            ./modules/core/nixon.nix
          ];
          extraSpecialArgs = { 
            inherit inputs pkgs' alien dotsLocal; 
            bashrcDerivation = gutterEval.config.home.file.".bashrc".source;
            profileDerivation = gutterEval.config.home.file.".profile".source;
          };
        };

    in {
      # There's no "profile choice" to make on the command line - it's
      # fully determined by whatever dots-local.flake.nix's `profile` (and
      # other axis fields) say. `apply-dots` (no argument) / `apply-dots
      # opt` select baseline vs. optimized.
      homeConfigurations = {
        default = mkHomeConfig { optimized = false; };
        default-opt = mkHomeConfig { optimized = true; };
      };

      # Exposes the fully-resolved dots-local schema (all defaults filled
      # in) for introspection/debugging, e.g.:
      #   nix eval .#dotsLocal --override-input dots-local git+file://$HOME/dots-local
      #   nix eval .#dotsLocal.march --override-input dots-local git+file://$HOME/dots-local
      dotsLocal = dotsLocal;
    };
}
