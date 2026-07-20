{ config, lib, pkgs, ... }:

let
  coreLib = import ../core/lib.nix { inherit lib; };
  cfg = config.features.bookokrat;
in {
  options.features.bookokrat = {
    enable = coreLib.mkDefaultDisabledOption "Enable bookokrat - terminal ebook reader";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.external.bookokrat ];
  };
}
