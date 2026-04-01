{ config, lib, pkgs, inputs, alien, ... }:

let
  cfg = config.suites.gui-apps;
in
{
  options.suites.gui-apps = {
    enable = lib.mkEnableOption "Enable GUI application suite";

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
