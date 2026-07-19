{ config, lib, pkgs, alien, dotsLocal, ... }:

let
  cfg = config.suites.git-tools;
  coreLib = import ../core/lib.nix { inherit lib; };
  # `delta` is deliberately NOT in this appSet - `programs.delta.enable`
  # below already adds its package unconditionally (its `package` option
  # isn't nullable, unlike lazygit's), so listing it again here would
  # just re-duplicate it (same pattern already fixed for
  # lsd/zoxide/fzf/bat/direnv in modules/core/default.nix - see its
  # comment for the general rule).
  #
  # `lazygit` and `gh` DO have real alien specs (owned by
  # tui-apps.cachyos-packages.nix and cloud-tools.cachyos-packages.nix
  # respectively, since those suites also offer their own toggle for the
  # same tool) - routing them through `mkAppSet` here (rather than a
  # plain, non-alien-aware package list, as this file did before) makes
  # this suite correctly avoid re-installing them via Nix whenever
  # `suites.tui-apps.lazygit`/`suites.cloud-tools.github` already have
  # them alien-managed, instead of silently double/triple-installing the
  # same tool via pacman *and* two independent Nix code paths (a real,
  # confirmed-live bug on chromaden before this fix).
  appSet = coreLib.mkAppSet {
    inherit alien;
    apps = {
      jj = { enable = cfg.jj; pkg = pkgs.jj; };
      jjui = { enable = cfg.jj; pkg = pkgs.jjui; };
      lazygit = { enable = cfg.lazygit; pkg = pkgs.lazygit; };
      gh = { enable = cfg.gh; pkg = pkgs.gh; };
      gh-dash = { enable = cfg.gh-dash; pkg = pkgs.gh-dash; };
      gitCredentialManager = { enable = cfg.gitCredentialManager; pkg = pkgs.git-credential-manager; alienName = "git-credential-manager"; };
    };
  };
in
{
  options.suites.git-tools = {
    enable = lib.mkEnableOption "Enable Git tools";

    # Core
    git = lib.mkEnableOption "Git";
    jj = lib.mkEnableOption "jj (Git alternative)";
    
    # Tools
    delta = lib.mkEnableOption "delta (Git pager)";
    lazygit = lib.mkEnableOption "lazygit (TUI Git client)";
    gh = lib.mkEnableOption "gh (GitHub CLI)" // { default = true; };
    gh-dash = lib.mkEnableOption "gh-dash (GitHub dashboard)" // { default = true; };
    gitCredentialManager = lib.mkEnableOption "Git Credential Manager";
  };

  config = lib.mkIf cfg.enable {
    home.packages = appSet.packages;
    alienPackages.enabledPackages = appSet.alienEnabled;

    programs.git = lib.mkIf cfg.git {
      enable = true;
      signing.format = null;
      settings = {
        user = {
          name = dotsLocal.realname;
          email = dotsLocal.realmail;
        };
        # `git difft` runs a one-off diff through difftastic's structural
        # diff instead of the normal unified diff - scoped to this alias
        # only (via `-c diff.external=difft`) rather than setting
        # `diff.external` globally, so it doesn't interfere with delta's
        # pager integration (programs.delta.enableGitIntegration below),
        # which expects to receive plain unified-diff output. difftastic
        # itself (the `difft` binary) is installed unconditionally in
        # modules/core/default.nix.
        alias = {
          difft = "-c diff.external=difft diff";
        };
      };
    };

    programs.delta = lib.mkIf cfg.delta {
      enable = true;
      enableGitIntegration = true;
      options = {
        navigate = true;
        line-numbers = true;
        side-by-side = true;
      };
    };
  };
}
