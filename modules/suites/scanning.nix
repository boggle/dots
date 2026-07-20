{ config, lib, pkgs, inputs, alien, ... }:

let
  cfg = config.suites.scanning;
  coreLib = import ../core/lib.nix { inherit lib; };
  appSet = coreLib.mkAppSet {
    inherit alien;
    apps = {
      "simple-scan" = { enable = cfg.simple-scan; pkg = pkgs.simple-scan; };
      gscan2pdf = { enable = cfg.gscan2pdf; pkg = pkgs.gscan2pdf; };
      tesseract = { enable = cfg.tesseract; pkg = pkgs.tesseract; };
    };
  };
in
{
  options.suites.scanning = {
    enable = coreLib.mkDefaultDisabledOption "Enable scanning/OCR tools";

    simple-scan = coreLib.mkDefaultDisabledOption "Simple Scan (GNOME scanner app)";
    gscan2pdf = coreLib.mkDefaultDisabledOption "gscan2pdf (PDF from scans)";
    tesseract = coreLib.mkDefaultDisabledOption "Tesseract OCR engine";
  };

  config = lib.mkIf cfg.enable {
    home.packages = appSet.packages;

    # Declare which alien packages are enabled
    alienPackages.enabledPackages = appSet.alienEnabled;
  };
}
