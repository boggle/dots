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
    enable = lib.mkEnableOption "Enable network CLI tools";

    nmap = lib.mkEnableOption "nmap (network scanner)";
    rclone = lib.mkEnableOption "rclone (cloud sync)";
    doggo = lib.mkEnableOption "doggo (DNS client)";
    xh = lib.mkEnableOption "xh (modern HTTP client)";
    curlie = lib.mkEnableOption "curlie (curl with jq-like output)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = appSet.packages;
    alienPackages.enabledPackages = appSet.alienEnabled;
  };
}
