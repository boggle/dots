{ config, lib, pkgs, inputs, alien, ... }:

let
  cfg = config.suites.tui-apps;
  coreLib = import ../core/lib.nix { inherit lib; };
  appSet = coreLib.mkAppSet {
    inherit alien;
    apps = {
      # Core TUI apps
      btop = { enable = cfg.btop; pkg = pkgs.btop; };
      zellij = { enable = cfg.zellij; pkg = pkgs.zellij; };
      lazygit = { enable = cfg.lazygit; pkg = pkgs.lazygit; };
      yazi = { enable = cfg.yazi; pkg = pkgs.yazi; };
      pass = { enable = cfg.pass; pkg = pkgs.pass; };
      bandwhich = { enable = cfg.bandwhich; pkg = pkgs.bandwhich; };
      vhs = { enable = cfg.vhs; pkg = pkgs.vhs; };
      tailspin = { enable = cfg.tailspin; pkg = pkgs.tailspin; };

      # Email
      aerc = { enable = cfg.aerc; pkg = pkgs.aerc; };
      deltachat = { enable = cfg.deltachat; pkg = pkgs.deltachat-desktop; alienName = "deltachat-desktop"; };

      # DTP
      imagemagick = { enable = cfg.imagemagick; pkg = pkgs.imagemagick; };
      graphviz = { enable = cfg.graphviz; pkg = pkgs.graphviz; };
      pandoc = { enable = cfg.pandoc; pkg = pkgs.pandoc; };
      typst = { enable = cfg.typst; pkg = pkgs.typst; };

      # Network/Utils
      gping = { enable = cfg.gping; pkg = pkgs.gping; };

      # Social/Utils
      posting = { enable = cfg.posting; pkg = pkgs.posting; };
      frogmouth = { enable = cfg.frogmouth; pkg = pkgs.frogmouth; };
      hledger = { enable = cfg.hledger; pkg = pkgs.hledger; };
    };
  };
in
{
  options.suites.tui-apps = {
    enable = lib.mkEnableOption "Enable interactive TUI tools" // { default = true; };

    btop = lib.mkEnableOption "btop - system monitor";
    zellij = lib.mkEnableOption "Zellij terminal multiplexer";
    lazygit = lib.mkEnableOption "Lazygit";
    yazi = lib.mkEnableOption "Yazi file manager";
    pass = lib.mkEnableOption "pass (password manager)";
    bandwhich = lib.mkEnableOption "bandwhich - network monitor";
    vhs = lib.mkEnableOption "vhs - terminal recorder";
    tailspin = lib.mkEnableOption "tailspin (tspin) - log file highlighter";

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
    home.packages = appSet.packages;

    programs.btop = lib.mkIf cfg.btop {
      settings = {
        vim_keys = true;
        proc_sorting = "cpu lazy"; 
        proc_cmdline = true;
      };      
    };

    # NOTE: no `programs.zellij.enable = true;` here (deliberately) - it
    # would only re-add `pkgs.zellij` to home.packages a second time
    # (already provided above via `appSet`/`alien.mkEntry`, alien-aware),
    # since `cfg.settings`/`cfg.extraConfig` are never touched (the KDL
    # config below is written directly via `home.file`, not through the
    # module), and no shell integration is enabled - `programs.zellij`
    # would genuinely do nothing else for us here. Confirmed via reading
    # home-manager's own zellij.nix module source.
    home.file.".config/zellij/config.kdl" = lib.mkIf cfg.zellij {
      force = true;
      text = ''
        // Minimal UI settings
        show_startup_tips false
        show_release_notes false
        pane_frames false
        simplified_ui true
        
        // Use compact status bar instead of full button bar
        // The compact-bar shows just the current mode and help hint
        default_layout "compact"
        
        // Theme - Tokyo Night Storm (blue/purple compatible)
        theme "tokyo-night-storm"
        
        themes {
          tokyo-night-storm {
            text_unselected {
              base 169 177 214
              background 36 40 59
              emphasis_0 255 158 100
              emphasis_1 130 170 255
              emphasis_2 187 154 247
              emphasis_3 42 195 222
            }
            text_selected {
              base 192 202 245
              background 65 72 104
              emphasis_0 255 158 100
              emphasis_1 130 170 255
              emphasis_2 187 154 247
              emphasis_3 42 195 195
            }
            ribbon_unselected {
              base 122 162 247
              background 41 46 66
              emphasis_0 255 158 100
              emphasis_1 130 170 255
              emphasis_2 187 154 247
              emphasis_3 42 195 195
            }
            ribbon_selected {
              base 36 40 59
              background 122 162 247
              emphasis_0 255 158 100
              emphasis_1 192 202 245
              emphasis_2 187 154 247
              emphasis_3 42 195 195
            }
            frame_unselected {
              base 86 95 137
              background 36 40 59
              emphasis_0 255 158 100
              emphasis_1 130 170 255
              emphasis_2 187 154 247
              emphasis_3 42 195 222
            }
            frame_selected {
              base 122 162 247
              background 36 40 59
              emphasis_0 255 158 100
              emphasis_1 192 202 245
              emphasis_2 187 154 247
              emphasis_3 42 195 195
            }
            frame_highlight {
              base 187 154 247
              background 36 40 59
              emphasis_0 255 158 100
              emphasis_1 192 202 245
              emphasis_2 187 154 247
              emphasis_3 42 195 195
            }
          }
        }
        
        // UI configuration
        ui {
          pane_frames {
            hide_session_name false
            rounded_corners true
          }
        }
        
        // Keybindings - Ctrl+o for session mode, then a or h for help
        keybinds {
          shared_except "locked" {
            bind "Ctrl o" { SwitchToMode "Session"; }
          }
          session {
            bind "Ctrl o" { SwitchToMode "Normal"; }
            bind "a" {
              // Open about plugin (navigate to Help tab with arrow keys)
              LaunchOrFocusPlugin "zellij:about" {
                floating true
                move_to_focused_tab true
              }
              SwitchToMode "Normal"
            }
            bind "h" {
              // Show zellij config in a new pane to the right
              Run "sh" "-c" "zellij setup --dump-config | bat --style=plain" {
                direction "Right"
                close_on_exit true
              }
              SwitchToMode "Normal"
            }

          }
        }
      '';
    };

    home.file.".config/zellij/layouts/compact.kdl" = lib.mkIf cfg.zellij {
      force = true;
      text = ''
        layout {
          default_tab_template {
            // Top: compact bar (as plugin intends)
            pane size=1 borderless=true {
              plugin location="zellij:compact-bar"
            }
            children

          }
        }
      '';
    };

    programs.bash.initExtra = lib.mkIf cfg.zellij ''
      if [ -n "$ZELLIJ" ] && [ -z "$ZELLIJ_HELP_SHOWN" ]; then
        export ZELLIJ_HELP_SHOWN=1
        echo -e '\033[1m\033[35m ctrl-o a / ctrl-o h / ctrl-g\033[0m'
      fi
    '';

    # NOTE: no `programs.lazygit.enable = true;` here (deliberately) -
    # `lazygit` has no `settings`/shell-integration set anywhere in this
    # file, so the module would do nothing except re-add `pkgs.lazygit`
    # to home.packages a second time (already provided above via
    # `appSet`/`alien.mkEntry`, alien-aware). Confirmed via reading
    # home-manager's own lazygit.nix module source.

    # Declare alien packages for this suite
    alienPackages.enabledPackages = appSet.alienEnabled;
  };
}
