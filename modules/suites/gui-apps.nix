{ config, lib, pkgs, inputs, alien, ... }:

let
  cfg = config.suites.gui-apps;
  coreLib = import ../core/lib.nix { inherit lib; };
  appSet = coreLib.mkAppSet {
    inherit alien;
    apps = {
      # Terminal emulators
      ghostty = { enable = cfg.ghostty; pkg = pkgs.ghostty; };
      wezterm = { enable = cfg.wezterm; pkg = pkgs.wezterm; };

      # Browsers
      librewolf = { enable = cfg.librewolf; pkg = pkgs.librewolf; };
      firefox = { enable = cfg.firefox; pkg = pkgs.firefox; };
      chromium = { enable = cfg.chromium; pkg = pkgs.chromium; };

      # Office
      libreoffice = { enable = cfg.libreoffice; pkg = pkgs.libreoffice-fresh; alienName = "libreoffice-fresh"; };

      # Productivity
      vscodium = { enable = cfg.vscodium; pkg = pkgs.vscodium; };
      keepassxc = { enable = cfg.keepassxc; pkg = pkgs.keepassxc; };
      sublime = { enable = cfg.sublime; pkg = pkgs.sublime; };

      # PDF/Documents
      drawio = { enable = cfg.drawio; pkg = pkgs.drawio; };
      masterpdfeditor = { enable = cfg.masterpdfeditor; pkg = pkgs.masterpdfeditor; };
      papers = { enable = cfg.papers; pkg = pkgs.papers; };
      pdfarranger = { enable = cfg.pdfarranger; pkg = pkgs.pdfarranger; };
      sioyek = { enable = cfg.sioyek; pkg = pkgs.sioyek; };
      zathura = { enable = cfg.zathura; pkg = pkgs.zathura; };
      evince = { enable = cfg.evince; pkg = pkgs.evince; };
      newsfeed = { enable = cfg.newsfeed; pkg = pkgs.newsflash; alienName = "newsflash"; };

      # Graphics
      gimp = { enable = cfg.gimp; pkg = pkgs.gimp-with-plugins; };
      inkscape = { enable = cfg.inkscape; pkg = pkgs.inkscape-with-extensions; };
      krita = { enable = cfg.krita; pkg = pkgs.krita; };

      # Media
      vlc = { enable = cfg.vlc; pkg = pkgs.vlc; };
      ffmpeg = { enable = cfg.ffmpeg; pkg = pkgs.ffmpeg_7-full; };
      handbrake = { enable = cfg.handbrake; pkg = pkgs.handbrake; };
      imv = { enable = cfg.imv; pkg = pkgs.imv; };
      amberol = { enable = cfg.amberol; pkg = pkgs.amberol; };

      # Chat/Communication
      tuba = { enable = cfg.tuba; pkg = pkgs.tuba; };
      betterbird = { enable = cfg.betterbird; pkg = pkgs.betterbird; };

      # Utils
      flameshot = { enable = cfg.flameshot; pkg = pkgs.flameshot; };
    };
  };
