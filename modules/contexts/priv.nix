# "priv" context bundle - personal Linux environment.
#
# Host-specific config doesn't require a dedicated per-host file in `dots`
# - it's expressed via dotsLocal fields (machine.*, gpu, compositor, ...),
# rules.nix, and (for truly bespoke needs)
# dotsLocal.extraModules. See memory-bank/preserved-features-checklist.md
# for the per-host migration notes.
{ pkgs, lib, dotsLocal, ... }:

let
  enableGuiDefaults = dotsLocal.enableGuiDefaults;
  graphicalBackend = dotsLocal.graphicalBackend;
in {

  imports = [
    # opener.nix/clipboard.nix/fonts.nix/ai-apps.nix are imported by
    # modules/composition.nix (see its comment for why) - only the
    # enable/backend/base config below is context-specific, not the
    # import itself.
    ../../modules/suites/sixel-tools.nix
    ../../modules/features/appimages.nix
    ../../modules/suites/pim-apps.nix
    ../../modules/features/bookokrat.nix
    ../../modules/features/quarkdown.nix
    ../../modules/suites/gui-apps.nix
    ../../modules/suites/tui-apps.nix
  ];

  features.opener = {
      enable = true;
      backend = graphicalBackend;
      alias = "o";
  };

  features.clipboard = {
    enable = true;
    backend = graphicalBackend;
  };

  # Common AI Apps configuration
  suites.ai-apps = {
    enable = true;
    opencode = true;
    grabcontext = true;
    # Default pi packages - hosts extend with ++ (via dotsLocal.extraModules
    # if truly needed; in practice every priv host currently just inherits
    # this list unmodified)
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
  };

  suites.network-tools = {
      enable = true;
      doggo = true;
      xh = true;
      rclone = true;
  };

  suites.git-tools = {
      enable = true;
      git = true;
      jj = true;
      delta = true;
      lazygit = true;
      gh = true;
      gh-dash = true;
      gitCredentialManager = true;
  };

  suites.dev-tools = {
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
      quarto = true;
      typst = true;
      pandoc = true;
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
