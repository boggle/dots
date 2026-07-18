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
    enable = lib.mkEnableOption "Enable PIM (Personal Information Management) tools";
    
    khal = lib.mkEnableOption "khal - calendar CLI";
    
    todoman = lib.mkEnableOption "todoman - todo manager for CalDAV";
    
    pimsync = lib.mkEnableOption "pimsync - sync CalDAV/CardDAV with vdirsyncer";
    
    khard = lib.mkEnableOption "khard - console CardDAV client";
    
    taskwarrior = lib.mkEnableOption "Taskwarrior - command line task manager";
    
    superproductivity = lib.mkEnableOption "SuperProductivity - GUI todo app with timeboxing";
  };

  config = lib.mkIf cfg.enable {
    home.packages = appSet.packages;

    # Declare alien packages as enabled
    alienPackages.enabledPackages = appSet.alienEnabled;
  };
}