in
{
  options.suites.gui-apps = {
    enable = lib.mkEnableOption "Enable GUI application suite";

    # Terminal emulators
    ghostty = lib.mkEnableOption "Ghostty terminal";
    wezterm = lib.mkEnableOption "WezTerm terminal emulator";

    # Browsers
    librewolf = lib.mkEnableOption "LibreWolf browser" // { default = true; };
    firefox = lib.mkEnableOption "Firefox browser";
    chromium = lib.mkEnableOption "Chromium browser" // { default = true; };

    # Office
    libreoffice = lib.mkEnableOption "LibreOffice" // { default = true; };
    
    # Productivity
    vscodium = lib.mkEnableOption "VSCodium editor";
    keepassxc = lib.mkEnableOption "KeePassXC password manager";
    sublime = lib.mkEnableOption "Sublime Text editor";
    
    # PDF/Documents
    drawio = lib.mkEnableOption "Draw.io diagram editor";
    masterpdfeditor = lib.mkEnableOption "Master PDF Editor";
    papers = lib.mkEnableOption "Papers (PDF viewer)";
    pdfarranger = lib.mkEnableOption "PDF Arranger";
    sioyek = lib.mkEnableOption "Sioyek PDF viewer";
    zathura = lib.mkEnableOption "zathura (PDF viewer)";
    evince = lib.mkEnableOption "Evince (PDF viewer)";
    newsfeed = lib.mkEnableOption "Newsflash RSS reader";
    
    # Graphics
    gimp = lib.mkEnableOption "GIMP image editor";
    inkscape = lib.mkEnableOption "Inkscape vector graphics";
    krita = lib.mkEnableOption "Krita digital painting";

    # Media
    vlc = lib.mkEnableOption "VLC media player";
    ffmpeg = lib.mkEnableOption "FFmpeg (full)";
    handbrake = lib.mkEnableOption "HandBrake video transcoder";
    imv = lib.mkEnableOption "imv image viewer";
    amberol = lib.mkEnableOption "Amberol music player";
    
    # Chat/Communication
    tuba = lib.mkEnableOption "Tuba (Fediverse client)";
    betterbird = lib.mkEnableOption "Betterbird (email client)";
    
    # Utils
    flameshot = lib.mkEnableOption "Flameshot screenshot tool";
  };

  config = lib.mkIf cfg.enable {
    home.packages = appSet.packages;

    # Declare which alien packages are enabled
    alienPackages.enabledPackages = appSet.alienEnabled;

    # Ghostty config file (using CachyOS ghostty, not programs.ghostty module)
    home.file.".config/ghostty/config" = lib.mkIf cfg.ghostty {
      force = true;
      text = ''
        # --- Firewatch Theme Colors ---
        background = #1a1a1c
        foreground = #bebebe
        selection-background = #3c3c3c
        selection-foreground = #ffffff
        cursor-color = #e27878

        # Palette
        palette = 0=#1a1a1c
        palette = 1=#e27878
        palette = 2=#b4be82
        palette = 3=#e0af68
        palette = 4=#84a0c6
        palette = 5=#a093c7
        palette = 6=#89b8c2
        palette = 7=#c0caf5
        palette = 8=#3e3e40
        palette = 9=#e98989
        palette = 10=#c0ca8e
        palette = 11=#e9b978
        palette = 12=#91accf
        palette = 13=#aca1d3
        palette = 14=#93c4d1
        palette = 15=#d0d0d0

        # --- Font Configuration ---
        font-family = "IosevkaTerm NFM Light"
        font-family-bold = "IosevkaTerm NFM Medium"
        font-family-italic = "IosevkaTerm NFM Light Obl"
        font-family-bold-italic = "IosevkaTerm NFM Medium Obl"
        font-size = 13

        # --- UI Settings ---
        cursor-style-blink = false
        adjust-cursor-thickness = 1
        window-step-resize = true
        window-decoration = false
        shell-integration = detect
        focus-follows-mouse = true
        copy-on-select = true
        term = xterm-256color

        # --- Visual Polish (Niri 25.08) ---
        background-opacity = 0.78
        background-blur = 10
        unfocused-split-opacity = 0.85
      '';
    };

    programs.wezterm = lib.mkIf cfg.wezterm {
      enable = true;
      package = pkgs.wezterm;
      extraConfig = ''
        local wezterm = require "wezterm"

        return {
          -- Font fallback with absolute path (ensure font is installed correctly)
          font = wezterm.font_with_fallback {
            os.getenv("HOME") .. "/.nix-profile/share/fonts/truetype/NerdFonts/IosevkaTerm/IosevkaTermNerdFont-Regular.ttf",
            "JetBrains Mono"  -- Fallback font
          },
          font_size = 12.0,

          -- Tabs and window settings
          enable_tab_bar = true,
          hide_tab_bar_if_only_one_tab = false,
          use_fancy_tab_bar = true,
          window_decorations = "RESIZE",

          -- Transparency settings
          window_background_opacity = 0.85,  -- background opacity
          text_background_opacity = 0.85,    -- text opacity

          -- Dimming for inactive panes while maintaining transparency
          inactive_pane_hsb = {
            brightness = 0.75,  -- Dimming inactive panes to 75%
            saturation = 0.8,   -- Slightly reduce saturation
            hue = 1.0,          -- Keep hue intact
          },

          -- Color scheme settings
          color_schemes = {
            Firewatch = {
              background = "#1F1F28",
              foreground = "#C5C8C6",
            }
          },
          color_scheme = "Firewatch",

          -- Wayland support and other tweaks
          enable_wayland = true,
          scrollback_lines = 3500,
          enable_scroll_bar = false,
        }
      '';
    };

    # NOTE: LibreWolf is installed as a native/alien package (librewolf-bin
    # via pacman/paru, see `alien.mkEntry cfg.librewolf` above) rather than
    # through Home Manager's `programs.librewolf` module. A rich
    # `programs.librewolf` config (extensions: keepassxc-browser,
    # ublock-origin, darkreader; hardened settings) used to live here but
    # was permanently dead - it hardcoded `enable = false;` regardless of
    # `cfg.librewolf`, so none of it ever applied. Removed rather than
    # fixed: native librewolf-bin is the intended path, not a Nix-managed
    # LibreWolf.
  };
}
