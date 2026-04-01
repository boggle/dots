{ config, lib, pkgs, ... }:

let
  cfg = config.features.viewer;
  sixelCfg = config.suites.sixel-tools or { enable = false; };
  
  # Check feature availability
  hasChafa = sixelCfg.enable && (sixelCfg.chafa or false);
  hasCatimg = sixelCfg.enable && (sixelCfg.catimg or false);
  hasMpv = sixelCfg.enable && (sixelCfg.mpv or false);
  
  # Image viewer preference and fallback
  preferChafa = cfg.preferImageViewer == "chafa";
  
  # Available image viewers in priority order
  imageViewer = 
    if hasChafa && preferChafa then "${pkgs.chafa}/bin/chafa"
    else if hasCatimg then "${pkgs.catimg}/bin/catimg"
    else if hasChafa then "${pkgs.chafa}/bin/chafa"
    else "${pkgs.bat}/bin/bat";
  
  # PDF viewer
  pdfViewer = "${pkgs.bat}/bin/bat";
  
  # Video viewer
  videoViewer = 
    if hasMpv then "${pkgs.mpv}/bin/mpv"
    else "${pkgs.bat}/bin/bat";
  
  # Main viewer script
  viewerScript = pkgs.writeShellScriptBin "v" ''
    #!/usr/bin/env bash
    
    # Configuration flags
    CONTINUOUS_MODE=false
    PAGER_MODE=false
    STRIP_ANSI=false
    SHOW_HELP=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
      case "$1" in
        -c|--continuous)
          CONTINUOUS_MODE=true
          shift
          ;;
        -p|--pager)
          PAGER_MODE=true
          shift
          ;;
        -s|--strip)
          STRIP_ANSI=true
          shift
          ;;
        -h|--help)
          SHOW_HELP=true
          shift
          ;;
        --)
          shift
          break
          ;;
        -*)
          echo "Unknown option: $1" >&2
          echo "Use 'v --help' for usage" >&2
          exit 1
          ;;
        *)
          break
          ;;
      esac
    done
    
    # Show help
    if [ "$SHOW_HELP" = true ]; then
      cat << 'EOF'
Usage: v [options] [file(s)...]

View files in the terminal with smart type detection.

File Handlers:
  .md, .markdown  => glow (markdown rendering)
  .png, .jpg,... => chafa/catimg (terminal images) or bat
  .pdf            => bat
  .mp4, .mkv...   => mpv --vo=sixel (terminal video, interactive only)
  .zip, .tar.gz   => List archive contents
  .csv            => column -t (formatted table)
  .json           => jq . (pretty print)
  .log            => bat --style=numbers
  .diff/.patch    => delta (syntax highlighted)
  Directory       => lsd --tree
  Binary          => xxd | bat (hex dump)
  *               => bat (syntax highlighted)

Options:
  -c, --continuous  Stream to stdout (no pager, no interactivity)
  -p, --pager        Force pager mode, wait between files
  -s, --strip        Strip ANSI color codes from output
  -h, --help         Show this help

Usage Modes:
  v                    Interactive FZF picker (always)
  v file.md            Single file, interactive mode (pager)
  v file1 file2        Multiple files, continuous mode (stream)
  v -c *.md            Force continuous mode, stream all files
  v -p file1 file2     Force pager mode, wait between files
  v -c -s *.md | less   Clean output for piping
  v -s binary.dat      Strip colors from hexdump

Notes:
  - Multiple files default to continuous mode
  - Video files in continuous mode show metadata only
  - Use -p to review each file when viewing multiple
  - Interactive tools (mpv, glow -t) only work in single/pager mode
  
  Image/PDF/Video viewing requires suites.sixel-tools to be enabled.
