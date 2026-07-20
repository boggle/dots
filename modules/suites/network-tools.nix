{ config, lib, pkgs, alien, ... }:

let
  cfg = config.suites.network-tools;
  coreLib = import ../core/lib.nix { inherit lib; };
  appSet = coreLib.mkAppSet {
    inherit alien;
    apps = {
      nmap = { enable = cfg.nmap; pkg = pkgs.nmap; };
      doggo = { enable = cfg.doggo; pkg = pkgs.doggo; };
      xh = { enable = cfg.xh; pkg = pkgs.xh; };
      curlie = { enable = cfg.curlie; pkg = pkgs.curlie; };
      # Moved from suites.tui-apps - both are network-monitoring tools
      # that belong here rather than in the general TUI-app grab-bag.
      bandwhich = { enable = cfg.bandwhich; pkg = pkgs.bandwhich; };
      gping = { enable = cfg.gping; pkg = pkgs.gping; };
    };
  };
in
{
  options.suites.network-tools = {
    enable = coreLib.mkDefaultEnabledOption "Enable network CLI tools";

    nmap = coreLib.mkDefaultEnabledOption "nmap (network scanner)";
    doggo = coreLib.mkDefaultEnabledOption "doggo (DNS client)";
    xh = coreLib.mkDefaultEnabledOption "xh (modern HTTP client)";
    curlie = coreLib.mkDefaultDisabledOption "curlie (curl with jq-like output)";
    bandwhich = coreLib.mkDefaultDisabledOption "bandwhich - network monitor";
    gping = coreLib.mkDefaultEnabledOption "gping (ping with graph)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = appSet.packages;
    alienPackages.enabledPackages = appSet.alienEnabled;
  };
}
