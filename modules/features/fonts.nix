{ config, lib, pkgs, ... }:

let
  cfg = config.features.fonts;
  inherit (lib) types;
in
{
  options.features.fonts = {
    enable = lib.mkEnableOption "Enable fonts";

    # Base fonts (user preferences)
    base = lib.mkOption {
      type = types.listOf types.package;
      default = with pkgs; [
        nerd-fonts.iosevka-term 
        nerd-fonts.iosevka
      ];
      description = "Base fonts to install";
    };

    # Required fonts (added by other modules like niri-noctalia)
    required = lib.mkOption {
      type = types.listOf types.package;
      default = [];
      description = "Additional fonts required by other features";
    };
  };

  config = lib.mkIf cfg.enable {
    fonts.fontconfig.enable = true;
    
    # Improve font smoothing and hinting
    fonts.fontconfig.defaultFonts = {
      monospace = [ "IosevkaTerm Nerd Font" "Iosevka Term" "monospace" ];
      sansSerif = [ "Inter" "Noto Sans" "sans-serif" ];
      serif = [ "Noto Serif" "serif" ];
    };
    
    home.packages = cfg.base ++ cfg.required;
  };
}
