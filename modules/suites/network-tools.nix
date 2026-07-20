{ config, lib, pkgs, alien, ... }:

let
  cfg = config.suites.network-tools;
  coreLib = import ../core/lib.nix { inherit lib; };
  appSet = coreLib.mkAppSet {
    inherit alien;
    apps = {
      nmap = { enable = cfg.nmap; pkg = pkgs.nmap; };
      rclone = { enable = cfg.rclone; pkg = pkgs.rclone; };
      doggo = { enable = cfg.doggo; pkg = pkgs.doggo; };
      xh = { enable = cfg.xh; pkg = pkgs.xh; };
      curlie = { enable = cfg.curlie; pkg = pkgs.curlie; };
    };
  };
in
{
  options.suites.network-tools = {
    enable = coreLib.mkDefaultEnabledOption "Enable network CLI tools";

    nmap = coreLib.mkDefaultDisabledOption "nmap (network scanner)";
    rclone = coreLib.mkDefaultDisabledOption "rclone (cloud sync)";
    doggo = coreLib.mkDefaultEnabledOption "doggo (DNS client)";
    xh = coreLib.mkDefaultEnabledOption "xh (modern HTTP client)";
    curlie = coreLib.mkDefaultDisabledOption "curlie (curl with jq-like output)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = appSet.packages;
    alienPackages.enabledPackages = appSet.alienEnabled;
  };
}