EOF
      exit 0
    fi
    
    # Interactive mode - no files provided, always use FZF
    if [ $# -eq 0 ]; then
      if [ -t 0 ] && command -v ${pkgs.fzf}/bin/fzf >/dev/null 2>&1; then
        # Interactive file picker with preview
        ${pkgs.fd}/bin/fd --type f 2>/dev/null | ${pkgs.fzf}/bin/fzf \
          --preview 'echo "File: {}"; echo "Size: $(stat -c%s {} 2>/dev/null || stat -f%z {} 2>/dev/null) bytes"; echo "Type: $(file -b {} 2>/dev/null)"; echo "---"; head -20 {}' \
          --height=60% \
          --reverse \
          --bind 'enter:execute(v {})' \
          --header 'Select file to view (ESC to cancel)'
        exit 0
      else
        echo "Error: No files specified and fzf not available for interactive mode" >&2
        echo "Use 'v --help' for usage" >&2
        exit 1
      fi
    fi
    
    # Determine mode
    # -c flag: force continuous
    # -p flag: force pager
    # Multiple files (no flags): default continuous
    # Single file (no flags): default interactive
    if [ "$PAGER_MODE" = "false" ] && [ "$CONTINUOUS_MODE" = "false" ]; then
      if [ $# -gt 1 ]; then
        # Multiple files without flags = continuous mode
        CONTINUOUS_MODE=true
      fi
      # Single file without flags = interactive mode (default)
    fi
    
    # Strip ANSI function
    strip_ansi() {
      if [ "$STRIP_ANSI" = "true" ]; then
        sed 's/\x1b\[[0-9;]*m//g'
      else
        cat
      fi
    }
    
    # Main viewer function
    view_file() {
      local file="$1"
      local idx="$2"
      local total="$3"
      
      if [ ! -e "$file" ]; then
        echo "Error: File not found: $file" >&2
        return 1
      fi
      
      # Directory handling
      if [ -d "$file" ]; then
        if [ "$CONTINUOUS_MODE" = "true" ] || [ $total -gt 1 ]; then
          echo "=== Directory: $file ==="
        fi
        ${pkgs.lsd}/bin/lsd --tree "$file" | strip_ansi
        return $?
      fi
      
      # Get file info
      local ext="''${file##*.}"
      ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
      local mime=$(file -b --mime-type "$file" 2>/dev/null || echo "unknown")
      local size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo "0")
      
      # Show header for multiple files
      if [ $total -gt 1 ] || [ "$PAGER_MODE" = "true" ]; then
        echo ""
        echo "=== [$idx/$total] $file ($(numfmt --to=iec $size)) ==="
        echo ""
      fi
      
      # File type dispatch
      case "$ext" in
        md|markdown)
          if [ "$CONTINUOUS_MODE" = "true" ]; then
            ${pkgs.glow}/bin/glow "$file" 2>/dev/null | strip_ansi
          else
            # Interactive mode: use glow -t (terminal mode) without any processing
            # to preserve interactive rendering and all terminal features
            ${pkgs.glow}/bin/glow -t "$file" 2>/dev/null
          fi
          ;;
          
        png|jpg|jpeg|gif|bmp|webp|tiff|tif|avif|jxl|svg|ico)
          ${imageViewer} "$file" 2>/dev/null | strip_ansi || ${pkgs.bat}/bin/bat "$file" | strip_ansi
          ;;
          
        pdf)
          ${pdfViewer} "$file" 2>/dev/null | strip_ansi || ${pkgs.bat}/bin/bat "$file" | strip_ansi
          ;;
          
        mp4|mkv|avi|mov|webm|flv|wmv|ogv|3gp)
          if [ "$CONTINUOUS_MODE" = "true" ]; then
            # In continuous mode, show metadata instead of playing
            echo "Video file: $file"
            echo "Type: $(file -b "$file" 2>/dev/null)"
            echo "Size: $(numfmt --to=iec $size)"
            echo ""
            echo "Use 'v -p $file' or 'v <single-file>' to play interactively"
          else
            echo "Playing: $file (press 'q' to quit)"
            ${videoViewer} --vo=sixel --profile=fast --loop-file=no --fs=no "$file" 2>/dev/null | strip_ansi || ${pkgs.bat}/bin/bat "$file" | strip_ansi
          fi
          ;;
          
        gif)
          ${imageViewer} "$file" 2>/dev/null | strip_ansi || ${pkgs.bat}/bin/bat "$file" | strip_ansi
          ;;
          
        zip)
          echo "Archive: $file ($(numfmt --to=iec $size))"
          echo ""
          unzip -l "$file" 2>/dev/null | head -20 | strip_ansi || ${pkgs.bat}/bin/bat "$file" | strip_ansi
          ;;
          
        tar|gz|bz2|xz|tgz|tbz2|txz)
          echo "Archive: $file ($(numfmt --to=iec $size))"
          echo ""
          tar -tvf "$file" 2>/dev/null | head -30 | strip_ansi || ${pkgs.bat}/bin/bat "$file" | strip_ansi
          ;;
          
        7z|rar)
          echo "Archive: $file ($(numfmt --to=iec $size))"
          echo ""
          if command -v 7z >/dev/null 2>&1; then
            7z l "$file" 2>/dev/null | head -30 | strip_ansi
          elif command -v unrar >/dev/null 2>&1; then
            unrar l "$file" 2>/dev/null | head -30 | strip_ansi
          else
            echo "Archive viewer not available (install p7zip or unrar)"
            ${pkgs.bat}/bin/bat "$file" | strip_ansi
          fi
          ;;
          
        csv)
          column -t -s, "$file" 2>/dev/null | ${pkgs.bat}/bin/bat --language=tsv | strip_ansi || ${pkgs.bat}/bin/bat "$file" | strip_ansi
          ;;
          
        json)
          ${pkgs.jq}/bin/jq . "$file" 2>/dev/null | ${pkgs.bat}/bin/bat --language=json | strip_ansi || ${pkgs.bat}/bin/bat "$file" | strip_ansi
          ;;
          
        yaml|yml)
          ${pkgs.bat}/bin/bat --language=yaml "$file" | strip_ansi
          ;;
          
        log)
          ${pkgs.bat}/bin/bat --style=numbers "$file" | strip_ansi
          ;;
          
        diff|patch)
          if command -v ${pkgs.delta}/bin/delta >/dev/null 2>&1; then
            ${pkgs.delta}/bin/delta "$file" 2>/dev/null | strip_ansi || ${pkgs.bat}/bin/bat --language=diff "$file" | strip_ansi
          else
            ${pkgs.bat}/bin/bat --language=diff "$file" | strip_ansi
          fi
          ;;
          
        *)
          # Binary file detection
          if echo "$mime" | grep -q "^application/" || echo "$mime" | grep -q "executable"; then
            echo "Binary file: $file"
            echo "Type: $(file -b "$file" 2>/dev/null)"
            echo "Size: $(numfmt --to=iec $size)"
            echo ""
            echo "Hexdump (first 4KB):"
            head -c 4096 "$file" 2>/dev/null | xxd | head -50 | ${pkgs.bat}/bin/bat --language=hex --style=numbers | strip_ansi
          else
            ${pkgs.bat}/bin/bat "$file" | strip_ansi
          fi
          ;;
      esac
      
      return $?
    }
    
    # Process all files
    exit_code=0
    total=$#
    idx=1
    
    for file in "$@"; do
      view_file "$file" "$idx" "$total"
      result=$?
      if [ $result -ne 0 ]; then
        exit_code=1
      fi
      
      # In pager mode with multiple files, wait for keypress
      if [ "$PAGER_MODE" = "true" ] && [ $total -gt 1 ] && [ $idx -lt $total ]; then
        echo ""
        read -p "Press Enter to continue to next file..."
      fi
      
      idx=$((idx + 1))
    done
    
    exit $exit_code
  '';

