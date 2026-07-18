{ config, pkgs, inputs, lib, alien, ... }: 

let
  cfg = config.features.niri-noctalia;
  terminalFont = "IosevkaTerm NFM";
  uiFont = "Inter";
  
  # Determine if we're using alien packages
  useAlienNiri = alien.has "niri";
  useAlienNoctalia = alien.has "noctalia-shell";
  
  # Get noctalia package/binary path
  # For alien: use 'qs -c noctalia-shell' (noctalia-qs package provides 'qs' binary)
  # For nix: use the full path to noctalia-shell binary
  noctaliaPkg = if useAlienNoctalia then "noctalia-shell" else inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
  noctaliaBin = if useAlienNoctalia then "qs -c noctalia-shell" else "${noctaliaPkg}/bin/noctalia-shell";
  
  # Get niri package (use regular niri to avoid tuning conflicts).
  # Only referenced in the non-alien branch at the ExecStart site below, so
  # no conditional is needed here (previously: `if useAlienNiri then pkgs.niri
  # else pkgs.niri` - a dead/no-op conditional, both branches were identical).
  niriPkg = pkgs.niri;
in {
  # Import nix modules (always import, but conditionally enable)
  imports = [ inputs.niri.homeModules.niri inputs.noctalia.homeModules.default ];

  options.features.niri-noctalia = {
    enable = lib.mkEnableOption "Enable niri + noctalia desktop environment";
    
    terminal = lib.mkOption {
      type = lib.types.str;
      default = "ghostty";
      description = "Terminal emulator command to use (must be on PATH)";
    };

    terminalAppId = lib.mkOption {
      type = lib.types.str;
      default = "com.mitchellh.ghostty";
      description = "App ID of the terminal emulator for window tracking";
    };

    terminalScratchpadSuffix = lib.mkOption {
      type = lib.types.str;
      default = "scratchpad";
      description = "Suffix appended to app-id for scratchpad windows";
    };

    renderDrmDevice = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Path to DRM render device for niri debug configuration (e.g., /dev/dri/by-path/...)";
    };

    configText = lib.mkOption {
      type = lib.types.str;
      default = ''
        // --- NIRI STARTUP ---

        // Noctalia (GTK/quickshell)
        spawn-sh-at-startup "${noctaliaBin}"

        // User Apps
        spawn-at-startup "keepassxc"
        spawn-at-startup "nm-applet" "--indicator"
        // spawn-at-startup "${cfg.terminal}"
      
        // Initialization
        spawn-sh-at-startup "niri msg action focus-workspace hidden && niri msg action focus-workspace 1"
      
        input {
          keyboard {
            xkb {
              layout "us,de"
            }
          }
          touchpad {
            tap
            natural-scroll
            accel-speed 0.2
            scroll-method "two-finger"
          }
          focus-follows-mouse
          warp-mouse-to-focus
        }

        debug {
            honor-xdg-activation-with-invalid-serial
            ${lib.optionalString (cfg.renderDrmDevice != null) ''render-drm-device "${cfg.renderDrmDevice}"''}
        }      
      
        layout {
          gaps 16
          struts { left 0; right 0; top 0; bottom 0; }
          center-focused-column "never"
          default-column-width { proportion 0.5; }
          
          focus-ring {
            width 1
            active-gradient from="#7aa2f7" to="#bb9af7" angle=45
            inactive-color "#414868"
          }

          border { off; }

          shadow {
            on
            softness 30
            spread 2
            offset x=0 y=4
            color "rgba(0, 0, 0, 0.5)"
            inactive-color "rgba(0, 0, 0, 0.3)"
          }

          preset-column-widths {
            proportion 0.25
            proportion 0.33
            proportion 0.5
            proportion 0.66
            proportion 0.75
          }
        }

        animations {
          window-open { duration-ms 250; curve "ease-out-quad"; }
          window-close { duration-ms 250; curve "ease-out-expo"; }
          horizontal-view-movement { spring damping-ratio=0.8 stiffness=350 epsilon=0.0001; }
          workspace-switch { spring damping-ratio=1.0 stiffness=450 epsilon=0.0001; }
          window-movement { spring damping-ratio=1.0 stiffness=600 epsilon=0.0001; }
          window-resize { spring damping-ratio=1.0 stiffness=500 epsilon=0.0001; }
        }

        hotkey-overlay {
          skip-at-startup
        }
                 
        overview {
          zoom 0.42
          backdrop-color "rgba(0, 0, 0, 0.5)"
        }

        layer-rule {
          match namespace="^launcher$"
          baba-is-float true
        }
      
        layer-rule {
          match namespace="^ghostty-scratchpad.*"
          baba-is-float true          
        }   
         
        layer-rule {
          match namespace="^noctalia-.*"
        }   
           
        layer-rule {
          match namespace=".*"
          geometry-corner-radius 12
          shadow { on; }
        }

        window-rule {
          geometry-corner-radius 12
          clip-to-geometry true      
        }

        window-rule {
          match app-id="launcher"
          default-window-height { proportion 0.4; }
        }

        window-rule {
          match app-id="^com\\.mitchellh\\.ghostty\\.scratchpad$"
          open-floating true
          block-out-from "screen-capture"
          default-column-width { proportion 0.8; }
          default-window-height { proportion 0.6; }
        }
      
        window-rule {
          match is-floating=true
          shadow {
            on
            softness 60
            spread 10
            offset x=0 y=12
            color "rgba(0, 0, 0, 0.66)"
          }
        }

        window-rule {
          match is-active=false
          opacity 0.9
          border {
            on
            width 1
            active-color "rgba(122, 162, 247, 0.3)"
          }
        }
      
        window-rule {
          match is-active=true
          border {
            on
            width 2
            active-color "#7aa2f7"
          }
        }

        window-rule {
          match app-id="com.mitchellh.ghostty"
          draw-border-with-background false
        }

        window-rule {
          match app-id="^org.keepassxc.KeePassXC$"
          open-on-workspace "pass"
          open-maximized false
          block-out-from "screen-capture"
        }
      
        binds {
          "Mod+Comma" { spawn "sh" "-c" "${noctaliaBin} ipc call plugin:keybind-cheatsheet toggle"; }
          "Mod+Shift+Comma" { show-hotkey-overlay; }
          
          "Mod+Return" { spawn "sh" "-c" "env NIXON=1 ${cfg.terminal} -e bash -l"; }
          "Mod+Alt+Return" { spawn "${cfg.terminal}"; }
          
          "Mod+Shift+Return" { spawn "sh" "-c" "env NIXON=1 $HOME/.nix-profile/bin/terminal-in-current-column -e bash -l"; }
          "Mod+Shift+Alt+Return" { spawn "$HOME/.nix-profile/bin/terminal-in-current-column"; }
          
          "Mod+Grave" { spawn "$HOME/.nix-profile/bin/terminal-scratchpad-toggle"; }
          
          "Mod+Shift+C" { spawn "sh" "-l" "-c" "niri msg action center-column"; }
          "Mod+D" { spawn "sh" "-c" "${noctaliaBin} ipc call launcher toggle"; }          
          "Mod+S" { spawn "sh" "-c" "${noctaliaBin} ipc call controlCenter toggle"; }
          "Mod+M" { spawn "sh" "-c" "wdisplays"; }
          "Mod+Q" { close-window; }
          "Mod+Shift+E" { quit; }

          "Mod+H" { focus-column-or-monitor-left; }
          "Mod+L" { focus-column-or-monitor-right; }
          "Mod+J" { focus-workspace-down; }
          "Mod+K" { focus-workspace-up; }
             
          "Mod+Shift+H" { move-column-left-or-to-monitor-left; }
          "Mod+Shift+L" { move-column-right-or-to-monitor-right; }
          "Mod+Shift+J" { move-window-to-workspace-down; }
          "Mod+Shift+K" { move-window-to-workspace-up; }
             
          "Mod+Alt+J" { focus-window-or-monitor-down; }
          "Mod+Alt+K" { focus-window-or-monitor-up; }
             
          "Mod+Ctrl+J" { move-window-down; }
          "Mod+Ctrl+K" { move-window-up; }
                 
          "Mod+Tab" { toggle-overview; }
          "Mod+F" { maximize-column; }
          "Mod+Shift+F" { fullscreen-window; }
          "Mod+C" { center-column; }
          "Mod+V" { toggle-window-floating; }
          "Mod+Space" { switch-layout "next"; }
          "Mod+BracketLeft" { consume-or-expel-window-left; }
          "Mod+BracketRight" { consume-or-expel-window-right; }
          "Mod+Ctrl+P" { screenshot-screen; }
          "Mod+Alt+P" { screenshot-window; }

          "XF86AudioRaiseVolume" { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.02+"; }
          "XF86AudioLowerVolume" { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.02-"; }
          "XF86AudioMute" { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
          "XF86MonBrightnessUp" { spawn "brightnessctl" "set" "10%+"; }
          "XF86MonBrightnessDown" { spawn "brightnessctl" "set" "10%-"; }

          "Mod+R" { switch-preset-column-width; }
          "Mod+Minus" { set-column-width "-10%"; }
          "Mod+Equal" { set-column-width "+10%"; }
          "Mod+Shift+Minus" { set-window-height "-10%"; }
          "Mod+Shift+Equal" { set-window-height "+10%"; }

          "Mod+1" { focus-workspace 1; }
          "Mod+2" { focus-workspace 2; }
          "Mod+3" { focus-workspace 3; }
          "Mod+4" { focus-workspace 4; }
          "Mod+Shift+1" { spawn "sh" "-c" "niri msg action move-window-to-workspace 1 && niri msg action focus-workspace 1"; }
          "Mod+Shift+2" { spawn "sh" "-c" "niri msg action move-window-to-workspace 2 && niri msg action focus-workspace 2"; }
          "Mod+Shift+3" { spawn "sh" "-c" "niri msg action move-window-to-workspace 3 && niri msg action focus-workspace 3"; }
          "Mod+Shift+4" { spawn "sh" "-c" "niri msg action move-window-to-workspace 4 && niri msg action focus-workspace 4"; }
                  
          "Mod+Alt+1" { focus-monitor "0"; }
          "Mod+Alt+2" { focus-monitor "1"; }
          "Mod+Alt+3" { focus-monitor "2"; }
          "Mod+Alt+4" { focus-monitor "3"; }
        
          "Mod+Alt+Shift+1" { move-column-to-monitor "0"; }
          "Mod+Alt+Shift+2" { move-column-to-monitor "1"; }          
          "Mod+Alt+Shift+3" { move-column-to-monitor "2"; }          
          "Mod+Alt+Shift+4" { move-column-to-monitor "3"; }    
          
          "Mod+WheelScrollDown"      { focus-column-right; }
          "Mod+WheelScrollUp"        { focus-column-left; }
          "Mod+Ctrl+WheelScrollDown" { move-column-right; }
          "Mod+Ctrl+WheelScrollUp"   { move-column-left; }  
          
          "Mod+Alt+H" { focus-monitor-left; }
          "Mod+Alt+L" { focus-monitor-right; }

          "Mod+Alt+Shift+H" { spawn "sh" "-c" "niri msg action move-column-to-monitor-left && niri msg action focus-monitor-left"; }
          "Mod+Alt+Shift+L" { spawn "sh" "-c" "niri msg action move-column-to-monitor-right && niri msg action focus-monitor-right"; }
           
          "Mod+N" { spawn "sh" "-c" "${noctaliaBin} ipc call plugin:notifications toggle"; }
          "Mod+0" { spawn "sh" "-c" "${noctaliaBin} ipc call plugin:power-menu toggle"; } 
        }
      '';
      description = "Niri configuration (KDL format)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Declare alien packages as enabled (both are always enabled when feature is on)
    alienPackages.enabledPackages = [ "niri" "noctalia-shell" ];

    # Systemd service files - use correct niri binary
    home.file.".config/systemd/user/niri.service".text = ''
      [Unit]
      Description=A scrollable-tiling Wayland compositor
      BindsTo=graphical-session.target
      Before=graphical-session.target
      Wants=graphical-session-pre.target
      After=graphical-session-pre.target

      Wants=xdg-desktop-autostart.target
      Before=xdg-desktop-autostart.target

      [Service]
      Slice=session.slice
      Type=notify
      ExecStart=${if useAlienNiri then "/usr/bin/niri" else "${niriPkg}/bin/niri"} --session

      [Install]
      WantedBy=default.target
    '';
    
    home.file.".config/systemd/user/niri-shutdown.target".text = ''
      [Unit]
      Description=Shutdown Niri
      DefaultDependencies=false
      After=graphical-session.target
    '';

    # Always write niri config directly (never use programs.niri)
    home.file.".config/niri/config.kdl" = {
      text = cfg.configText;
    };

    # Helper scripts
    home.packages = [
      (pkgs.writeShellScriptBin "terminal-in-current-column" ''
        #!/bin/sh
        set -eu

        term="${cfg.terminal}"
        appid="${cfg.terminalAppId}"
        py="${pkgs.python3}/bin/python3"

        old_id="$(niri msg -j focused-window | "$py" -c 'import sys,json; print(json.load(sys.stdin).get("id",""))')"

        "$term" "$@" >/dev/null 2>&1 &

        i=0
        while [ $i -lt 80 ]; do
          fw="$(niri msg -j focused-window 2>/dev/null || true)"
          new_id="$(printf %s "$fw" | "$py" -c 'import sys,json; d=json.load(sys.stdin); print(d.get("id",""))')"
          app_id="$(printf %s "$fw" | "$py" -c 'import sys,json; d=json.load(sys.stdin); print(d.get("app_id",""))')"

          if [ -n "$new_id" ] && [ "$new_id" != "$old_id" ] && [ "$app_id" = "$appid" ]; then
            break
          fi

          i=$((i + 1))
          sleep 0.025
        done

        niri msg action consume-or-expel-window-left >/dev/null 2>&1 || true
      '')
      
      (pkgs.writeShellScriptBin "terminal-scratchpad-toggle" ''
        #!/bin/sh
        set -eu

        term="${cfg.terminal}"
        appid="${cfg.terminalAppId}"
        scratch_suffix="${cfg.terminalScratchpadSuffix}"
        scratch_app_id="${cfg.terminalAppId}.${cfg.terminalScratchpadSuffix}"
        zellij="${pkgs.zellij}/bin/zellij"
        py="${pkgs.python3}/bin/python3"
        session_name="scratchpad"

        # Ensure zellij session exists (create detached if not)
        if ! "$zellij" list-sessions 2>/dev/null | grep -q "^$session_name "; then
          nohup env TERM="xterm-256color" "$zellij" --session "$session_name" </dev/null >/dev/null 2>&1 &
          sleep 0.5
        fi

        # Find existing scratchpad window
        win_json="$(niri msg -j windows 2>/dev/null | "$py" -c 'import sys,json; wins=json.load(sys.stdin); s=[w for w in wins if w.get("app_id")=="'"$scratch_app_id"'"]; print(json.dumps(s[-1]) if s else "")')" || true

        if [ -n "$win_json" ]; then
          win_id="$(printf %s "$win_json" | "$py" -c 'import sys,json; print(json.load(sys.stdin).get("id",""))')"
          is_focused="$(printf %s "$win_json" | "$py" -c 'import sys,json; print("1" if json.load(sys.stdin).get("is_focused") else "0")')"
          win_pid="$(printf %s "$win_json" | "$py" -c 'import sys,json; print(json.load(sys.stdin).get("pid",""))')"

          if [ "$is_focused" = "1" ]; then
            kill "$win_pid" 2>/dev/null || true
            exit 0
          fi

          target_ws_idx="$(niri msg -j workspaces 2>/dev/null | "$py" -c 'import sys,json; ws=[w for w in json.load(sys.stdin) if w.get("is_focused")]; print(str(ws[0].get("idx","")) if ws else "")')" || target_ws_idx=""
          
          niri msg action focus-window --id "$win_id" 2>/dev/null || true
          if [ -n "$target_ws_idx" ]; then
            niri msg action move-window-to-workspace "$target_ws_idx" 2>/dev/null || true
          fi
          exit 0
        fi

        "$term" --class="$scratch_app_id" -e "$zellij" attach "$session_name" >/dev/null 2>&1 &
      '')
      
      (pkgs.writeShellScriptBin "start-xwayland-satellite" ''
        #!/bin/sh
        set -eu

        display=":0"
        sock="/tmp/.X11-unix/X0"

        "${pkgs.xwayland-satellite}/bin/xwayland-satellite" "$display" &
        sat_pid=$!

        ready=0
        i=0
        while [ $i -lt 200 ]; do
          if [ -S "$sock" ] && DISPLAY="$display" ${pkgs.xlsclients}/bin/xlsclients >/dev/null 2>&1; then
            ready=1
            break
          fi
          i=$((i + 1))
          sleep 0.05
        done

        if command -v systemctl >/dev/null 2>&1; then
          if [ "$ready" -eq 1 ]; then
            systemctl --user set-environment DISPLAY="$display" >/dev/null 2>&1 || true
          fi
        fi

        wait "$sat_pid"
      '')
      
      (pkgs.writeShellScriptBin "wait-for-x11" ''
        #!/bin/sh
        set -eu

        display=":0"
        sock="/tmp/.X11-unix/X0"

        i=0
        while [ $i -lt 200 ]; do
          if [ -S "$sock" ] && DISPLAY="$display" ${pkgs.xlsclients}/bin/xlsclients >/dev/null 2>&1; then
            break
          fi
          i=$((i + 1))
          sleep 0.05
        done

        export DISPLAY="$display"
        exec "$@"
      '')
    ];

    # GTK/Qt theming - commented out, not niri/noctalia specific
    # gtk = {
    #   enable = true;
    #   theme = {
    #     name = "Adwaita-dark";
    #     package = pkgs.gnome-themes-extra;
    #   };
    #   gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    #   gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
    # };

    # qt = {
    #   enable = true;
    #   platformTheme.name = "gtk";
    #   style.name = "adwaita-dark";
    # };
    
    # home.sessionVariables = {
    #   GTK_THEME = "Adwaita-dark";
    # };

    # Launch script - uses niri-session with systemd service
    # Use this when running from a display manager (SDDM, GDM, etc.)
    home.file.".local/bin/niri-launch-systemd" = {
      executable = true;
      text = ''
        #!/bin/sh
        ${if useAlienNiri then "exec niri-session" else "exec nixexec niri-session"} "$@"
      '';
    };
    
    # Direct launch script - runs niri directly without systemd service
    # Use this from TTY (multi-user.target) - bypasses Type=notify deadlock
    home.file.".local/bin/niri-launch-direct" = {
      executable = true;
      text = ''
        #!/bin/sh
        # Run niri directly without systemd service (bypasses Type=notify deadlock)
        
        # Import minimal environment
        export XDG_SESSION_TYPE=wayland
        export XDG_CURRENT_DESKTOP=niri
        
        # Update D-Bus
        if command -v dbus-update-activation-environment >/dev/null 2>&1; then
            dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE 2>/dev/null || true
        fi
        
        # Run niri directly with optional debug logging
        if [ "$1" = "--debug" ]; then
            shift
            exec niri --session 2>&1 | tee /tmp/niri-direct.log
        else
            exec niri --session "$@"
        fi
      '';
    };
  };
}
