{ config, lib, pkgs, inputs, alien, ... }:

let
  cfg = config.suites.cloud-tools;
  coreLib = import ../core/lib.nix { inherit lib; };
  appSet = coreLib.mkAppSet {
    inherit alien;
    apps = {
      github = { enable = cfg.github; pkg = pkgs.gh; alienName = "gh"; };
      azure = { enable = cfg.azure; pkg = pkgs.azure-cli; alienName = "azure-cli"; };
      lazydocker = { enable = cfg.lazydocker; pkg = pkgs.lazydocker; };
      # Moved from suites.network-tools - rclone is a cloud-storage sync
      # tool, a better fit here.
      rclone = { enable = cfg.rclone; pkg = pkgs.rclone; };
    };
  };
in
{
  options.suites.cloud-tools = {
    enable = coreLib.mkDefaultDisabledOption "Enable cloud CLI tools";

    github = coreLib.mkDefaultEnabledOption "GitHub CLI (gh)";
    azure = coreLib.mkDefaultDisabledOption "Azure CLI";
    lazydocker = coreLib.mkDefaultDisabledOption "lazydocker (TUI Docker client)";
    rclone = coreLib.mkDefaultDisabledOption "rclone (cloud sync)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = appSet.packages;

    # Declare which alien packages are enabled
    alienPackages.enabledPackages = appSet.alienEnabled;
  };
}
