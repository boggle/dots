# Laputa Machine Configuration
# Machine-specific hardware and settings for the laputa laptop

{ config, pkgs, lib, ... }:

{
    
  imports = [
    ../../../modules/features/sd-switch.nix
    ../../../modules/features/opener.nix
    ../../../modules/features/clipboard.nix
    ../../../modules/suites/tui-apps.nix
    ../../../modules/suites/ai-apps.nix
  ];
  
  home.packages = with pkgs; [ 
    # inputs.nixgl.packages.x86_64-linux.nixGLNvidia
    bluez
    localsend
  ];

  features.opener = {
      enable = true;
      backend = "wsl";
      alias = "o";  # Use 'o' to open files
  };

  features.clipboard = {
    enable = true;
    backend = "wsl";
  };

  # WSL2/WSLg compatibility
  home.sessionVariables = {
    WAYLAND_DISPLAY = lib.mkDefault "wayland-0";
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent.socket";
  };

  # suites.gui-apps = {
  #     enable = false;
  #     librewolf = true;
  #     chromium = true;
  #     libreoffice = true;
  #     vscodium = true;
  #     keepassxc = true;
  #     drawio = true;
  #     gimp = true;
  #     inkscape = true;
  #     vlc = true;
  #     ffmpeg = true;
  #     flameshot = true;
  #     zathura = true;
  # };

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
  
  programs.ssh = {
    matchBlocks."*" = {
      identityFile = "~/.ssh/id_github_triomino";
      addKeysToAgent = "yes";
    };
  };
  
  # xdg.configFile."xdg-desktop-portal/portals.conf".text = ''
  #   [preferred]
  #   default=gnome;gtk;
  # '';

  # Scanner support for this machine
  # suites.scanning = {
  #     enable = false;
  #     simple-scan = true;
  #     gscan2pdf = true;
  #     tesseract = true;
  # };

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
