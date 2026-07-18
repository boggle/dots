{ config, lib, pkgs, dotsLocal, ... }:

let
  cfg = config.features.git;
in
{
  options.features.git = {
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
