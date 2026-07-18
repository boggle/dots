{ config, lib, pkgs, inputs, bashrcDerivation, profileDerivation, ... }:

let
  local = inputs.dots-local;
  nixonDefault = if local ? nixonDefault then local.nixonDefault else false;
  nixonDefaultStr = if nixonDefault then "1" else "0";
in

{
  home.file.".bashrc-nix".source = bashrcDerivation;
  home.file.".profile-nix".source = profileDerivation;

  home.file.".profile" = lib.mkForce {
    text = ''
      if [ -z "''${NIXON+x}" ]; then export NIXON=${nixonDefaultStr}; fi
      [[ -f ~/.profile-core ]] && . ~/.profile-core
      if [ "$NIXON" = "1" ]; then [[ -f ~/.profile-nix ]] && . ~/.profile-nix; fi
      [[ -f ~/.bashrc ]] && . ~/.bashrc
    '';
  };

  home.file.".bashrc" = lib.mkForce {
    text = ''
      if [ -z "''${NIXON+x}" ]; then export NIXON=${nixonDefaultStr}; fi

      # --- 0. SHELL FOUNDATIONS (Universal) ---
      # Fix TERM for remote/minimal environments before starting logic
      if [ -z "$TERM" ] || [ "$TERM" = "dumb" ]; then
        export TERM=xterm-256color
      fi

      # Better bash behavior
      shopt -s histappend extglob globstar checkjobs

      # Less noisy bell
      echo -n -e "\e[11;30]"
      echo -n -e "\e[10;440]"
     
      # --- 2. THE NIXON GATEKEEPER ---
      # NOTE: was previously "~/.bashrc_core" (underscore) - a typo that
      # never matched the real file "~/.bashrc-core" (hyphen, consistent
      # with ~/.profile-core below), so native/pre-nix bashrc content
      # (e.g. GTK/QT theme env vars) was silently never sourced.
      [[ -f ~/.bashrc-core ]] && . ~/.bashrc-core
      alias nixon='NIXON=1 exec bash -l'
      alias nixoff='NIXON=0 exec bash -l'
 
      if [ "$NIXON" = "1" ]; then
        # NIX-ON MODE: Load nix environment
        [[ -f ~/.bashrc-nix ]] && . ~/.bashrc-nix       
      else
        # NON-NIX MODE: Pure host environment
        export PATH=$(echo "$PATH" | tr ":" "\n" | grep -v "/nix" | tr "\n" ":" | sed 's/:$//')
        export PATH="$PATH:/nix/var/nix/profiles/default/bin"
        alias ls='ls --color=auto'
        if [ "$EUID" -eq 0 ]; then
          PS1='\[\e[31m\]\u@\h\[\e[0m\]:\[\e[32m\]\w\[\e[0m\]\$ '
        else
          PS1='\[\e[34m\]\u@\h\[\e[0m\]:\[\e[32m\]\w\[\e[0m\]\$ '
        fi
      fi

      # --- 1. DYNAMIC TOOL DISCOVERY (Generic) ---
      # Default alias setup
      alias +="sudo -E "

      # LS_COLORS Baseline
      if command -v vivid >/dev/null 2>&1; then
        export LS_COLORS="$(vivid generate tokyonight-moon)"
      elif command -v dircolors >/dev/null 2>&1; then
        eval "$(dircolors -b)"
      fi

      # Editor/Visual Setup
      for ed in hx helix nvim vim vi fresh nano; do
        if command -v "$ed" >/dev/null 2>&1; then
          export EDITOR="$ed"
          export VISUAL="$ed"
          break
        fi
      done
            
      if command -v fresh >/dev/null 2>&1; then
        alias fr="$(type -p fresh)"
      fi
    
      if ! command -v hx &> /dev/null; then  
        if command -v helix >/dev/null 2>&1; then
          alias hx="$(type -p helix)"
        fi
      fi
      
      if command -v frogmouth>/dev/null 2>&1; then
        alias fm='f() { if [ $# -eq 0 ]; then frogmouth .; else frogmouth "$@"; fi; }; f'
      fi

      # Butterfish AI shell (local LLM via llama.cpp)
      if command -v butterfish >/dev/null 2>&1; then
        alias bf="butterfish shell -u 'http://127.0.0.1:5001/v1' -b ${pkgs.bash}/bin/bash"
      fi

      # Pager & Previewer Logic
      if command -v moor >/dev/null 2>&1; then
        export PAGER="$(type -p moor)"
        export LESS="-RF"
      else
        export PAGER="$(type -p less)"
        export LESS="-RF"
      fi

      if command -v bat >/dev/null 2>&1; then
        alias cat="bat -pp"
        if command -v moor >/dev/null 2>&1; then
          export BAT_PAGER="$(type -p moor) -no-linenumbers"
        fi
        
        if command -v batpipe >/dev/null 2>&1; then
          eval "$(batpipe)"
        fi
        
        if command -v batman >/dev/null 2>&1; then
          alias man="batman"
        fi

        # if command -v batgrep >/dev/null 2>&1; then
        #   alias grep="batgrep"
        # fi
        
        if command -v batdiff >/dev/null 2>&1; then
          alias diff="batdiff"
          alias dt="batdiff --delta"
        fi
        
        if command -v batwatch >/dev/null 2>&1; then
          alias watch="batwatch"
        fi
      fi
            
      # 1. Global FZF Config (The "Source of Truth")
      if command -v fzf >/dev/null 2>&1; then
        export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --border --preview-window='right:60%:wrap:hidden' --bind='?:toggle-preview'"
      
        # 2. Use a Function instead of an Alias to prevent "command not found" errors
        fzf() {
          if command -v bat >/dev/null 2>&1; then
            # We use 'command fzf' to call the binary directly and avoid recursion
            command fzf \
               --preview 'bat --style=numbers --color=always --line-range :500 {} 2>/dev/null || lsd --tree --color=always {} 2>/dev/null || ls -C {}' \
               --bind 'ctrl-e:execute($EDITOR {} < /dev/tty)' \
               "$@"
          else
            command fzf "$@"
          fi
        }
      
        # 3. Optimized Zoxide Interactive (zi)
        if command -v zoxide >/dev/null 2>&1; then
          zi() {
            local dir preview_cmd
                  
            # Smart previewer selection
            if command -v lsd >/dev/null 2>&1; then
              preview_cmd="lsd --tree --depth 2 --color=always {}"
            else
              preview_cmd="ls -C {}"
            fi
      
            # We use 'zoxide query -l' to get the list, then pipe to our new fzf function
            dir=$(zoxide query -l | fzf \
              --preview "$preview_cmd" \
              --preview-window="right:50%:wrap" \
              --bind 'ctrl-delete:execute(zoxide remove {})+reload(zoxide query -l)')
            
            if [[ -n "$dir" ]]; then
              cd "$dir" || return
            fi
          }
        fi
      fi
      export GLOW_STYLE="dark"
      export GLOW_WIDTH="auto"
    '';
  };

  # nixexec: Run command in nix-enabled login shell environment
  home.file.".local/bin/nixexec" = {
    executable = true;
    text = ''
      #!/usr/bin/env NIXON=1 /bin/bash -l
      exec "$@"
    '';
  };
}
