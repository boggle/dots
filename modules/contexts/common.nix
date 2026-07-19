# Always-imported baseline - minimal CLI essentials shared across every
# context (priv, work, ...). Plain text/CLI focused, no UI or hardware
# specifics. Imported unconditionally by modules/composition.nix.
{ lib, ... }:

{
  imports = [
    ../features/viewer.nix
    ../features/network.nix
    ../suites/network-tools.nix
    ../suites/git-tools.nix
    ../suites/dev-tools.nix
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
  };

  suites.network-tools = {
    enable = lib.mkDefault true;
    nmap = lib.mkDefault false;
    rclone = lib.mkDefault false;
    doggo = lib.mkDefault false;
    xh = lib.mkDefault false;
  };

  # Set defaults for common profile
  suites.git-tools = {
    enable = lib.mkDefault true;
    git = lib.mkDefault true;
    delta = lib.mkDefault true;
  };

  suites.dev-tools = {
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
