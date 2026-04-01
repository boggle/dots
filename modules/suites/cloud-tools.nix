{ config, lib, pkgs, inputs, alien, ... }:

let
  cfg = config.suites.cloud-tools;
in
{
  options.suites.cloud-tools = {
    enable = lib.mkEnableOption "Enable cloud CLI tools";

    github = lib.mkEnableOption "GitHub CLI (gh)";
    azure = lib.mkEnableOption "Azure CLI";
    lazydocker = lib.mkEnableOption "lazydocker (TUI Docker client)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = builtins.filter (p: p != null) [
      (alien.mkEntry cfg.github "gh" pkgs.gh)
      (alien.mkEntry cfg.azure "azure-cli" pkgs.azure-cli)
      (alien.mkEntry cfg.lazydocker "lazydocker" pkgs.lazydocker)
    ];

    # Declare which alien packages are enabled
    alienPackages.enabledPackages = 
      (lib.optional cfg.github "gh") ++
      (lib.optional cfg.azure "azure-cli") ++
      (lib.optional cfg.lazydocker "lazydocker");
  };
}
