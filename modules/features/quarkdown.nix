{ config, lib, pkgs, ... }:

let
  cfg = config.features.quarkdown;
in {
  options.features.quarkdown = {
    enable = lib.mkEnableOption "Quarkdown - Markdown typesetting system";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.external.quarkdown ];
  };
}
