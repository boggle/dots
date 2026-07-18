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
    };
  };
in
{
  options.suites.cloud-tools = {
    enable = lib.mkEnableOption "Enable cloud CLI tools";

    github = lib.mkEnableOption "GitHub CLI (gh)";
    azure = lib.mkEnableOption "Azure CLI";
    lazydocker = lib.mkEnableOption "lazydocker (TUI Docker client)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = appSet.packages;

    # Declare which alien packages are enabled
    alienPackages.enabledPackages = appSet.alienEnabled;
  };
}
