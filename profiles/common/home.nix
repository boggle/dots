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
  };

  features.network = {
    enable = lib.mkDefault true;
    sshAgent = lib.mkDefault true;
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
  };

  programs.bash = {
    enable = lib.mkDefault true;
  };
}
