{ config, lib, pkgs, dotsLocal, ... }:

let
  cfg = config.suites.git-tools;
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
    home.packages = with pkgs; builtins.filter (x: x != null) [
      (lib.mkIf cfg.jj jj)
      (lib.mkIf cfg.jj jjui)
      (lib.mkIf cfg.delta delta)
      (lib.mkIf cfg.lazygit lazygit)
      (lib.mkIf cfg.gh gh)
      (lib.mkIf cfg.gh-dash gh-dash)
      (lib.mkIf cfg.gitCredentialManager git-credential-manager)
    ];

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
