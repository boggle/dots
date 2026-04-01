# Laputa Machine Configuration
# Machine-specific hardware and settings for the laputa laptop

{ config, pkgs, lib, ... }:

{
    
  imports = [
    ../../../modules/features/sd-switch.nix
    ../../../modules/features/opener.nix
    ../../../modules/features/clipboard.nix
    ../../../modules/suites/gui-apps.nix
    ../../../modules/suites/tui-apps.nix
    ../../../modules/suites/ai-apps.nix
    ../../../modules/suites/scanning.nix
  ];
  
  home.packages = with pkgs; [ 
    # inputs.nixgl.packages.x86_64-linux.nixGLNvidia
    bluez
    localsend
  ];

  features.opener = {
      enable = true;
      backend = "wayland";
      alias = "o";  # Use 'o' to open files
  };

  features.clipboard = {
    enable = true;
    backend = "wayland";
  };

  features.niri-noctalia = {
      renderDrmDevice = "/dev/dri/render_amd";
      terminal = "/usr/bin/ghostty";
  };

  suites.gui-apps = {
      enable = true;
      librewolf = true;
      chromium = true;
      libreoffice = true;
      vscodium = true;
      keepassxc = true;
      drawio = true;
      gimp = true;
      inkscape = true;
      vlc = true;
      ffmpeg = true;
      flameshot = true;
      zathura = true;
  };

  suites.tui-apps = {
      enable = true;
      # Core TUI
      btop = true;
      gping = true;
      # Email
      aerc = false;
      deltachat = false;
      # DTP
      imagemagick = true;
      graphviz = true;
      pandoc = false;
      typst = false;
  };

  suites.ai-apps = {
      enable = true;
      opencode = true;
      grabcontext = true;
  };
  
  home.sessionVariables = {
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent.socket";
    SAXON_DIR="$HOME/Applications/SaxonHE12-9J";
    XEP_HOME="$HOME/Applications/XEP";
  };

  programs.ssh = {
    matchBlocks."*" = {
      identityFile = "~/.ssh/id_github_chromaden";
      addKeysToAgent = "yes";
    };
  };
  
  xdg.configFile."xdg-desktop-portal/portals.conf".text = ''
    [preferred]
    default=gnome;gtk;
  '';
  
  # Power toggle script - machine specific (eDP-1 display, CPU boost)
  home.file.".local/bin/power-toggle.sh" = {
    executable = true;
    text = ''
      #!/bin/bash
      # Use absolute paths from the Nix store to be safe
      BOOST_FILE="/sys/devices/system/cpu/cpufreq/boost"
    
      if [ $(cat $BOOST_FILE) -eq 1 ]; then
        echo 0 | sudo ${pkgs.bash}/bin/tee $BOOST_FILE
        ${pkgs.wlr-randr}/bin/wlr-randr --output eDP-1 --mode 2560x1600@60.000
        ${pkgs.brightnessctl}/bin/brightnessctl set 30%
        ${pkgs.libnotify}/bin/notify-send "Power" "Eco Mode"
      else
        echo 1 | sudo ${pkgs.bash}/bin/tee $BOOST_FILE
        ${pkgs.wlr-randr}/bin/wlr-randr --output eDP-1 --mode 2560x1600@120.000
        ${pkgs.libnotify}/bin/notify-send "Power" "Performance Mode"
      fi
    '';  
  };

  # Scanner support for this machine
  suites.scanning = {
      enable = true;
      simple-scan = true;
      gscan2pdf = true;
      tesseract = true;
  };

  # AppImages - enable all on this machine
  # features.appimages = {
  #   enable = true;
  #   apps = {
  #     betterbird.enable = true;
  #     buttercup.enable = true;
  #     discord.enable = true;
  #     tuta.enable = true;
  #   };
  # };
}
