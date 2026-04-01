{ pkgs, lib, inputs, ... }:
  # Work Profile - WSL Environment
  # Sources common essentials first, then adds work-specific configuration
  
{
  imports = [
    # Common essentials (nix, git, viewer, bash)
    ../common/home.nix
    
    # Work-specific features
    ../../modules/features/fonts.nix
    ../../modules/features/terminal.nix
    ../../modules/features/sd-switch.nix
    ../../modules/features/clipboard.nix
    ../../modules/features/opener.nix
    ../../modules/features/apps.nix
    ../../modules/features/dtp.nix
    ../../modules/features/email.nix
    ../../modules/suites/sixel-tools.nix
    ../../modules/suites/cloud-tools.nix
  ];

  home.packages = with pkgs; [ 
       bluez
       localsend
  ];
 
  # ============================================================================
  # MACHINE SPECIFIC SECTION (will be moved to host configs later)
  # ============================================================================
  # WSL-specific: X11 clipboard instead of Wayland
  features.clipboard = {
      enable = true;
      backend = lib.mkDefault "x11";
  };

  # WSL Wayland socket fix
  home.sessionVariables = {
    WAYLAND_DISPLAY = lib.mkDefault "wayland-0";
  };

  # WSL clipboard aliases
  programs.bash.shellAliases = {
    copy = "xclip -selection clipboard";
    paste = "xclip -selection clipboard -o"; 
  };
  # ============================================================================
  # END MACHINE SPECIFIC SECTION
  # ============================================================================

  features.opener = {
      enable = true;
      backend = lib.mkDefault "x11";
      alias = "o";
  };

  features.viewer = {
      enable = true;
      alias = "v";
      preferImageViewer = "chafa";
      enableVideo = true;
      enableDirectoryTree = true;
      enableArchives = true;
      enableDataFormats = true;
      enableFzfPicker = true;
  };
    
  # AI features now managed via ai-apps suite in host configs

  features.fonts = {
      enable = true;
  };
  
  features.terminal = {
      enable = true;
      wezterm = true;
  };
  
  suites.sixel-tools = {
      enable = true;
      chafa = true;
      catimg = true;
      mpv = true;
      ytdlp = true;
  };

  suites.cloud-tools = {
      enable = true;
      github = true;
      azure = true;
  };
      
  features.apps = {
      enable = true;
      vscodium = true;
      keepassxc = false;  # WSL limitation
      drawio = true;
      tuba = false;  # GNOME app
      flameshot = false;  # Wayland tool
      imv = true;
      amberol = true;
      ffmpeg = true;
      vlc = true;
      gimp = true;
      inkscape = true;
  };
        
  features.dtp = {
      enable = true;
      zathura = true;
  };

  features.email = {
      enable = false;
  };

  features.git = {
      enable = true;
      git = true;
      jj = true;
      delta = true;
  };

  features.dev-tools = {
      enable = true;
      rust = true;
      haskell = false;
      egglog = false;
      steel = false;
  };

  features.tune = {
      enable = true;
      packages = {
        ripgrep = { enable = true; mode = "fast"; lang = "rust"; scope = "global"; };
        fd = { enable = true; mode = "fast"; lang = "rust"; scope = "global"; };
        yazi = { 
          enable = true; 
          mode = "fast"; 
          lang = "rust"; 
          scope = "wrapped"; 
          suffix = "-tuned";
        };
      };
  };

  programs.bash = {
      enable = true;
      initExtra = ''        
        export GPG_TTY=$(tty 2>/dev/null || echo /dev/tty)

        export XDG_DATA_DIRS="$HOME/.nix-profile/share:$HOME/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:$XDG_DATA_DIRS";
        if command -v github-copilot-cli > /dev/null; then
          eval "$(github-copilot-cli alias -- bash)"
        fi
      '';
  };

  systemd.user.sessionVariables = {
    SSL_CERT_FILE = "/etc/ssl/ca-bundle.pem"; 
    NIX_SSL_CERT_FILE = "/etc/ssl/ca-bundle.pem";
  };
  
  home.sessionVariables = {
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent.socket";
  };

  xdg.configFile."xdg-desktop-portal/portals.conf".text = ''
    [preferred]
    default=gnome;gtk;
  '';
}
