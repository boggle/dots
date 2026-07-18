{ config, lib, pkgs, dotsLocal, ... }:

let
  distro = dotsLocal.distro;
  
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

    protectedPackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''
        Native package names that should NEVER be flagged as orphans or
        offered for removal by `update-alien-packages`, even though no
        alien spec declares them as required.

        Use this for packages dots itself doesn't manage but that other
        native packages on the system depend on (e.g. `fzf` required by
        some unrelated native tool) - the orphan detector can only reason
        about packages it manages, not arbitrary reverse-dependencies from
        packages installed outside of dots, so those need to be listed here
        explicitly to avoid a confusing/dangerous removal prompt.
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
      PROTECTED_FILE="$HOME/.local/share/dots/packages/protected.txt"
      
      mkdir -p "$INSTALLED_DIR" "$ORPHAN_DIR"

      USE_GUM=0
      if command -v gum >/dev/null 2>&1; then
        USE_GUM=1
      fi

      print_header() {
        local icon="$1"
        local title="$2"
        echo ""
        if [ "$USE_GUM" -eq 1 ]; then
          gum style --border rounded --border-foreground 69 --padding "0 1" --bold "$icon $title"
        else
          echo "============================================================"
          echo "$title"
          echo "============================================================"
        fi
        echo ""
      }
      
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
      
      # Union of packages required by ANY manager (pacman.txt, paru.txt, etc.
      # combined). Used for orphan-detection cross-checks instead of a
      # single manager's required list.
      #
      # Why this matters: pacman and paru share the exact same underlying
      # package database (paru is just an AUR-aware pacman wrapper) - a
      # package can be "required" under either manager's spec depending on
      # where it happens to live (official repo vs AUR) at any point in
      # time, and that can change (e.g. an AUR package later gets added to
      # an official repo, so its spec moves from `paru = [...]` to
      # `pacman = [...]`). Comparing only against the SAME manager's
      # required list means a package that moved from one manager's spec to
      # another's gets permanently flagged as an orphan under the OLD
      # manager forever, even though it is still required (just tracked
      # under a different manager now) and still genuinely installed -
      # "remove" would then actually uninstall a package that's still
      # wanted. Cross-checking against the union of all managers' required
      # lists avoids this false-positive class entirely.
      get_all_required() {
        # NOTE: required/*.txt files are Nix `home.file` text (built via
        # `lib.concatStringsSep "\n" packages`), which does NOT end in a
        # trailing newline. A plain `cat file1 file2` would then glue the
        # last line of file1 to the first line of file2 (e.g.
        # "zellij" + "frogmouth" -> "zellijfrogmouth"), silently dropping
        # both from the set. `awk 1` normalizes every line to be
        # newline-terminated regardless of the input file's own ending, so
        # concatenation across files is always safe.
        #
        # Also unions in PROTECTED_FILE (alienPackages.protectedPackages) -
        # packages that are never alien-managed by any spec, but that other
        # native packages depend on, so they must never be treated as
        # orphans either. See that option's description for why.
        local files=("$PKG_DIR"/*.txt)
        if [ -f "$PROTECTED_FILE" ]; then
          files+=("$PROTECTED_FILE")
        fi
        awk 1 "''${files[@]}" 2>/dev/null | sort -u
      }

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
          tdnf)
            tdnf list installed 2>/dev/null | awk 'NR>2 {print $1}' | cut -d'.' -f1 | sort -u || echo ""
            ;;
          *)
            echo ""
            ;;
        esac
      }
      
      remove_packages() {
        # NOTE: this function used to increment its counters with
        # `((counter++))`. Under `set -e` (enabled at the top of this
        # script), `((expr))` returns the shell-arithmetic truth value of
        # the *result*, and post-increment's result is the OLD value - so
        # the very first increment from 0 evaluates to `((0))`, which is
        # "false", which aborts the whole script right there under `set -e`
        # (silently, no error message). Concretely: the first time a user
        # skipped or successfully removed a package, this function would
        # exit early and any remaining orphans in the file would silently
        # never be processed. Fixed by using `counter=$((counter + 1))`
        # (a plain assignment, whose exit status is always 0) everywhere
        # instead.
        local mgr="$1"
        local orphaned_file="$ORPHAN_DIR/$mgr.txt"
        
        if [ ! -f "$orphaned_file" ] || [ ! -s "$orphaned_file" ]; then
          print_header "🗑️" "Remove Orphaned Packages - $mgr"
          echo "No orphaned packages found."
          return 0
        fi
        
        print_header "🗑️" "Remove Orphaned Packages - $mgr"
        
        local to_remove=""
        local removed_count=0
        local kept_count=0
        
        # Cross-manager safety net: never offer to remove a package that is
        # STILL required by any manager's current spec, even if it's listed
        # in this manager's (possibly stale) orphan file - see
        # get_all_required's comment for why a package can appear as an
        # orphan under one manager while still being required under another.
        local still_required
        still_required=$(get_all_required)

        # Use file descriptor 3 to read from orphan file, leaving stdin for user input
        while IFS= read -r pkg <&3; do
          [ -z "$pkg" ] && continue

          if echo "$still_required" | grep -Fxq "$pkg"; then
            echo "  ⚠️  Skipping $pkg - still required (by another manager's spec, or explicitly protected) - stale orphan entry, will self-heal on next 'update-alien-packages'"
            kept_count=$((kept_count + 1))
            continue
          fi

          printf "Remove %s? (y/N): " "$pkg"
          read -r response
          
          if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
            case "$mgr" in
              pacman|paru)
                if sudo pacman -Rns "$pkg"; then
                  echo "  ✅ Removed $pkg"
                  to_remove="$to_remove\n$pkg"
                  removed_count=$((removed_count + 1))
                else
                  echo "  ❌ Failed to remove $pkg"
                fi
                ;;
              zypper)
                if sudo zypper remove --no-confirm "$pkg"; then
                  echo "  ✅ Removed $pkg"
                  to_remove="$to_remove\n$pkg"
                  removed_count=$((removed_count + 1))
                else
                  echo "  ❌ Failed to remove $pkg"
                fi
                ;;
              tdnf)
                if sudo tdnf remove -y "$pkg"; then
                  echo "  ✅ Removed $pkg"
                  to_remove="$to_remove\n$pkg"
                  removed_count=$((removed_count + 1))
                else
                  echo "  ❌ Failed to remove $pkg"
                fi
                ;;
            esac
          else
            echo "  -> Skipped $pkg"
            kept_count=$((kept_count + 1))
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
        
        # Calculate orphans: previously_installed - (required by ANY manager)
        # (see get_all_required's comment above for why this must be the
        # cross-manager union, not just this manager's own required list)
        local orphans
        if [ -n "$previously_installed" ]; then
          orphans=$(comm -23 <(echo "$previously_installed") <(get_all_required))
        else
          orphans=""
        fi
        
        # For update action only: track + reconcile orphans (skip in dry-run)
        if [ "$ACTION" = "update" ] && [ "$DRY_RUN" -eq 0 ]; then
          # Reconcile the orphan list unconditionally (not just when there
          # are *new* orphans this run) so stale false-positive entries -
          # e.g. a package that moved from this manager's required spec to
          # another manager's - get purged automatically on the next update,
          # rather than needing a manual edit to the orphan file forever.
          local tmp_orphan
          tmp_orphan=$(mktemp)
          if [ -f "$orphaned_file" ]; then
            cat "$orphaned_file" >> "$tmp_orphan"
          fi
          if [ -n "$orphans" ]; then
            echo "$orphans" >> "$tmp_orphan"
          fi
          sort "$tmp_orphan" | uniq | comm -23 - <(get_all_required) > "$orphaned_file" || true
          rm "$tmp_orphan"
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
          print_header "📦" "Alien Package Changes - $mgr"
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
        print_header "📦" "Alien Package Manager - $mgr"
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
            tdnf)
              install_cmd="sudo tdnf install -y"
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
            print_header "⚠️" "ORPHANED PACKAGES - Review for removal"
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
    home.file = (lib.mapAttrs' (mgr: packages: {
      name = ".local/share/dots/packages/required/${mgr}.txt";
      value = {
        text = lib.concatStringsSep "\n" packages;
      };
    }) nonEmptyPackages) // (lib.optionalAttrs (cfg.protectedPackages != []) {
      ".local/share/dots/packages/protected.txt".text =
        lib.concatStringsSep "\n" cfg.protectedPackages;
    });
    
    # Make helpers available via specialArg
    _module.args.alien = { 
      inherit hasAlien mkEntry;
      # Allow modules to check if a package is in the enabled list
      isEnabled = pkgName: builtins.elem pkgName cfg.enabledPackages;
    };
  });
}
