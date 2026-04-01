{ config, lib, pkgs, ... }:

let
  cfg = config.features.bookokrat;
in {
  options.features.bookokrat = {
    enable = lib.mkEnableOption "Enable bookokrat - terminal ebook reader";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.external.bookokrat ];
  };
}
