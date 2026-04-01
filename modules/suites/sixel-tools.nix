{ config, lib, pkgs, inputs, alien, ... }:

let
  cfg = config.suites.sixel-tools;

  sixelMpvBinary = pkgs.mpv-unwrapped.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.pkg-config ];
    buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.libsixel ];
    mesonFlags = (old.mesonFlags or [ ]) ++ [ "-Dsixel=enabled" ];
  });
in
{
  options.suites.sixel-tools = {
    enable = lib.mkEnableOption "Enable Sixel graphics tools";

    # Terminal graphics
    chafa = lib.mkEnableOption "Chafa (images in terminal)";
    catimg = lib.mkEnableOption "catimg (images in terminal)";
    lsix = lib.mkEnableOption "lsix (ls for images)";

    # Video
    mpv = lib.mkEnableOption "mpv (Sixel-enabled)";
    ytdlp = lib.mkEnableOption "yt-dlp";
  };

  config = lib.mkIf cfg.enable {
    home.packages = builtins.filter (p: p != null) [
      (alien.mkEntry cfg.chafa "chafa" pkgs.chafa)
      (alien.mkEntry cfg.catimg "catimg" pkgs.catimg)
      (alien.mkEntry cfg.lsix "lsix" pkgs.lsix)
      (alien.mkEntry cfg.ytdlp "yt-dlp" pkgs.yt-dlp)
      pkgs.fontconfig
    ];

    programs.mpv = lib.mkIf cfg.mpv {
      enable = true;
      package = sixelMpvBinary;
      config = {
        vo = "sixel";
        osc = "no";
        osd-level = 0;
        osd-bar = "no";
        ytdl-format = "bestvideo[height<=720]+bestaudio/best";
        vf = "scale=-1:720";
        video-align-x = "-1";
        video-align-y = "-1";
        display-fps-override = 20;
        video-sync = "display-resample";
        framedrop = "vo";
        hwdec = "auto";
        term-status-msg = "";
      };
    };
    
    home.sessionVariables = {
      FONTCONFIG_FILE = "${pkgs.fontconfig.out}/etc/fonts/fonts.conf";
    } // (lib.mkIf cfg.ytdlp { MPV_YTDL_EXE = "${pkgs.yt-dlp}/bin/yt-dlp"; });

    # Declare which alien packages are enabled
    alienPackages.enabledPackages = 
      (lib.optional cfg.chafa "chafa") ++
      (lib.optional cfg.catimg "catimg") ++
      (lib.optional cfg.lsix "lsix") ++
      (lib.optional cfg.ytdlp "yt-dlp");
  };
}
