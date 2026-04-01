{ config, lib, pkgs, inputs, alien, ... }:

let
  cfg = config.suites.gui-apps;
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
    home.packages = builtins.filter (p: p != null) [
      # Terminal emulators
      (alien.mkEntry cfg.ghostty "ghostty" pkgs.ghostty)
      (alien.mkEntry cfg.wezterm "wezterm" pkgs.wezterm)

      # Browsers
      (alien.mkEntry cfg.librewolf "librewolf" pkgs.librewolf)
      (alien.mkEntry cfg.firefox "firefox" pkgs.firefox)
      (alien.mkEntry cfg.chromium "chromium" pkgs.chromium)
      
      # Office
      (alien.mkEntry cfg.libreoffice "libreoffice-fresh" pkgs.libreoffice-fresh)
      
      # Productivity
      (alien.mkEntry cfg.vscodium "vscodium" pkgs.vscodium)
      (alien.mkEntry cfg.keepassxc "keepassxc" pkgs.keepassxc)
      (alien.mkEntry cfg.sublime "sublime" pkgs.sublime)

      # PDF/Documents
      (alien.mkEntry cfg.drawio "drawio" pkgs.drawio)
      (alien.mkEntry cfg.masterpdfeditor "masterpdfeditor" pkgs.masterpdfeditor)
      (alien.mkEntry cfg.papers "papers" pkgs.papers)
      (alien.mkEntry cfg.pdfarranger "pdfarranger" pkgs.pdfarranger)
      (alien.mkEntry cfg.sioyek "sioyek" pkgs.sioyek)
      (alien.mkEntry cfg.zathura "zathura" pkgs.zathura)
      (alien.mkEntry cfg.evince "evince" pkgs.evince)
      (alien.mkEntry cfg.newsfeed "newsflash" pkgs.newsflash)

      # Graphics
      (alien.mkEntry cfg.gimp "gimp" pkgs.gimp-with-plugins)
      (alien.mkEntry cfg.inkscape "inkscape" pkgs.inkscape-with-extensions)
      (alien.mkEntry cfg.krita "krita" pkgs.krita)
      
      # Media
      (alien.mkEntry cfg.vlc "vlc" pkgs.vlc)
      (alien.mkEntry cfg.ffmpeg "ffmpeg" pkgs.ffmpeg_7-full)
      (alien.mkEntry cfg.handbrake "handbrake" pkgs.handbrake)
      (alien.mkEntry cfg.imv "imv" pkgs.imv)
      (alien.mkEntry cfg.amberol "amberol" pkgs.amberol)
      
      # Chat/Communication
      (alien.mkEntry cfg.tuba "tuba" pkgs.tuba)
      (alien.mkEntry cfg.betterbird "betterbird" pkgs.betterbird)
      
      # Utils
      (alien.mkEntry cfg.flameshot "flameshot" pkgs.flameshot)
    ];

    # Declare which alien packages are enabled
    alienPackages.enabledPackages = 
      (lib.optional cfg.ghostty "ghostty") ++
      (lib.optional cfg.wezterm "wezterm") ++
      (lib.optional cfg.librewolf "librewolf") ++
      (lib.optional cfg.firefox "firefox") ++
      (lib.optional cfg.chromium "chromium") ++
      (lib.optional cfg.libreoffice "libreoffice-fresh") ++
      (lib.optional cfg.vscodium "vscodium") ++
      (lib.optional cfg.keepassxc "keepassxc") ++
      (lib.optional cfg.sublime "sublime") ++
      (lib.optional cfg.drawio "drawio") ++
      (lib.optional cfg.masterpdfeditor "masterpdfeditor") ++
      (lib.optional cfg.papers "papers") ++
      (lib.optional cfg.pdfarranger "pdfarranger") ++
      (lib.optional cfg.sioyek "sioyek") ++
      (lib.optional cfg.zathura "zathura") ++
      (lib.optional cfg.evince "evince") ++
      (lib.optional cfg.newsfeed "newsflash") ++
      (lib.optional cfg.gimp "gimp") ++
      (lib.optional cfg.inkscape "inkscape") ++
      (lib.optional cfg.krita "krita") ++
      (lib.optional cfg.vlc "vlc") ++
      (lib.optional cfg.ffmpeg "ffmpeg") ++
      (lib.optional cfg.handbrake "handbrake") ++
      (lib.optional cfg.imv "imv") ++
      (lib.optional cfg.amberol "amberol") ++
      (lib.optional cfg.tuba "tuba") ++
      (lib.optional cfg.betterbird "betterbird") ++
      (lib.optional cfg.flameshot "flameshot");

    programs.ghostty = lib.mkIf cfg.ghostty {
      enable = true;
      enableBashIntegration = true;
    };

    home.file.".config/ghostty/config.ghostty" = lib.mkIf cfg.ghostty {
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
            "/home/pc0w/.nix-profile/share/fonts/truetype/NerdFonts/IosevkaTerm/IosevkaTermNerdFont-Regular.ttf",
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

    # LibreWolf has rich config, handle separately
    programs.librewolf = lib.mkIf cfg.librewolf {
      enable = false;
      profiles.default = {
        id = 0;
        isDefault = true;  
        
        settings = {
          "ui.systemUsesDarkTheme" = 1;
          "layout.css.prefers-color-scheme.content-override" = 2;
          "browser.uiDensity" = 1;
          "browser.compactmode.show" = true;
          "browser.tabs.drawInTitlebar" = true;
        
          "font.name.monospace.x-western" = "Iosevka Term Nerd Font";
          "font.name.sans-serif.x-western" = "Inter";
          "font.size.variable.x-western" = 14;
          "font.size.monospace.x-western" = 13;
          
          "privacy.resistFingerprinting" = false;
        };
      
        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          keepassxc-browser
          ublock-origin
          darkreader
        ];
      };
    };
  };
}
