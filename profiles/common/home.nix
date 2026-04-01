{ lib, ... }:
# Common Profile - Minimal CLI essentials shared across all profiles
# Plain text/CLI focused, no UI or hardware specifics

{
  imports = [
    ../../modules/features/viewer.nix
    ../../modules/features/network.nix
    ../../modules/features/git.nix
    ../../modules/features/dev-tools.nix
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
