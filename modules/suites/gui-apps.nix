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
    enable = coreLib.mkDefaultDisabledOption "Enable GUI application suite";

    # Terminal emulators
    ghostty = coreLib.mkDefaultDisabledOption "Ghostty terminal";
    wezterm = coreLib.mkDefaultDisabledOption "WezTerm terminal emulator";

    # Browsers - opt-in only (no global default; enable explicitly per
    # machine, e.g. via dotsLocal.extraModules/host.nix)
    librewolf = coreLib.mkDefaultDisabledOption "LibreWolf browser";
    chromium = coreLib.mkDefaultEnabledOption "Chromium browser";

    firefox = coreLib.mkDefaultDisabledOption "Firefox browser";

    # Office - opt-in only, see librewolf's comment above
    libreoffice = coreLib.mkDefaultDisabledOption "LibreOffice";
    
    # Productivity
    vscodium = coreLib.mkDefaultDisabledOption "VSCodium editor";
    keepassxc = coreLib.mkDefaultDisabledOption "KeePassXC password manager";
    sublime = coreLib.mkDefaultDisabledOption "Sublime Text editor";
    
    # PDF/Documents
    drawio = coreLib.mkDefaultDisabledOption "Draw.io diagram editor";
    pdfarranger = coreLib.mkDefaultDisabledOption "PDF Arranger";
    zathura = coreLib.mkDefaultDisabledOption "zathura (PDF viewer)";
    evince = coreLib.mkDefaultDisabledOption "Evince (PDF viewer)";
    papers = coreLib.mkDefaultDisabledOption "Papers (GNOME document viewer)";

    masterpdfeditor = coreLib.mkDefaultDisabledOption "Master PDF Editor";
    sioyek = coreLib.mkDefaultDisabledOption "Sioyek PDF viewer";
    
    # Graphics
    gimp = coreLib.mkDefaultDisabledOption "GIMP image editor";
    inkscape = coreLib.mkDefaultDisabledOption "Inkscape vector graphics";
    krita = coreLib.mkDefaultDisabledOption "Krita digital painting";

    # Media
    vlc = coreLib.mkDefaultDisabledOption "VLC media player";
    ffmpeg = coreLib.mkDefaultDisabledOption "FFmpeg (full)";
    handbrake = coreLib.mkDefaultDisabledOption "HandBrake video transcoder";
    imv = coreLib.mkDefaultDisabledOption "imv image viewer";
    amberol = coreLib.mkDefaultDisabledOption "Amberol music player";
    
    # Chat/Communication/Social
    tuba = coreLib.mkDefaultDisabledOption "Tuba (Fediverse client)";
    betterbird = coreLib.mkDefaultDisabledOption "Betterbird (email client)";
    newsfeed = coreLib.mkDefaultDisabledOption "Newsflash RSS reader";
    
    # Utils
    flameshot = coreLib.mkDefaultDisabledOption "Flameshot screenshot tool";
  };

  config = lib.mkMerge [
    # Global, non-context-specific "desktop app baseline": whenever
    # there's an actual GUI backend to use (config.core.enableGuiDefaults,
    # computed purely from dotsLocal - see modules/core/platform.nix),
    # turn the suite on with a small curated set of everyday desktop
    # tools (terminal, browser, PDF viewer, diagram editor, editor,
    # password manager, video toolkit) rather than requiring every
    # context to hand-roll this list. `libreoffice`/`firefox`/etc. are
    # deliberately NOT in this baseline - genuinely opt-in only, per
    # "only when requested". Still just `mkDefault`s - an explicit
    # context/host setting always wins.
    {
      suites.gui-apps.enable = lib.mkDefault config.core.enableGuiDefaults;
      suites.gui-apps.ghostty = lib.mkDefault config.core.enableGuiDefaults;
      suites.gui-apps.keepassxc = lib.mkDefault config.core.enableGuiDefaults;
      suites.gui-apps.librewolf = lib.mkDefault config.core.enableGuiDefaults;
      suites.gui-apps.zathura = lib.mkDefault config.core.enableGuiDefaults;
      suites.gui-apps.drawio = lib.mkDefault config.core.enableGuiDefaults;
      suites.gui-apps.vscodium = lib.mkDefault config.core.enableGuiDefaults;
      suites.gui-apps.ffmpeg = lib.mkDefault config.core.enableGuiDefaults;
    }
    (lib.mkIf cfg.enable {
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

    # NOTE: unlike zellij/lazygit (see suites/tui-apps.nix), this genuinely
    # needs `programs.wezterm` for its real `extraConfig` below - but
    # `programs.wezterm.package` is NOT nullable (unlike lazygit's), so
    # this unconditionally re-adds `pkgs.wezterm` to home.packages even
    # when alien-managed (wezterm has a real alien spec, see
    # gui-apps.cachyos-packages.nix, and `appSet` above already correctly
    # omits the Nix package whenever it is). Accepted, harmless tradeoff
    # for now (a second, unused copy of the same derivation in the Nix
    # store) rather than hand-rolling this config via `home.file` -
    # wezterm isn't currently enabled anywhere, so this isn't costing
    # anything today; revisit if wezterm actually gets used and the
    # duplication becomes worth avoiding.
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
    # through Home Manager's `programs.librewolf` module - native
    # librewolf-bin is the intended path, not a Nix-managed LibreWolf.
    })
  ];
}
