{ config, lib, pkgs, inputs, ... }:

let
  local = inputs.dots-local;
  distro = local.distro or "unknown";
  
  # Find all alien package spec files recursively
  collectAlienSpecsFiles = dir:
    let
      entries = builtins.readDir dir;
      names = builtins.attrNames entries;
      suffix = ".${distro}-packages.nix";
    in builtins.concatLists (map (name:
      let 
        ty = entries.${name}; 
        p = dir + "/${name}";
      in 
        if ty == "directory" then collectAlienSpecsFiles p
        else if ty == "regular" && lib.hasSuffix suffix name then [ p ]
        else [ ]
    ) names);
  
  # Load alien specs for current distro
  modulesDir = ../../modules;
  alienSpecFiles = collectAlienSpecsFiles modulesDir;
  rawAlienSpecs = lib.foldl' (acc: p: acc // (import p)) {} alienSpecFiles;
  
  # Get all package managers from specs
  allManagers = lib.unique (lib.concatLists (lib.mapAttrsToList (pkgName: spec:
    builtins.attrNames (spec.packages or {})
  ) rawAlienSpecs));

  # Helper function for features to check if alien package exists
  hasAlien = pkgName: rawAlienSpecs ? ${pkgName};
  
  # Create an alien-aware package entry
  # Usage: mkEntry enabled "pkgname" pkgs.pkgname
  # Returns: null if disabled or alien-managed, otherwise the nix package
  mkEntry = enabled: pkgName: nixPkg: 
    if !enabled then null
    else if hasAlien pkgName then null
    else nixPkg;

in {
  options.alienPackages = {
    enable = lib.mkEnableOption "alien package management" // { default = true; };
    
    enabledPackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''
        List of alien package names to enable. Each module should add its
        alien package names here when both the module and the specific feature
        are enabled.
      '';
    };
  };

  config = lib.mkIf config.alienPackages.enable (let
    cfg = config.alienPackages;
    enabledPkgs = cfg.enabledPackages;
    
    # Get packages per manager from enabled packages
    packagesPerManager = lib.genAttrs allManagers (mgr:
      lib.concatLists (lib.mapAttrsToList (pkgName: spec:
        if builtins.elem pkgName enabledPkgs then
          (spec.packages or {}).${mgr} or []
        else []
      ) rawAlienSpecs)
    );
    
    # Filter out empty managers
    nonEmptyPackages = lib.filterAttrs (mgr: pkgs: pkgs != []) packagesPerManager;
    
    # Create install script
    installScript = pkgs.writeShellScriptBin "update-alien-packages" ''
      set -e
      
      PKG_DIR="$HOME/.local/share/dots/packages/required"
      INSTALLED_DIR="$HOME/.local/share/dots/packages/installed"
      ORPHAN_DIR="$HOME/.local/share/dots/packages/orphaned"
      
      mkdir -p "$INSTALLED_DIR" "$ORPHAN_DIR"
      
      # Parse arguments
      TARGET="all"
      ACTION="update"
      DRY_RUN=0
      
      while [ $# -gt 0 ]; do
        case "$1" in
          --target)
            TARGET="$2"
            shift 2
            ;;
          --action)
            ACTION="$2"
            shift 2
            ;;
          --dry-run)
            DRY_RUN=1
            shift
            ;;
          --help|-h)
            cat << 'HELP'
Usage: update-alien-packages [--action=<update|install|remove>] [--target=<all|pacman|paru|...>] [--dry-run]

Manage alien (native) package managers

Actions:
  update   Install missing packages and detect orphans (default)
  install  Install missing packages only
  remove   Interactively remove orphaned packages

Options:
  --target=<manager>  Target specific manager (default: all)
  --action=<action>   Action to perform (default: update)
  --dry-run           Show what would be done without making changes
  --help, -h          Show this help message

