{ pkgs, lib, inputs, config, ... }: {
home.packages = with pkgs; [
    # --- 1. CORE UTILITIES (Pure CLI / Automation) ---
    # Fast, silent, and scriptable tools
    nh                    # Nix helper
    uv                    # Universal packaging
    ripgrep               # Fast search (rg)
    ripgrep-all           # even in PDFs
    fd                    # Fast find
    jq                    # JSON processor
    fx                    # JSON viewer
    nmap                  # Network mapper
    tree                  # Directory hierarchy
    gnupg                 # Encryption/Signing
    rsync                 # File transfer
    rclone                # File transfer (cloud edition)
    t3                    # Tree-like utility
    direnv                # Env loader
    nix-direnv            # Nix integration for direnv
    xh                    # HTTP client (modern)
    curl                  # HTTP client (classic)
    wget                  # File downloader
    curlie                # curl with jq-like output
        
    # --- 2. ENHANCED WORKFLOW (Modern Unix Replacements) ---
    # Tools that upgrade the interactive Bash experience
    bash                  # Updated Bash shell
    bash-completion       # Tab-completion logic
    bash-language-server  # Editing bash scripts from helix 
    starship              # Prompt engine
    moor                  # General pager
    ov                    # Pager for csv, tsv
    lsd                   # Next-gen 'ls'
    less                  # Standard pager
    bat                   # 'cat' with wings
    glow                  # Markdown renderer
    dust                  # 'du' replacement
    tokei                 # Code statistics
    fastfetch             # System info fetch
    procs                 # 'ps' replacement
    tailspin              # Log highlighter (tspin)
    tealdeer              # Fast 'tldr'
    difftastic            # Semantic diff tool
    doggo                 # DNS client (modern 'dig')
    vivid                 # LS_COLORS generator
    gum                   # Shell script TUI components
    fzf                   # Fuzzy finder
    zoxide                # Smarter 'cd'
    prettier              # Code formatter
     
    # --- 3. INTERACTIVE TUI (Full-Screen Interfaces) ---
    # Tools with persistent terminal UI/dashboards
    helix                 # Modern modal text editor
    marksman              # Markdown lsp
    external.snippets-ls  # Snippets LSP
    btop                  # Resource monitor
    pass                  # Password manager (TUI/CLI)
    pinentry-tty          # TTY-based pinentry for GPG
    # msgvault              # Search old email
  ];
  
  home.stateVersion = "23.11"; 
  programs.home-manager.enable = true;

  # --- TOOL CONFIGURATIONS ---
  programs.lsd = { 
    enable = true; 
    colors = "unthemed"; 
  };
  
  programs.zoxide = { 
    enable = true; 
    enableBashIntegration = true; 
    options = [ "--cmd cd" ]; 
  };
  
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    defaultCommand = "fd --type f";
    defaultOptions = [ "--height=40%" "--layout=reverse" "--border" ];
  };
  
  programs.bat = {
    enable = true;
    extraPackages = with pkgs.bat-extras; [
        batman
        batgrep
        batdiff
        batpipe
    ];
    config = { 
      theme = "TwoDark"; 
      italic-text = "always"; 
      style = "numbers,header,snip,changes"; 
    };
  };
  
  programs.direnv = { 
    enable = true; 
    nix-direnv.enable = true; 
  };
  
  programs.btop.settings = { 
    vim_keys = true; 
    proc_sorting = "cpu lazy"; 
    proc_cmdline = true; 
  };

  # --- BASH SETTINGS ---
  # These are the settings that the Flake's "Gutter Eval" will capture
  # and redirect into your .bashrc-nix file.
  programs.bash = {
    enable = true;
    enableCompletion = true;
    historySize = 50000;
    historyFileSize = 100000;
    historyControl = [ "ignoredups" "ignorespace" ];

    initExtra = ''
      if [[ "$TERM" == "linux" ]]; then
        export STARSHIP_CONFIG=~/.config/starship_minimal.toml
      else
        export STARSHIP_CONFIG=~/.config/starship.toml
      fi
      eval "$(starship init bash)"
    '';

    sessionVariables = {
      FZF_CTRL_T_OPTS = "--preview 'lsd -l --color=always {}'";
    };
    
    shellAliases = {
      "+" = "sudo -E env \"PATH=$PATH\" ";  
      apply = "apply-dots";
      ls = lib.mkForce "lsd --group-dirs first --git";
      ll = lib.mkForce "lsd --group-dirs first -l --git";
      la = lib.mkForce "lsd --group-dirs first -a --git";
      lt = lib.mkForce "lsd --tree --git";
    };
  };
}
