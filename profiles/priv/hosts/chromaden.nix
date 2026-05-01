# Laputa Machine Configuration
# Machine-specific hardware and settings for the laputa laptop

{ config, pkgs, lib, inputs, ... }:

let
  local = inputs.dots-local;
  enableGuiDefaults = local.enableGuiDefaults or (local.graphical or false);
in

{
    
  imports = [
    ../../../modules/features/sd-switch.nix
    ../../../modules/suites/ai-apps.nix
    ../../../modules/suites/scanning.nix
  ];
  
  home.packages = with pkgs; [ 
    # inputs.nixgl.packages.x86_64-linux.nixGLNvidia
    bluez
    localsend
  ];

  features.niri-noctalia = {
      renderDrmDevice = "/dev/dri/render_amd";
      terminal = "/usr/bin/ghostty";
  };

  suites.gui-apps = lib.mkIf enableGuiDefaults {
      enable = true;

      # Host extras beyond lean priv defaults
      chromium = true;
      libreoffice = true;
      gimp = true;
      inkscape = true;
      vlc = true;
      flameshot = true;
  };

  suites.ai-apps = {
      enable = true;
      opencode = true;
      grabcontext = true;
      pi = true;
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
