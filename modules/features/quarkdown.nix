{ config, lib, pkgs, ... }:

let
  coreLib = import ../core/lib.nix { inherit lib; };
  cfg = config.features.quarkdown;
in {
  options.features.quarkdown = {
    enable = coreLib.mkDefaultDisabledOption "Quarkdown - Markdown typesetting system";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.external.quarkdown ];
  };
}
