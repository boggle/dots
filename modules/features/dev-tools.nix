{ config, lib, pkgs, inputs, alien, ... }:

let
  local = inputs.dots-local;
  cfg = config.features.dev-tools;
in
{
  options.features.dev-tools = {
    enable = lib.mkEnableOption "Enable dev tools";

    # Nix tooling
    nixd = lib.mkEnableOption "nixd (Nix language server)";

    # Rust tooling
    rust = lib.mkEnableOption "Rust toolchain (mold, clang, sccache)";
    
    # Python tooling
    python= lib.mkEnableOption "Python toolchain";

    # General tooling
    uv = lib.mkEnableOption "uv (Python package/project manager)";
    marksman = lib.mkEnableOption "marksman (Markdown language server)";
    snippetsLs = lib.mkEnableOption "snippets-ls (snippet language server)";

    # JSON tooling
    json = lib.mkEnableOption "JSON toolchain";

    # XML tooling
    xml = lib.mkEnableOption "XML toolchain";

    # Haskell tooling
    haskell = lib.mkEnableOption "Haskell toolchain (ghc, cabal, stack)";
    
    # HMR tooling
    entr = lib.mkEnableOption "entr (file watcher for auto-rebuilds)";
    
    # Other tools
    egglog = lib.mkEnableOption "egglog (e-graph toolkit)";
    steel = lib.mkEnableOption "steel (Scheme interpreter)";
  };

  config = lib.mkIf cfg.enable {
    # Nix tooling
    home.packages = with pkgs; builtins.filter (p: p != null) [
      (lib.mkIf cfg.nixd nixd)
      (lib.mkIf cfg.nixd alejandra)
      (lib.mkIf cfg.rust mold)
      (lib.mkIf cfg.rust clang)
      (lib.mkIf cfg.rust sccache)
      (lib.mkIf cfg.rust rust-analyzer)
      (lib.mkIf cfg.json vscode-json-languageserver)
      (lib.mkIf cfg.python basedpyright)
      (lib.mkIf cfg.python ruff)
      (lib.mkIf cfg.uv uv)
      (lib.mkIf cfg.xml lemminx)
      (alien.mkEntry cfg.marksman "marksman" marksman)
      (lib.mkIf cfg.snippetsLs external.snippets-ls)
      (lib.mkIf cfg.haskell ghc)
      (lib.mkIf cfg.haskell cabal-install)
      (lib.mkIf cfg.haskell stack)
      (lib.mkIf cfg.entr entr)
      (lib.mkIf cfg.egglog egglog)
      (lib.mkIf cfg.steel steel)
    ];

    alienPackages.enabledPackages =
      (lib.optional cfg.marksman "marksman");

    # nixd config
    home.file.".nixd.json" = lib.mkIf cfg.nixd {
      text = builtins.toJSON {
        options = {
          home-manager = {
            expr = "(builtins.getFlake \"/home/${local.username}/dots\").homeConfigurations.\"${local.username}\".options";
          };
        };
        
        nixpkgs = {
          expr = "import (builtins.getFlake \"/home/${local.username}/dots\").inputs.nixpkgs { }";
        };

        formatting = {
          command = [ "alejandra" ];
        };
      };
    };

    # Rust config
    programs.cargo = lib.mkIf cfg.rust {
      enable = true;
      settings = {
        target."x86_64-unknown-linux-gnu" = {
          linker = "${pkgs.clang}/bin/clang";
          rustflags = ["-C" "link-arg=-fuse-ld=${pkgs.mold}/bin/mold"];
        };
      };
    };

    home.sessionVariables = lib.mkIf cfg.rust {
      RUSTC_WRAPPER = "${pkgs.sccache}/bin/sccache";
    };
  };
}
