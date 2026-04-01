{ config, lib, pkgs, alien, ... }:

let
  cfg = config.suites.pim-apps;
in {
  options.suites.pim-apps = {
    enable = lib.mkEnableOption "Enable PIM (Personal Information Management) tools";
    
    khal = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "khal - calendar CLI";
    };
    
    todoman = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "todoman - todo manager for CalDAV";
    };
    
    pimsync = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "pimsync - sync CalDAV/CardDAV with vdirsyncer";
    };
    
    khard = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "khard - console CardDAV client";
    };
    
    taskwarrior = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Taskwarrior - command line task manager";
    };
    
    superproductivity = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "SuperProductivity - GUI todo app with timeboxing";
    };
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
