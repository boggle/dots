{ config, lib, pkgs, ... }:

let
  cfg = config.features.clipboard;
  backend = cfg.backend;
  sed = "${pkgs.gnused}/bin/sed";

  # Cleaned base commands (No backend-specific trimming)
  copyCmdBase = {
    wayland = "${pkgs.wl-clipboard}/bin/wl-copy";
    x11     = "${pkgs.xclip}/bin/xclip -selection clipboard";
    wsl     = "clip.exe";
    macos   = "pbcopy";
  }.${backend};

  pasteCmdBase = {
    wayland = "${pkgs.wl-clipboard}/bin/wl-paste";
    x11     = "${pkgs.xclip}/bin/xclip -selection clipboard -o";
    wsl     = "powershell.exe -NoProfile -Command \"Get-Clipboard -Raw\"";
    macos   = "pbpaste";
  }.${backend};

in
{
  options.features.clipboard = {
    enable = lib.mkEnableOption "Cross-platform clipboard feature";
    backend = lib.mkOption {
      type = lib.types.enum [ "wayland" "x11" "wsl" "macos" ];
      description = "Clipboard backend to use.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ gnused ]
      ++ lib.optionals (backend == "wayland") [ wl-clipboard ]
      ++ lib.optionals (backend == "x11") [ xclip ];

    programs.bash.initExtra = ''
      _clip_help() {
        echo "Usage: $1 [FLAGS] [COMMAND]"
        echo ""
        echo "Flags:"
        echo "  -s, --strip      Strip ANSI color codes"
        echo "  -r, --raw        Keep CR characters (WSL)"
        echo "  -T, --no-trim    Do NOT trim the trailing newline (trimmed by default)"
        echo "  -h, --help       Show this help"
        if [[ "$1" == "teeclip" || "$1" == "clipin" ]]; then
          echo "  -k, --keep       Keep stdout/passthrough clean (unmodified by -s/-r/-T)"
          echo "  --out            Capture stdout only"
          echo "  --err            Capture stderr only"
          echo "  --all            Capture both stdout and stderr (default for COMMAND)"
        fi
      }

      # Centralized processing logic
      _clip_process() {
        local strip_ansi=$1
        local keep_cr=$2
        local no_trim=$3
        
        local pipeline="cat"

        # 1. Strip ANSI
        [ "$strip_ansi" = "true" ] && pipeline="$pipeline | ${sed} -r \"s/\x1B\[([0-9]{1,3}(;[0-9]{1,3})*)?[mGK]//g\""
        
        # 2. Handle WSL CRLF
        [ "${backend}" = "wsl" ] && [ "$keep_cr" = "false" ] && pipeline="$pipeline | tr -d '\r'"
        
        # 3. Handle Newline Trimming (Standardized)
        if [ "$no_trim" = "false" ]; then
           # This perl snippet safely removes exactly one trailing newline if it exists
           pipeline="$pipeline | ${pkgs.perl}/bin/perl -pe 'chomp if eof'"
        fi

        eval "$pipeline"
      }

      _clip_logic() {
        local use_tee=$1; local func_name=$2; shift 2
        local mode="default"; local s=false; local r=false; local k=false; local T=false
        
        while [[ "$1" =~ ^- ]]; do
          case "$1" in
            --err|--all|--out) mode=''${1#--}; shift ;;
            --strip) s=true; shift ;;
            --raw)   r=true; shift ;;
            --no-trim) T=true; shift ;;
            --keep)  k=true; shift ;;
            --help)  _clip_help "$func_name"; return 0 ;;
            -[a-zA-Z]*) 
              local optstring=''${1#-}
              for (( i=0; i<''${#optstring}; i++ )); do
                case "''${optstring:$i:1}" in
                  s) s=true ;; r) r=true ;; k) k=true ;; T) T=true ;; h) _clip_help "$func_name"; return 0 ;; *) break ;;
                esac
              done
              shift ;;
            *) break ;;
          esac
        done

        _do_copy_buffered() {
          local tmp_raw=$(mktemp)
          cat > "$tmp_raw"
          if [ "$use_tee" = "true" ]; then
            if [ "$k" = "true" ]; then 
                cat "$tmp_raw" >&4
            else 
                _clip_process "$s" "$r" "$T" < "$tmp_raw" >&4
            fi
          fi
          if [ -s "$tmp_raw" ]; then 
            _clip_process "$s" "$r" "$T" < "$tmp_raw" | ${copyCmdBase}
          fi
          rm -f "$tmp_raw"
        }

        exec 4>&1 
        if [ $# -eq 0 ]; then
          [[ "$mode" == "err" || "$mode" == "all" ]] && { echo "Error: --all/--err require COMMAND." >&2; return 1; }
          _do_copy_buffered
        else
          [ "$mode" = "default" ] && mode="all"
          case "$mode" in
            out) "$@" | _do_copy_buffered ;;
            all) "$@" 2>&1 | _do_copy_buffered ;;
            err) "$@" 2>&1 1>/dev/null | _do_copy_buffered ;;
          esac
        fi
        exec 4>&-
      }

      clipin()   { _clip_logic false "clipin" "$@"; }
      teeclip()  { _clip_logic true "teeclip" "$@"; }

      clipout() {
        local s=false; local r=false; local T=false
        while [[ "$1" =~ ^- ]]; do
          case "$1" in
            --strip) s=true; shift ;; --raw) r=true; shift ;; --no-trim) T=true; shift ;; --help) _clip_help "clipout"; return 0 ;;
            -[a-zA-Z]*)
              local optstring=''${1#-}
              for (( i=0; i<''${#optstring}; i++ )); do
                case "''${optstring:$i:1}" in s) s=true ;; r) r=true ;; T) T=true ;; h) _clip_help "clipout"; return 0 ;; esac
              done
              shift ;;
            *) break ;;
          esac
        done
        ${pasteCmdBase} | _clip_process "$s" "$r" "$T"
      }

      clipfile() {
        local s=false; local r=false; local T=false
        while [[ "$1" =~ ^- ]]; do
          case "$1" in
            --strip) s=true; shift ;; --raw) r=true; shift ;; --no-trim) T=true; shift ;; --help) _clip_help "clipfile"; return 0 ;;
            -[a-zA-Z]*)
              local optstring=''${1#-}
              for (( i=0; i<''${#optstring}; i++ )); do
                case "''${optstring:$i:1}" in s) s=true ;; r) r=true ;; T) T=true ;; h) _clip_help "clipfile"; return 0 ;; esac
              done
              shift ;;
            *) break ;;
          esac
        done
        [ -f "$1" ] && _clip_process "$s" "$r" "$T" < "$1" | ${copyCmdBase}
      }
    '';
  };
}