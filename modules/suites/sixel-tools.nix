{ config, lib, pkgs, inputs, alien, ... }:

let
  cfg = config.suites.sixel-tools;

  sixelMpvBinary = pkgs.mpv-unwrapped.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.pkg-config ];
    buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.libsixel ];
    mesonFlags = (old.mesonFlags or [ ]) ++ [ "-Dsixel=enabled" ];
  });

  # NOTE: `mpv` is deliberately NOT part of this appSet - it's handled
  # separately below via programs.mpv with the custom sixelMpvBinary, never
  # alien-managed.
  coreLib = import ../core/lib.nix { inherit lib; };
  appSet = coreLib.mkAppSet {
    inherit alien;
    apps = {
      chafa = { enable = cfg.chafa; pkg = pkgs.chafa; };
      catimg = { enable = cfg.catimg; pkg = pkgs.catimg; };
      lsix = { enable = cfg.lsix; pkg = pkgs.lsix; };
      ytdlp = { enable = cfg.ytdlp; pkg = pkgs.yt-dlp; alienName = "yt-dlp"; };
    };
  };
in
{
  options.suites.sixel-tools = {
    enable = lib.mkEnableOption "Enable Sixel graphics tools" // { default = true; };

    # Terminal graphics
    chafa = lib.mkEnableOption "Chafa (images in terminal)" // { default = true; };
    catimg = lib.mkEnableOption "catimg (images in terminal)" // { default = true; };
    lsix = lib.mkEnableOption "lsix (ls for images)";

    # Video
    mpv = lib.mkEnableOption "mpv (Sixel-enabled)";
    ytdlp = lib.mkEnableOption "yt-dlp";
  };

  config = lib.mkIf cfg.enable {
    home.packages = appSet.packages ++ [ pkgs.fontconfig ];

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
    
    # NOTE: `lib.mkMerge` here, NOT a plain `//` - merging a `lib.mkIf`
    # result into a plain attrset via `//` breaks the module system's own
    # mkIf handling (the combined value's outer shape becomes the mkIf
    # wrapper itself, silently dropping FONTCONFIG_FILE entirely
    # regardless of cfg.ytdlp - confirmed via `nix eval`, this was a real,
    # live bug). `lib.mkMerge [ {...} (lib.mkIf ... {...}) ]` is the
    # correct idiom for "always this, plus conditionally that" on an
    # attrsOf-typed option.
    home.sessionVariables = lib.mkMerge [
      { FONTCONFIG_FILE = "${pkgs.fontconfig.out}/etc/fonts/fonts.conf"; }
      (lib.mkIf cfg.ytdlp { MPV_YTDL_EXE = "${pkgs.yt-dlp}/bin/yt-dlp"; })
    ];

    # Declare which alien packages are enabled
    alienPackages.enabledPackages = appSet.alienEnabled;
  };
}
