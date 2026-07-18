# Always-imported baseline - minimal CLI essentials shared across every
# context (priv, work, ...). Plain text/CLI focused, no UI or hardware
# specifics. Ported from profiles/common/home.nix (Phase 2 - see
# memory-bank/architecture.md section 2); content unchanged, only the
# location moved (now imported unconditionally by modules/composition.nix
# rather than via a profile-directory chain).
{ lib, ... }:

{
  imports = [
    ../features/viewer.nix
    ../features/network.nix
    ../features/git.nix
    ../features/dev-tools.nix
  ];

  features.tune = {
    enable = lib.mkDefault true;
  };

  features.viewer = {
    enable = lib.mkDefault true;
    alias = lib.mkDefault "v";
    ripgrepAll = lib.mkDefault false;
  };

  features.network = {
    enable = lib.mkDefault true;
    sshAgent = lib.mkDefault true;
    nmap = lib.mkDefault false;
    rclone = lib.mkDefault false;
    doggo = lib.mkDefault false;
    xh = lib.mkDefault false;
  };

  # Set defaults for common profile
  features.git = {
    enable = lib.mkDefault true;
    git = lib.mkDefault true;
    delta = lib.mkDefault true;
  };

  features.dev-tools = {
    enable = lib.mkDefault true;
    nixd = lib.mkDefault true;
    entr = lib.mkDefault true;
    uv = lib.mkDefault false;
    marksman = lib.mkDefault false;
    snippetsLs = lib.mkDefault false;
  };

  programs.bash = {
    enable = lib.mkDefault true;
  };
}
