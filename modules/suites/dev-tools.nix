{ config, lib, pkgs, alien, ... }:

let
  cfg = config.suites.dev-tools;
  coreLib = import ../core/lib.nix { inherit lib; };
  # Only the alien-managed subset (marksman/mkcert/caddy) - everything else
  # in this feature is a plain, always-Nix-installed package with no alien
  # counterpart, so it stays as a hand-written lib.mkIf list below.
  appSet = coreLib.mkAppSet {
    inherit alien;
    apps = {
      marksman = { enable = cfg.marksman; pkg = pkgs.marksman; };
      mkcert = { enable = cfg.mkcert; pkg = pkgs.mkcert; };
      caddy = { enable = cfg.caddy; pkg = pkgs.caddy; };
    };
  };
in
{
  options.suites.dev-tools = {
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

    # Web development tools
    mkcert = lib.mkEnableOption "mkcert (locally-trusted development certificates)";
    caddy = lib.mkEnableOption "caddy (modern web server with automatic HTTPS)";

    # Document/Publishing tools
    quarto = lib.mkEnableOption "quarto (scientific/technical publishing)";
    typst = lib.mkEnableOption "typst (modern markup-based typesetting)";
    pandoc = lib.mkEnableOption "pandoc (universal document converter)";

    # Other tools
    egglog = lib.mkEnableOption "egglog (e-graph toolkit)";
    steel = lib.mkEnableOption "steel (Scheme interpreter)";
    prettier = lib.mkEnableOption "prettier (code formatter)";
  };

  config = lib.mkIf cfg.enable {
    # Nix tooling
    home.packages = (with pkgs; builtins.filter (p: p != null) [
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
      (lib.mkIf cfg.snippetsLs external.snippets-ls)
      (lib.mkIf cfg.haskell ghc)
      (lib.mkIf cfg.haskell cabal-install)
      (lib.mkIf cfg.haskell stack)
      (lib.mkIf cfg.entr entr)
      (lib.mkIf cfg.quarto quarto)
      (lib.mkIf cfg.typst typst)
      (lib.mkIf cfg.pandoc pkgs.pandoc)
      (lib.mkIf cfg.egglog egglog)
      (lib.mkIf cfg.steel steel)
      (lib.mkIf cfg.prettier prettier)
    ]) ++ appSet.packages;

    alienPackages.enabledPackages = appSet.alienEnabled;

    # nixd config
    # NOTE: uses config.home.homeDirectory (resolved from dotsLocal in
    # flake.nix) and assumes `dots` is checked out directly in
    # $HOME/dots (matches DOTS_DIR's own default in scripts.nix) - not
    # fully general if someone uses a custom DOTS_DIR.
    home.file.".nixd.json" = lib.mkIf cfg.nixd {
      text = builtins.toJSON {
        options = {
          home-manager = {
            # `default` is the real flake output name (see flake.nix) -
            # homeConfigurations has never been keyed by username in this
            # repo (it went priv/work -> default/default-opt across the
            # re-architecture, never username-based) - this was a stale
            # reference that predates even that split, confirmed via
            # `git log -p` showing it unchanged since the file's first
            # version. nixd's option-completion was likely never working
            # correctly before this fix.
            expr = "(builtins.getFlake \"${config.home.homeDirectory}/dots\").homeConfigurations.default.options";
          };
        };
        
        nixpkgs = {
          expr = "import (builtins.getFlake \"${config.home.homeDirectory}/dots\").inputs.nixpkgs { }";
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
