{ config, lib, pkgs, alien, ... }:

let
  cfg = config.suites.pim-apps;
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
    home.packages = builtins.filter (p: p != null) [
      # All PIM tools with alien support
      (alien.mkEntry cfg.khal "khal" pkgs.khal)
      (alien.mkEntry cfg.todoman "todoman" pkgs.todoman)
      (alien.mkEntry cfg.pimsync "pimsync" pkgs.pimsync)
      (alien.mkEntry cfg.khard "khard" pkgs.khard)
      (alien.mkEntry cfg.taskwarrior "taskwarrior" pkgs.taskwarrior)
      (alien.mkEntry cfg.superproductivity "superproductivity" pkgs.superproductivity)
    ];
    
    # Declare alien packages as enabled
    alienPackages.enabledPackages = 
      (lib.optional cfg.khal "khal") ++
      (lib.optional cfg.todoman "todoman") ++
      (lib.optional cfg.pimsync "pimsync") ++
      (lib.optional cfg.khard "khard") ++
      (lib.optional cfg.taskwarrior "taskwarrior") ++
      (lib.optional cfg.superproductivity "superproductivity");
  };
}
