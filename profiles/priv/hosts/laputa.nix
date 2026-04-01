# Laputa Machine Configuration
# Machine-specific hardware and settings for the laputa laptop

{ config, pkgs, lib, ... }:

{
    
  imports = [
    ../../../modules/features/sd-switch.nix
    ../../../modules/features/opener.nix
    ../../../modules/features/clipboard.nix
  ];
  
  home.packages = with pkgs; [ 
    # inputs.nixgl.packages.x86_64-linux.nixGLNvidia
    bluez
    localsend
  ];

  features.opener = {
      enable = true;
      backend = "wayland";
      alias = "o";
  };

  features.clipboard = {
    enable = true;
    backend = "wayland";
  };

  # Laputa uses integrated Intel graphics, no explicit render device needed
  # features.niri-noctalia.renderDrmDevice = "/dev/dri/renderD128";

  home.sessionVariables = {
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent.socket";
    GDK_SCALE = "1";
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
        ${pkgs.wlr-randr}/bin/wlr-randr --output eDP-1 --mode 1920x1200@60.000
        ${pkgs.brightnessctl}/bin/brightnessctl set 30%
        ${pkgs.libnotify}/bin/notify-send "Power" "Eco Mode"
      else
        echo 1 | sudo ${pkgs.bash}/bin/tee $BOOST_FILE
        ${pkgs.wlr-randr}/bin/wlr-randr --output eDP-1 --mode 1920x1200@120.000
        ${pkgs.libnotify}/bin/notify-send "Power" "Performance Mode"
      fi
    '';  
  };

  # Scanner support for this machine
  features.scanning = {
    enable = true;
    simple-scan = true;
    gscan2pdf = true;
    tesseract = true;
  };

  # AppImages - enable all on this machine
  features.appimages = {
    enable = true;
    apps = {
      steam.enable = true;
      betterbird.enable = true;
      buttercup.enable = true;
      discord.enable = true;
      tuta.enable = true;
    };
  };
}
