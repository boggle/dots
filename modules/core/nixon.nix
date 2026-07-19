{ config, lib, pkgs, dotsLocal, bashrcDerivation, profileDerivation, ... }:

let
  nixonDefaultStr = if dotsLocal.nixonDefault then "1" else "0";
in

{
  # .bashrc-nix / .profile-nix: pure Home Manager output (via the
  # "gutter eval" in flake.nix).
  home.file.".bashrc-nix".source = bashrcDerivation;
  home.file.".profile-nix".source = profileDerivation;

  # `programs.bash.enable = true` (set in flake.nix) makes Home Manager's
  # own built-in bash module declare `home.file.".bashrc"`/`".profile"`
  # itself, independent of anything in this file. Explicitly disabling
  # these two `home.file` entries (rather than simply not declaring our
  # own) tells HM to skip materializing them at all, leaving the real
  # dotfiles genuinely alone for the activation hook below to manage.
  home.file.".bashrc".enable = lib.mkForce false;
  home.file.".profile".enable = lib.mkForce false;

  # .profile-dots / .bashrc-dots: the hand-authored NIXON-gatekeeper hybrid
  # script. These are dots-owned files under their own name - the REAL
  # ~/.profile/~/.bashrc are left for the user, with a small idempotent
  # activation hook (below) ensuring they source these files, appended
  # only if not already present, never overwriting existing content.
  home.file.".profile-dots" = {
    text = ''
      if [ -z "''${NIXON+x}" ]; then export NIXON=${nixonDefaultStr}; fi
      if [ "$NIXON" = "1" ]; then [[ -f ~/.profile-nix ]] && . ~/.profile-nix; fi
      [[ -f ~/.bashrc-dots ]] && . ~/.bashrc-dots
    '';
  };

  home.file.".bashrc-dots" = {
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
      for ed in hx helix nvim vim vi nano; do
        if command -v "$ed" >/dev/null 2>&1; then
          export EDITOR="$ed"
          export VISUAL="$ed"
          break
        fi
      done
    
      if ! command -v hx &> /dev/null; then  
        if command -v helix >/dev/null 2>&1; then
          alias hx="$(type -p helix)"
        fi
      fi
      
      if command -v frogmouth>/dev/null 2>&1; then
        alias fm='f() { if [ $# -eq 0 ]; then frogmouth .; else frogmouth "$@"; fi; }; f'
      fi

      # The `bf` butterfish alias is set correctly by butterfish.nix's
      # `programs.bash.shellAliases.bf`, which flows through the real Home
      # Manager bash config into .bashrc-nix - sourced above whenever
      # NIXON=1, no need to duplicate it here.

      # Pager & Previewer Logic
      export PAGER="$(type -p less)"
      export LESS="-RF"

      if command -v bat >/dev/null 2>&1; then
        alias cat="bat -pp"

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

  # Idempotent, additive-only hook ensuring the REAL ~/.bashrc/~/.profile
  # source .bashrc-dots/.profile-dots. Appends the source line only if a
  # sentinel comment isn't already present - creates the file fresh if it
  # doesn't exist yet (first-run bootstrap), but never touches/removes any
  # other content a user has in these files. Runs after Home Manager's own
  # file linking (writeBoundary).
  home.activation.ensureDotsShellHook = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    BASHRC_SENTINEL="# dots-managed: source ~/.bashrc-dots (see ~/dots/modules/core/nixon.nix)"
    if [ ! -f "$HOME/.bashrc" ] || ! grep -qF "$BASHRC_SENTINEL" "$HOME/.bashrc" 2>/dev/null; then
      {
        echo ""
        echo "$BASHRC_SENTINEL"
        echo '[[ -f ~/.bashrc-dots ]] && . ~/.bashrc-dots'
      } >> "$HOME/.bashrc"
    fi

    PROFILE_SENTINEL="# dots-managed: source ~/.profile-dots (see ~/dots/modules/core/nixon.nix)"
    if [ ! -f "$HOME/.profile" ] || ! grep -qF "$PROFILE_SENTINEL" "$HOME/.profile" 2>/dev/null; then
      {
        echo ""
        echo "$PROFILE_SENTINEL"
        echo '[[ -f ~/.profile-dots ]] && . ~/.profile-dots'
      } >> "$HOME/.profile"
    fi
  '';
}
