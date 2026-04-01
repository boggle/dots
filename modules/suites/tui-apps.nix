{ config, lib, pkgs, inputs, alien, ... }:

let
  cfg = config.suites.tui-apps;
in
{
  options.suites.tui-apps = {
    enable = lib.mkEnableOption "Enable interactive TUI tools";

    btop = lib.mkEnableOption "btop - system monitor";
    bandwhich = lib.mkEnableOption "bandwhich - network monitor";
    vhs = lib.mkEnableOption "vhs - terminal recorder";
    fresh = lib.mkEnableOption "fresh-editor - interactive editor";

    # Email
    aerc = lib.mkEnableOption "aerc (terminal email client)";
    deltachat = lib.mkEnableOption "DeltaChat (Delta Chat)";

    # DTP
    imagemagick = lib.mkEnableOption "ImageMagick";
    graphviz = lib.mkEnableOption "Graphviz";
    pandoc = lib.mkEnableOption "Pandoc";
    typst = lib.mkEnableOption "Typst";

    # Network/Utils
    gping = lib.mkEnableOption "gping (ping with graph)";

    # Social/Utils
    posting = lib.mkEnableOption "posting (API client)" // { default = true; };
    frogmouth = lib.mkEnableOption "frogmouth (Markdown viewer)" // { default = true; };
    hledger = lib.mkEnableOption "hledger (accounting)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = builtins.filter (p: p != null) [
      # Core TUI apps
      (alien.mkEntry cfg.btop "btop" pkgs.btop)
      (alien.mkEntry cfg.bandwhich "bandwhich" pkgs.bandwhich)
      (alien.mkEntry cfg.vhs "vhs" pkgs.vhs)
      (alien.mkEntry cfg.fresh "fresh-editor" pkgs.fresh-editor)

      # Email
      (alien.mkEntry cfg.aerc "aerc" pkgs.aerc)
      (alien.mkEntry cfg.deltachat "deltachat-desktop" pkgs.deltachat-desktop)

      # DTP
      (alien.mkEntry cfg.imagemagick "imagemagick" pkgs.imagemagick)
      (alien.mkEntry cfg.graphviz "graphviz" pkgs.graphviz)
      (alien.mkEntry cfg.pandoc "pandoc" pkgs.pandoc)
      (alien.mkEntry cfg.typst "typst" pkgs.typst)

      # Network/Utils
      (alien.mkEntry cfg.gping "gping" pkgs.gping)

      # Social/Utils
      (alien.mkEntry cfg.posting "posting" pkgs.posting)
      (alien.mkEntry cfg.frogmouth "frogmouth" pkgs.frogmouth)
      (alien.mkEntry cfg.hledger "hledger" pkgs.hledger)
    ];

    programs.btop = lib.mkIf cfg.btop {
      settings = {
        vim_keys = true;
        proc_sorting = "cpu lazy"; 
        proc_cmdline = true;
      };      
    };

    # Declare alien packages for this suite
    alienPackages.enabledPackages = 
      (lib.optional cfg.btop "btop") ++
      (lib.optional cfg.bandwhich "bandwhich") ++
      (lib.optional cfg.vhs "vhs") ++
      (lib.optional cfg.fresh "fresh-editor") ++
      (lib.optional cfg.aerc "aerc") ++
      (lib.optional cfg.deltachat "deltachat-desktop") ++
      (lib.optional cfg.imagemagick "imagemagick") ++
      (lib.optional cfg.graphviz "graphviz") ++
      (lib.optional cfg.pandoc "pandoc") ++
      (lib.optional cfg.typst "typst") ++
      (lib.optional cfg.gping "gping") ++
      (lib.optional cfg.posting "posting") ++
      (lib.optional cfg.frogmouth "frogmouth") ++
      (lib.optional cfg.hledger "hledger");
  };
}