Available package managers:
HELP
            ${lib.concatStringsSep "\n" (map (mgr: ''echo "  - ${mgr}"'') (builtins.attrNames nonEmptyPackages))}
            exit 0
            ;;
          *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
        esac
      done
      
      get_installed_packages() {
        local mgr="$1"
        case "$mgr" in
          pacman|paru)
            # Use -Qq (all installed) instead of -Qqe (explicitly installed)
            # This handles metapackages that install deps automatically
            pacman -Qq 2>/dev/null | sort || echo ""
            ;;
          zypper)
            zypper search -i --installed-only -t package 2>/dev/null | grep "^i" | awk '{print $3}' | sort || echo ""
            ;;
          *)
            echo ""
            ;;
        esac
      }
      
      remove_packages() {
        local mgr="$1"
        local orphaned_file="$ORPHAN_DIR/$mgr.txt"
        
        if [ ! -f "$orphaned_file" ] || [ ! -s "$orphaned_file" ]; then
          echo ""
          echo "╔════════════════════════════════════════════════════════════╗"
          printf "║  🗑️  Remove Orphaned Packages - %-25s ║\n" "$mgr"
          echo "╚════════════════════════════════════════════════════════════╝"
          echo ""
          echo "No orphaned packages found."
          return 0
        fi
        
        echo ""
        echo "╔════════════════════════════════════════════════════════════╗"
          printf "║  🗑️  Remove Orphaned Packages - %-25s ║\n" "$mgr"
        echo "╚════════════════════════════════════════════════════════════╝"
        echo ""
        
        local to_remove=""
        local removed_count=0
        local kept_count=0
        
        # Use file descriptor 3 to read from orphan file, leaving stdin for user input
        while IFS= read -r pkg <&3; do
          [ -z "$pkg" ] && continue
          
          printf "Remove %s? (y/N): " "$pkg"
          read -r response
          
          if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
            case "$mgr" in
              pacman|paru)
                if sudo pacman -Rns "$pkg"; then
                  echo "  ✅ Removed $pkg"
                  to_remove="$to_remove\n$pkg"
                  ((removed_count++))
                else
                  echo "  ❌ Failed to remove $pkg"
                fi
                ;;
              zypper)
                if sudo zypper remove --no-confirm "$pkg"; then
                  echo "  ✅ Removed $pkg"
                  to_remove="$to_remove\n$pkg"
                  ((removed_count++))
                else
                  echo "  ❌ Failed to remove $pkg"
                fi
                ;;
            esac
          else
            echo "  → Skipped $pkg"
            ((kept_count++))
          fi
        done 3< "$orphaned_file"
        
        # Refresh orphan list - filter against actually installed packages
        local actually_installed
        actually_installed=$(get_installed_packages "$mgr")
        
        if [ -n "$actually_installed" ]; then
          # Filter orphaned list: keep only what's still installed
          comm -12 <(sort "$orphaned_file") <(echo "$actually_installed") > "$orphaned_file.tmp"
          mv "$orphaned_file.tmp" "$orphaned_file"
        else
          # No packages installed, clear orphan list
          > "$orphaned_file"
        fi
        
        echo ""
        echo "Summary: $removed_count removed, $kept_count kept"
      }
      
      update_packages() {
        local mgr="$1"
        local pkg_file="$PKG_DIR/$mgr.txt"
        local installed_file="$INSTALLED_DIR/$mgr.txt"
        local orphaned_file="$ORPHAN_DIR/$mgr.txt"
        
        if [ ! -f "$pkg_file" ]; then
          return 0
        fi
        
        # Get ACTUALLY installed packages from system
        local actually_installed
        actually_installed=$(get_installed_packages "$mgr")
        
        # Get required packages
        local required
        required=$(sort "$pkg_file")
        
        # Get previously tracked installed packages
        local previously_installed
        if [ -f "$installed_file" ]; then
          previously_installed=$(sort "$installed_file")
        else
          previously_installed=""
        fi
        
        # Calculate to_install: required - actually_installed
        local to_install
        if [ -n "$actually_installed" ]; then
          to_install=$(comm -23 <(echo "$required") <(echo "$actually_installed"))
        else
          to_install="$required"
        fi
        
        # Calculate orphans: previously_installed - required
        local orphans
        if [ -n "$previously_installed" ]; then
          orphans=$(comm -23 <(echo "$previously_installed") <(echo "$required"))
        else
          orphans=""
        fi
        
        # For update action only: track orphans (skip in dry-run)
        if [ "$ACTION" = "update" ] && [ "$DRY_RUN" -eq 0 ]; then
          # Update orphan list (cumulative, filtered against required)
          if [ -n "$orphans" ]; then
            local tmp_orphan
            tmp_orphan=$(mktemp)
            if [ -f "$orphaned_file" ]; then
              cat "$orphaned_file" >> "$tmp_orphan"
            fi
            echo "$orphans" >> "$tmp_orphan"
            sort "$tmp_orphan" | uniq | comm -23 - <(echo "$required") > "$orphaned_file" || true
            rm "$tmp_orphan"
          fi
        fi
        
        local to_install_count
        if [ -n "$to_install" ]; then
          to_install_count=$(echo "$to_install" | grep -c . || echo 0)
        else
          to_install_count=0
        fi
        
        local orphan_count
        if [ -n "$orphans" ]; then
          orphan_count=$(echo "$orphans" | grep -c . || echo 0)
        else
          orphan_count=0
        fi
        
        # DRY-RUN MODE: Show summary and exit
        if [ "$DRY_RUN" -eq 1 ]; then
          echo ""
          echo "╔════════════════════════════════════════════════════════════╗"
          printf "║  📦 Alien Package Changes - %-30s ║\n" "$mgr"
          echo "╚════════════════════════════════════════════════════════════╝"
          echo ""
          echo "Required: $(echo "$required" | grep -c .) packages"
          
          local already_installed_count
          if [ -n "$actually_installed" ]; then
            already_installed_count=$(echo "$actually_installed" | grep -Fxf <(echo "$required") | grep -c . || echo 0)
          else
            already_installed_count=0
          fi
          echo "Already installed: $already_installed_count"
          
          if [ "$to_install_count" -gt 0 ]; then
            echo ""
            echo "To install (+):"
            echo "$to_install" | while read -r pkg; do
              [ -n "$pkg" ] && echo "  + $pkg"
            done
          fi
          
          if [ "$orphan_count" -gt 0 ]; then
            echo ""
            echo "To remove (-):"
            echo "$orphans" | while read -r pkg; do
              [ -n "$pkg" ] && echo "  - $pkg"
            done
          fi
          
          echo ""
          if [ "$to_install_count" -eq 0 ] && [ "$orphan_count" -eq 0 ]; then
            echo "✅ All packages in order"
            return 0
          else
            echo "⚠️  Changes needed"
            return 1
          fi
        fi
        
        # NORMAL MODE: Print summary header
        echo ""
        echo "╔════════════════════════════════════════════════════════════╗"
        printf "║  📦 Alien Package Manager - %-30s ║\n" "$mgr"
        echo "╚════════════════════════════════════════════════════════════╝"
        echo ""
        echo "Required packages: $(echo "$required" | grep -c .)"
        
        local already_installed_count
        if [ -n "$actually_installed" ]; then
          already_installed_count=$(echo "$actually_installed" | grep -Fxf <(echo "$required") | grep -c . || echo 0)
        else
          already_installed_count=0
        fi
        echo "Already installed: $already_installed_count"
        
        if [ -z "$to_install" ] || [ "$to_install_count" -eq 0 ]; then
          echo ""
          echo "✅ All required packages already installed"
        else
          echo ""
          echo "Installing:"
          echo "$to_install" | while read -r pkg; do
            [ -n "$pkg" ] && echo "  - $pkg"
          done
          echo ""
          
          local install_cmd
          case "$mgr" in
            pacman)
              install_cmd="sudo pacman -S --needed"
              ;;
            paru)
              install_cmd="paru -S --needed"
              ;;
            zypper)
              install_cmd="sudo zypper install --no-confirm"
              ;;
            *)
              echo "Unknown package manager: $mgr"
              return 1
              ;;
          esac
          
          if $install_cmd $to_install; then
            echo ""
            echo "✅ Successfully installed $to_install_count package(s)"
          else
            echo ""
            echo "❌ Installation failed"
            return 1
          fi
        fi
        
        # Update installed tracking (what we think is now installed)
        echo "$required" > "$installed_file"
        
        # For update action only: show orphans
        if [ "$ACTION" = "update" ]; then
          if [ -f "$orphaned_file" ] && [ -s "$orphaned_file" ]; then
            local orphan_count
            orphan_count=$(wc -l < "$orphaned_file")
            echo ""
            echo ""
            echo "╔════════════════════════════════════════════════════════════╗"
            printf "║  ⚠️  ORPHANED PACKAGES - Review for removal%-14s ║\n" ""
            echo "╚════════════════════════════════════════════════════════════╝"
            echo ""
            cat "$orphaned_file"
            echo ""
            echo "Total orphaned: $orphan_count"
            echo "Location: $orphaned_file"
            echo ""
            echo "To remove orphaned packages:"
            echo "  update-alien-packages --action remove --target $mgr"
          fi
        fi
      }
      
      process_manager() {
        local mgr="$1"
        
        case "$ACTION" in
          update|install)
            update_packages "$mgr"
            ;;
          remove)
            remove_packages "$mgr"
            ;;
          *)
            echo "Unknown action: $ACTION"
            echo "Use --help for usage information"
            exit 1
            ;;
        esac
      }
      
      if [ "$TARGET" = "all" ]; then
        ${if builtins.attrNames nonEmptyPackages == [] then 
          ''echo "No alien packages configured for this distro"'' 
        else 
          lib.concatStringsSep "\n        " (map (mgr: ''process_manager "${mgr}"'') (builtins.attrNames nonEmptyPackages))
        }
      else
        process_manager "$TARGET"
      fi
    '';
  in {
    # Install the install script
    home.packages = [ installScript ];
    
    # Copy package lists to ~/.local/share/dots/packages/required/
    home.file = lib.mapAttrs' (mgr: packages: {
      name = ".local/share/dots/packages/required/${mgr}.txt";
      value = {
        text = lib.concatStringsSep "\n" packages;
      };
    }) nonEmptyPackages;
    
    # Make helpers available via specialArg
    _module.args.alien = { 
      inherit hasAlien mkEntry;
      # Allow modules to check if a package is in the enabled list
      isEnabled = pkgName: builtins.elem pkgName cfg.enabledPackages;
    };
  });
}
