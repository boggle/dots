{ config, lib, pkgs, alien, ... }:

let
  coreLib = import ../core/lib.nix { inherit lib; };
  cfg = config.features.opener;
  # Shared, derived value (modules/core/platform.nix) - not an
  # independently-set option on this feature anymore (see that file's
  # comment for why).
  backend = config.core.platformBackend;

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
    enable = coreLib.mkDefaultDisabledOption "Cross-platform file opener feature";

    alias = lib.mkOption {
      type = lib.types.str;
      default = "o";
      description = "Alias name for the open command (default: 'o').";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = backend != null;
        message = ''
          features.opener.enable requires a non-null
          config.core.platformBackend (no compositor and not WSL - see
          modules/core/platform.nix). Set dotsLocal.compositor/isWsl
          appropriately, or leave features.opener disabled on a CLI-only
          host.
        '';
      }
    ];

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
