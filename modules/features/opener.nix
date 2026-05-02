{ config, lib, pkgs, alien, ... }:

let
  cfg = config.features.opener;
  backend = cfg.backend;

  # Platform-specific open commands
  openCmd = {
    wayland = "${pkgs.xdg-utils}/bin/xdg-open";
    x11     = "${pkgs.xdg-utils}/bin/xdg-open";
    wsl     = "wslview";  # From wslu package
    macos   = "open";
  }.${backend};

in
{
  options.features.opener = {
    enable = lib.mkEnableOption "Cross-platform file opener feature";
    
    backend = lib.mkOption {
      type = lib.types.enum [ "wayland" "x11" "wsl" "macos" ];
      description = "Desktop environment backend to use for opening opener.";
    };
    
    alias = lib.mkOption {
      type = lib.types.str;
      default = "o";
      description = "Alias name for the open command (default: 'o').";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = builtins.filter (p: p != null) (
      (lib.optionals (backend == "wayland" || backend == "x11") [ pkgs.xdg-utils ])
      ++ [ (alien.mkEntry (backend == "wsl") "wslu" null) ]
    );

    alienPackages.enabledPackages = lib.optional (backend == "wsl") "wslu";

    programs.bash.shellAliases = {
      ${cfg.alias} = openCmd;
    };
    
    # Also set XDG_OPEN_CMD for other tools that might use it
    home.sessionVariables = lib.mkIf (backend != "macos") {
      XDG_OPEN_CMD = openCmd;
    };
  };
}
