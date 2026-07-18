# Triomino Machine Configuration
# Machine-specific hardware and settings for the triomino WSL2 host

{ config, pkgs, lib, ... }:

{
    
  imports = [
    ../../../modules/features/sd-switch.nix
  ];
  
  home.packages = with pkgs; [ 
    # inputs.nixgl.packages.x86_64-linux.nixGLNvidia
    bluez
    localsend
  ];

  # WSL2/WSLg compatibility
  home.sessionVariables = {
    WAYLAND_DISPLAY = lib.mkDefault "wayland-0";
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent.socket";
    DIRENV_LOG_FORMAT = "";
  };

  xdg.configFile."direnv/direnvrc".text = ''
    log_status() {
      printf "\033[32mdirenv: %s\033[0m\n" "$*" >&2
    }
  '';

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
      pi = true;
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
  
  programs.ssh = {
    settings."*" = {
      IdentityFile = "~/.ssh/id_github_triomino";
      AddKeysToAgent = "yes";
    };
  };

  programs.zoxide.enableBashIntegration = lib.mkForce false;
  programs.direnv.enableBashIntegration = lib.mkForce false;

  programs.bash.initExtra = lib.mkOrder 999999 ''
    if command -v direnv >/dev/null 2>&1; then
      eval "$(direnv hook bash)"
    fi

    if [[ "$TERM_PROGRAM" == "vscode" ]]; then
      if [[ "$(declare -p PROMPT_COMMAND 2>/dev/null)" == "declare -a"* ]]; then
        _pc=()
        for _cmd in "''${PROMPT_COMMAND[@]}"; do
          if [[ "$_cmd" != "starship_precmd" ]] && [[ -n "$_cmd" ]]; then
            _pc+=("$_cmd")
          fi
        done
        PROMPT_COMMAND=("''${_pc[@]}")
        unset _pc _cmd
        if [[ "''${#PROMPT_COMMAND[@]}" -eq 0 ]]; then
          unset PROMPT_COMMAND
        fi
      elif [[ -n "''${PROMPT_COMMAND:-}" ]]; then
        PROMPT_COMMAND="''${PROMPT_COMMAND//starship_precmd;/}"
        PROMPT_COMMAND="''${PROMPT_COMMAND//;starship_precmd/}"
        PROMPT_COMMAND="''${PROMPT_COMMAND//starship_precmd/}"
        PROMPT_COMMAND="''${PROMPT_COMMAND#;}"
        PROMPT_COMMAND="''${PROMPT_COMMAND%;}"
        if [[ -z "$PROMPT_COMMAND" ]]; then
          unset PROMPT_COMMAND
        fi
      fi
      unset -f starship_precmd 2>/dev/null || true

      vscode_script=""
      newest_time=0

      for script in "$HOME"/.vscode-server/bin/*/out/vs/workbench/contrib/terminal/browser/media/shellIntegration-bash.sh; do
        if [ -f "$script" ]; then
          script_time=$(stat -c %Y "$script" 2>/dev/null || stat -f %m "$script" 2>/dev/null || echo 0)
          if [ "$script_time" -gt "$newest_time" ]; then
            newest_time="$script_time"
            vscode_script="$script"
          fi
        fi
      done

      if [ -n "$vscode_script" ]; then
        . "$vscode_script"
      fi

      export PS1='\[\e[34m\]\u@\h\[\e[0m\]:\[\e[32m\]\w\[\e[0m\]\$ '

      unset vscode_script newest_time script_time script
    fi

    if command -v zoxide >/dev/null 2>&1; then
      eval "$(zoxide init bash --cmd cd)"
    fi
  '';
  
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
