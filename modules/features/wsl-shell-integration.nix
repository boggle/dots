# VSCode Remote-SSH + WSL2/WSLg shell integration compatibility.
#
# This workaround (sourcing VS Code's shell-integration script, cleaning up
# starship's PROMPT_COMMAND hook so it doesn't fight with VS Code's own
# prompt handling, re-initializing zoxide/direnv after) applies to any WSL
# host connected to via VS Code's Remote-SSH extension. Enabled by default
# whenever dotsLocal.isWsl is true (see rules.nix), like every
# other feature module here - can still be disabled explicitly if not
# wanted.
{ config, lib, pkgs, ... }:

let
  coreLib = import ../core/lib.nix { inherit lib; };
  cfg = config.features.wsl-shell-integration;
in {
  options.features.wsl-shell-integration = {
    enable = coreLib.mkDefaultDisabledOption "VSCode Remote-SSH + WSL2 shell integration compatibility fixes";
  };

  config = lib.mkIf cfg.enable {
    # The context bundle's own zoxide/direnv bash integration (via
    # programs.zoxide/programs.direnv) gets disabled here in favor of the
    # manual re-init below, which only runs inside VS Code's integrated
    # terminal - this avoids double-initializing them in a plain terminal.
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
  };
}
