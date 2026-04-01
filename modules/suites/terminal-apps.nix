{ config, lib, pkgs, inputs, alien, ... }:

let
  cfg = config.suites.terminal-apps;
in
{
  options.suites.terminal-apps = {
    enable = lib.mkEnableOption "Enable terminal apps";

    ghostty = lib.mkEnableOption "Ghostty terminal";
    wezterm = lib.mkEnableOption "WezTerm terminal emulator";
    zellij = lib.mkEnableOption "Zellij terminal multiplexer";
    lazygit = lib.mkEnableOption "Lazygit";
    yazi = lib.mkEnableOption "Yazi file manager";
  };

  config = lib.mkIf cfg.enable {
    home.packages = builtins.filter (p: p != null) [
      (alien.mkEntry cfg.ghostty "ghostty" pkgs.ghostty)
      (alien.mkEntry cfg.wezterm "wezterm" pkgs.wezterm)
      (alien.mkEntry cfg.zellij "zellij" pkgs.zellij)
      (alien.mkEntry cfg.lazygit "lazygit" pkgs.lazygit)
      (alien.mkEntry cfg.yazi "yazi" pkgs.yazi)
    ];

    programs.ghostty = lib.mkIf cfg.ghostty {
      enable = true;
      enableBashIntegration = true;
    };

    # Ghostty configuration (for both alien and non-alien)
    home.file.".config/ghostty/config.ghostty" = lib.mkIf cfg.ghostty {
      force = true;
      text = ''
        # --- Firewatch Theme Colors ---
        background = #1a1a1c
        foreground = #bebebe
        selection-background = #3c3c3c
        selection-foreground = #ffffff
        cursor-color = #e27878

        # Palette
        palette = 0=#1a1a1c
        palette = 1=#e27878
        palette = 2=#b4be82
        palette = 3=#e0af68
        palette = 4=#84a0c6
        palette = 5=#a093c7
        palette = 6=#89b8c2
        palette = 7=#c0caf5
        palette = 8=#3e3e40
        palette = 9=#e98989
        palette = 10=#c0ca8e
        palette = 11=#e9b978
        palette = 12=#91accf
        palette = 13=#aca1d3
        palette = 14=#93c4d1
        palette = 15=#d0d0d0

        # --- Font Configuration ---
        font-family = "IosevkaTerm NFM Light"
        font-family-bold = "IosevkaTerm NFM Medium"
        font-family-italic = "IosevkaTerm NFM Light Obl"
        font-family-bold-italic = "IosevkaTerm NFM Medium Obl"
        font-size = 13

        # --- UI Settings ---
        cursor-style-blink = false
        adjust-cursor-thickness = 1
        window-step-resize = true
        window-decoration = false
        shell-integration = detect
        focus-follows-mouse = true
        copy-on-select = true
        term = xterm-256color

        # --- Visual Polish (Niri 25.08) ---
        background-opacity = 0.78
        background-blur = 10
        unfocused-split-opacity = 0.85
      '';
    };

    # WezTerm configuration
    programs.wezterm = lib.mkIf cfg.wezterm {
      enable = true;
      package = pkgs.wezterm;
      extraConfig = ''
        local wezterm = require "wezterm"

        return {
          -- Font fallback with absolute path (ensure font is installed correctly)
          font = wezterm.font_with_fallback {
            "/home/pc0w/.nix-profile/share/fonts/truetype/NerdFonts/IosevkaTerm/IosevkaTermNerdFont-Regular.ttf",
            "JetBrains Mono"  -- Fallback font
          },
          font_size = 12.0,

          -- Tabs and window settings
          enable_tab_bar = true,
          hide_tab_bar_if_only_one_tab = false,
          use_fancy_tab_bar = true,
          window_decorations = "RESIZE",

          -- Transparency settings
          window_background_opacity = 0.85,  -- background opacity
          text_background_opacity = 0.85,    -- text opacity

          -- Dimming for inactive panes while maintaining transparency
          inactive_pane_hsb = {
            brightness = 0.75,  -- Dimming inactive panes to 75%
            saturation = 0.8,   -- Slightly reduce saturation
            hue = 1.0,          -- Keep hue intact
          },

          -- Color scheme settings
          color_schemes = {
            Firewatch = {
              background = "#1F1F28",
              foreground = "#C5C8C6",
            }
          },
          color_scheme = "Firewatch",

          -- Wayland support and other tweaks
          enable_wayland = true,
          scrollback_lines = 3500,
          enable_scroll_bar = false,
        }
      '';
    };

    # Zellij multiplexer configuration
    programs.zellij = lib.mkIf cfg.zellij {
      enable = true;
    };

    # Zellij config (for both alien and non-alien)
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
    
    # Compact layout - minimal bar at top, help at bottom right
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

    # Show help when opening shell in zellij
    programs.bash.initExtra = lib.mkIf cfg.zellij ''
      if [ -n "$ZELLIJ" ] && [ -z "$ZELLIJ_HELP_SHOWN" ]; then
        export ZELLIJ_HELP_SHOWN=1
        echo -e '\033[1m\033[35m ctrl-o a / ctrl-o h / ctrl-g\033[0m'
      fi
    '';

    # Lazygit configuration
    programs.lazygit = lib.mkIf cfg.lazygit {
      enable = true;
    };
    
    # Declare which alien packages are enabled
    alienPackages.enabledPackages = 
      (lib.optional cfg.ghostty "ghostty") ++
      (lib.optional cfg.wezterm "wezterm") ++
      (lib.optional cfg.zellij "zellij") ++
      (lib.optional cfg.lazygit "lazygit") ++
      (lib.optional cfg.yazi "yazi");
  };
}
