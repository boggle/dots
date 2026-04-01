{ config, lib, pkgs, inputs, alien, ... }:

let
  cfg = config.suites.scanning;
in
{
  options.suites.scanning = {
    enable = lib.mkEnableOption "Enable scanning/OCR tools";

    simple-scan = lib.mkEnableOption "Simple Scan (GNOME scanner app)";
    gscan2pdf = lib.mkEnableOption "gscan2pdf (PDF from scans)";
    tesseract = lib.mkEnableOption "Tesseract OCR engine";
  };

  config = lib.mkIf cfg.enable {
    home.packages = builtins.filter (p: p != null) [
      (alien.mkEntry cfg.simple-scan "simple-scan" pkgs.simple-scan)
      (alien.mkEntry cfg.gscan2pdf "gscan2pdf" pkgs.gscan2pdf)
      (alien.mkEntry cfg.tesseract "tesseract" pkgs.tesseract)
    ];

    # Declare which alien packages are enabled
    alienPackages.enabledPackages = 
      (lib.optional cfg.simple-scan "simple-scan") ++
      (lib.optional cfg.gscan2pdf "gscan2pdf") ++
      (lib.optional cfg.tesseract "tesseract");
  };
}
