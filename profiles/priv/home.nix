{ pkgs, lib, inputs, ... }:
  # Priv Profile - Personal Linux Environment

  let
    local = inputs.dots-local;
    hostname = local.host or null;
    enableGuiDefaults = local.enableGuiDefaults or (local.graphical or false);
    graphicalBackend = local.graphicalBackend or "wayland";
    validBackend = builtins.elem graphicalBackend [ "wayland" "x11" "wsl" "macos" ];
    hostImport = if hostname != null 
      then ./hosts/${hostname}.nix
      else null;
  in {
  
  imports = lib.filter (x: x != null) [
    ../common/home.nix
    
    ../../modules/features/opener.nix
    ../../modules/features/clipboard.nix
    ../../modules/suites/sixel-tools.nix
    ../../modules/features/appimages.nix
    ../../modules/features/fonts.nix
    ../../modules/suites/pim-apps.nix
    ../../modules/features/bookokrat.nix
    ../../modules/features/quarkdown.nix
    ../../modules/suites/gui-apps.nix
    ../../modules/suites/tui-apps.nix
    
    hostImport
  ];
  
  # Package-specific tuning
  assertions = [
    {
      assertion = validBackend;
      message = "dots-local.graphicalBackend must be one of: wayland, x11, wsl, macos";
    }
  ];

  features.opener = {
      enable = validBackend;
      backend = graphicalBackend;
      alias = "o";
  };

  features.clipboard = {
    enable = validBackend;
    backend = graphicalBackend;
  };

  # Common AI Apps configuration
  suites.ai-apps = {
    enable = true;
    opencode = true;
    grabcontext = true;
    # Default pi packages - hosts extend with ++
    piPackages = [
      "pi-btw"
      "pi-subagents"
      "context-mode"
      "@tintinweb/pi-subagents"
      "pi-mcp-adapter"
      "@plannotator/pi-extension"
      "pi-powerline-footer"
      "pi-lens"
      "@juicesharp/rpiv-ask-user-question"
      "@juicesharp/rpiv-advisor"
      "@juicesharp/rpiv-todo"
      "@samfp/pi-memory"
      "@juicesharp/rpiv-web-tools"
    ];
  };

  # Package-specific tuning
  features.tune = {
      enable = true;
      packages = {
        ripgrep = { enable = true; mode = "fast"; lang = "rust"; scope = "global"; };
        fd = { enable = true; mode = "fast"; lang = "rust"; scope = "global"; };
        
        # tesseract = { enable = true; mode = "fast"; lang = "c"; scope = "global"; };
        # simple-scan = { enable = false; mode = "fast"; lang = "c"; scope = "global"; };
        # gscan2pdf = { enable = false; mode = "fast"; lang = "c"; scope = "global"; };
        
        # Example: Wrapped scope with custom suffix (both baseline and tuned available)
        # yazi baseline on PATH, yazi-tuned available for explicit calls
        # yazi = { 
        #  enable = true; 
        #  mode = "fast"; 
        #  lang = "rust"; 
        #  scope = "wrapped"; 
        #  suffix = "-tuned";  # Optional, defaults to "-tuned"
        # };
      };
  };
  
  features.viewer = {
      enable = true;
      alias = "v";  # Use 'v' to view files in terminal
      ripgrepAll = true;
      preferImageViewer = "chafa";  # "chafa" or "catimg"
      enableVideo = true;           # Use mpv for video files
      enableDirectoryTree = true;   # lsd --tree for directories
      enableArchives = true;        # List archive contents
      enableDataFormats = true;     # Pretty print JSON/CSV/YAML
      enableFzfPicker = true;       # Interactive picker when no args
  };
     
  features.network = {
      enable = true;
      sshAgent = true;
      gpgAgent = true;
      gpgSsh = false;
      doggo = true;
      xh = true;
      rclone = true;
  };

  features.git = {
      enable = true;
      git = true;
      jj = true;
      delta = true;
      lazygit = true;
      gh = true;
      gh-dash = true;
      gitCredentialManager = true;
  };
  
  features.dev-tools = {
      enable = true;
      rust = true;
      haskell = true;
      json = true;
      python = true;
      xml = true;
      marksman = true;
      egglog = true;
      steel = true;
      mkcert = true;
      caddy = true;
  };

  suites.sixel-tools = {
      enable = true;
      chafa = true;
      catimg = true;
      mpv = true;
      ytdlp = true;
  };
  
  suites.gui-apps = lib.mkIf enableGuiDefaults {
      enable = true;

      # Lean common graphical baseline
      ghostty = true;
      librewolf = true;
      vscodium = true;
      keepassxc = true;
      drawio = true;
      zathura = true;
      ffmpeg = true;
  };

  suites.tui-apps = {
      enable = true;
      btop = true;
      gping = true;
      imagemagick = true;
      graphviz = true;
      zellij = true;
      lazygit = true;
      yazi = true;
  };

  suites.pim-apps = {
      enable = true;
      superproductivity = enableGuiDefaults;
  };

  features.bookokrat = {
      enable = true;
    };
   
  features.appimages = {
     enable = true;
  };

  programs.bash = {
      enable = true;
      initExtra = ''
        export GPG_TTY=$(tty 2>/dev/null || echo /dev/tty)

        if command -v github-copilot-cli > /dev/null; then
          eval "$(github-copilot-cli alias -- bash)"
        fi
      '';
  };
}
