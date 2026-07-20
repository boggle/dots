{ config, lib, pkgs, alien, ... }:

let
  cfg = config.suites.pim-apps;
  coreLib = import ../core/lib.nix { inherit lib; };
  appSet = coreLib.mkAppSet {
    inherit alien;
    apps = {
      khal = { enable = cfg.khal; pkg = pkgs.khal; };
      todoman = { enable = cfg.todoman; pkg = pkgs.todoman; };
      pimsync = { enable = cfg.pimsync; pkg = pkgs.pimsync; };
      khard = { enable = cfg.khard; pkg = pkgs.khard; };
      taskwarrior = { enable = cfg.taskwarrior; pkg = pkgs.taskwarrior; };
      superproductivity = { enable = cfg.superproductivity; pkg = pkgs.superproductivity; };
    };
  };
in {
  options.suites.pim-apps = {
    enable = coreLib.mkDefaultDisabledOption "Enable PIM (Personal Information Management) tools";
    
    khal = coreLib.mkDefaultDisabledOption "khal - calendar CLI";
    
    todoman = coreLib.mkDefaultDisabledOption "todoman - todo manager for CalDAV";
    
    pimsync = coreLib.mkDefaultDisabledOption "pimsync - sync CalDAV/CardDAV with vdirsyncer";
    
    khard = coreLib.mkDefaultDisabledOption "khard - console CardDAV client";
    
    taskwarrior = coreLib.mkDefaultDisabledOption "Taskwarrior - command line task manager";
    
    superproductivity = coreLib.mkDefaultDisabledOption "SuperProductivity - GUI todo app with timeboxing";
  };

  config = lib.mkIf cfg.enable {
    home.packages = appSet.packages;

    # Declare alien packages as enabled
    alienPackages.enabledPackages = appSet.alienEnabled;
  };
}