in
{
  options.features.viewer = {
    enable = lib.mkEnableOption "Terminal file viewer with smart type detection";
    
    alias = lib.mkOption {
      type = lib.types.str;
      default = "v";
      description = "Alias name for the viewer command (default: 'v').";
    };
    
    preferImageViewer = lib.mkOption {
      type = lib.types.enum [ "chafa" "catimg" ];
      default = "chafa";
      description = "Preferred image viewer (chafa or catimg). Falls back to alternative if not available.";
    };
    
    enableVideo = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable video viewing with mpv --vo=sixel (requires features.sixel.mpv).";
    };
    
    enableDirectoryTree = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Show directory tree when viewing directories.";
    };
    
    enableArchives = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "List archive contents (.zip, .tar.gz, etc.) instead of extracting.";
    };
    
    enableDataFormats = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Pretty print data formats (.csv, .json, .yaml).";
    };
    
    enableFzfPicker = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable interactive file picker when v is called without arguments.";
    };

    ripgrepAll = lib.mkEnableOption "ripgrep-all (search including PDFs and binaries)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = builtins.filter (p: p != null) [
      viewerScript
      (lib.mkIf cfg.ripgrepAll pkgs.ripgrep-all)
    ];
    
    # Create the alias
    programs.bash.shellAliases = {
      ${cfg.alias} = "${viewerScript}/bin/v";
    };
    
    # Optional warnings if sixel features missing
    programs.bash.initExtra = lib.optionalString (!hasChafa && !hasCatimg) ''
      _v_warn_images() {
        if [[ "$1" =~ \.(png|jpg|jpeg|gif|bmp|webp|tiff|tif|avif|jxl|svg)$ ]]; then
          echo "Tip: Enable suites.sixel-tools.chafa or suites.sixel-tools.catimg for terminal images" >&2
        fi
      }
    '';
  };
}
