# scripts.nix - Generate dots helper scripts
# Creates apply-dots, dots-sync, and update-dots commands

{ config, lib, pkgs, ... }:

{
  # Create the scripts as derivations and add to packages
  home.packages = [
    (pkgs.writeShellScriptBin "apply-dots" ''
      #!/usr/bin/env bash
      # apply-dots - Apply home-manager configuration with dots-local integration
      # Usage: apply-dots [profile] [-- <nh-args>...]
      #
      # Examples:
      #   apply-dots                    # Use default profile
      #   apply-dots priv               # Use specific profile
      #   apply-dots -- -b backup       # Pass -b backup to nh home switch
      #   apply-dots priv -- -b backup  # Profile + nh flags

      set -e

      DOTS_DIR="''${DOTS_DIR:-$HOME/dots}"
      DOTS_LOCAL_DIR="''${DOTS_LOCAL_DIR:-$HOME/dots-local}"

      # Colors
      BLUE='\033[0;34m'
      GREEN='\033[0;32m'
      YELLOW='\033[1;33m'
      CYAN='\033[0;36m'
      PURPLE='\033[0;35m'
      RED='\033[0;31m'
      NC='\033[0m'
      BOLD='\033[1m'

      USE_GUM=0
      if command -v gum >/dev/null 2>&1; then
        USE_GUM=1
      fi

      print_header() {
        local icon="$1"
        local title="$2"
        echo ""
        if [ "$USE_GUM" -eq 1 ]; then
          gum style --border rounded --border-foreground 62 --padding "0 1" --bold "$icon  $title"
        else
          echo "=============================================================="
          echo "$title"
          echo "=============================================================="
        fi
        echo ""
      }

      print_section() {
        local icon="$1"
        local text="$2"
        if [ "$USE_GUM" -eq 1 ]; then
          gum style --foreground 51 --bold "$icon $text"
        else
          echo -e "''${CYAN}$text''${NC}"
        fi
      }

      print_error() {
        local text="$1"
        if [ "$USE_GUM" -eq 1 ]; then
          gum style --foreground 196 --bold "✗ $text"
        else
          echo -e "''${RED}✗ $text''${NC}"
        fi
      }

      BULLET="*"
      if [ "$USE_GUM" -eq 1 ]; then
        BULLET="•"
      fi

      # Parse arguments: profile name (optional) followed by -- and nh args
      PROFILE=""
      NH_ARGS=()
      FOUND_SEP=false

      for arg in "$@"; do
        if [[ "$arg" == "--" ]]; then
          FOUND_SEP=true
          continue
        fi
        if [[ "$FOUND_SEP" == true ]]; then
          NH_ARGS+=("$arg")
        elif [[ -z "$PROFILE" && ! "$arg" =~ ^- ]]; then
          PROFILE="$arg"
        fi
      done

      # Get profile from dots-local if not provided
      if [[ -z "$PROFILE" ]]; then
          PROFILE=$(nix eval "git+file://$DOTS_LOCAL_DIR#profile" 2>/dev/null | tr -d '"' || echo "priv")
          PROFILE="''${PROFILE:-priv}"
      fi

      print_header "✦" "DOTS CONFIGURATION"

      # Get other info from dots-local
      HOST=$(nix eval "git+file://$DOTS_LOCAL_DIR#host" 2>/dev/null | tr -d '"' || echo "unknown")
      SYSTEM=$(nix eval "git+file://$DOTS_LOCAL_DIR#system" 2>/dev/null | tr -d '"' || echo "x86_64-linux")
      USER=$(nix eval "git+file://$DOTS_LOCAL_DIR#username" 2>/dev/null | tr -d '"' || echo "$(whoami)")

      print_section "📋" "Settings:"
      echo -e "   ''${YELLOW}Host:''${NC}     ''${GREEN}$HOST''${NC}"
      echo -e "   ''${YELLOW}Profile:''${NC}  ''${GREEN}$PROFILE''${NC}"
      echo -e "   ''${YELLOW}System:''${NC}   ''${GREEN}$SYSTEM''${NC}"
      echo -e "   ''${YELLOW}User:''${NC}     ''${GREEN}$USER''${NC}"
      if [[ ''${#NH_ARGS[@]} -gt 0 ]]; then
          echo -e "   ''${YELLOW}NH args:''${NC} ''${CYAN}''${NH_ARGS[*]}''${NC}"
      fi
      echo ""

      # Check sync patterns if config exists
      if [[ -f "$DOTS_LOCAL_DIR/sync-config.json" ]]; then
          print_section "📝" "Sync Patterns:"
          if command -v jq &> /dev/null; then
              count=$(jq -r '.tracked | length' "$DOTS_LOCAL_DIR/sync-config.json" 2>/dev/null || echo "0")
              if [[ "$count" -gt 0 ]]; then
                  for ((i=0; i<count; i++)); do
                      pattern=$(jq -r ".tracked[$i].pattern" "$DOTS_LOCAL_DIR/sync-config.json" 2>/dev/null)
                      type=$(jq -r ".tracked[$i].type" "$DOTS_LOCAL_DIR/sync-config.json" 2>/dev/null)
                      echo -e "   ''${PURPLE}$BULLET''${NC} ''${YELLOW}$pattern''${NC} (''${CYAN}$type''${NC})"
                  done
              else
                  echo -e "   ''${YELLOW}No patterns configured''${NC}"
              fi
          fi
          echo ""
      fi

      # Run home-manager switch
      print_section "🏠" "Running home-manager switch..."
      cd "$DOTS_DIR"

      # Create temp log file for capturing full output
      BUILD_LOG=$(mktemp /tmp/apply-dots-XXXXXX.log)

      # Build the nh command with optional extra args
      if [[ ''${#NH_ARGS[@]} -gt 0 ]]; then
          nh home switch "$DOTS_DIR" -c "$PROFILE" "''${NH_ARGS[@]}" -- --override-input dots-local "git+file://$DOTS_LOCAL_DIR" 2>&1 | tee "$BUILD_LOG"
      else
          nh home switch "$DOTS_DIR" -c "$PROFILE" -- --override-input dots-local "git+file://$DOTS_LOCAL_DIR" 2>&1 | tee "$BUILD_LOG"
      fi
      result=$?

      if [[ $result -ne 0 ]]; then
          echo ""
          print_error "Activation failed! Full log saved to:"
          echo -e "   ''${YELLOW}$BUILD_LOG''${NC}"
          echo ""
          echo -e "''${CYAN}You can view the full log with:''${NC}"
          echo -e "   cat \"''${YELLOW}$BUILD_LOG''${NC}\""
          echo ""
          echo -e "''${CYAN}Common fixes:''${NC}"
          echo -e "   ''${YELLOW}apply-dots -- -b backup''${NC}  # Backup conflicting files"
          echo -e "   ''${YELLOW}apply-dots -- --dry''${NC}      # Dry run (don't activate)"
          exit $result
      fi

      # Clean up log on success
      rm -f "$BUILD_LOG"

      echo ""
      print_section "🔗" "Creating convenience symlinks..."
      
      # Create current-profile symlink (top-level, for bash navigation)
      ln -sfn "profiles/$PROFILE" "$DOTS_DIR/current-profile"
      echo -e "   ''${GREEN}current-profile''${NC} → ''${YELLOW}profiles/$PROFILE''${NC}"
      
      # Create host.nix and distro.nix symlinks in profile directory (for bash navigation only)
      PROFILE_DIR="$DOTS_DIR/profiles/$PROFILE"
      mkdir -p "$PROFILE_DIR"
      
      if [[ -n "$HOST" && "$HOST" != "unknown" ]]; then
          HOST_FILE="$PROFILE_DIR/hosts/$HOST.nix"
          if [[ -f "$HOST_FILE" ]]; then
              ln -sfn "hosts/$HOST.nix" "$PROFILE_DIR/host.nix"
              echo -e "   ''${GREEN}profiles/$PROFILE/host.nix''${NC} → ''${YELLOW}hosts/$HOST.nix''${NC}"
          fi
      fi
      
      DISTRO=$(nix eval "git+file://$DOTS_LOCAL_DIR#distro" 2>/dev/null | tr -d '"' || echo "")
      if [[ -n "$DISTRO" ]]; then
          DISTRO_FILE="$DOTS_DIR/modules/distros/$DISTRO.nix"
          if [[ -f "$DISTRO_FILE" ]]; then
              ln -sfn "../../modules/distros/$DISTRO.nix" "$PROFILE_DIR/distro.nix"
              echo -e "   ''${GREEN}profiles/$PROFILE/distro.nix''${NC} → ''${YELLOW}modules/distros/$DISTRO.nix''${NC}"
          fi
      fi
      
      echo ""
      print_section "🔄" "Syncing handcrafted user configs..."
      "$DOTS_DIR/sync.sh" || true
      
      # Check alien packages
      echo ""
      print_section "📦" "Checking alien packages..."
      if ! update-alien-packages --dry-run --target all 2>&1; then
          echo ""
          echo -e "''${YELLOW}Run: update-alien-packages to apply changes''${NC}"
      fi
      
      # Update desktop database for AppImages
      if command -v update-desktop-database &> /dev/null; then
          print_section "📝" "Updating desktop database..."
          update-desktop-database ~/.local/share/applications/ 2>/dev/null || true
      fi

      exit 0
    '')

    (pkgs.writeShellScriptBin "dots-sync" ''
      #!/usr/bin/env bash
      # dots-sync - Wrapper for sync.sh
      # Usage: dots-sync [options]
      # All options are passed through to sync.sh

      DOTS_DIR="''${DOTS_DIR:-$HOME/dots}"

      # Pass through to actual sync script
      exec "$DOTS_DIR/sync.sh" "$@"
    '')

    (pkgs.writeShellScriptBin "update-dots" ''
      #!/usr/bin/env bash
      # update-dots - Update dots flake inputs
      # Usage: update-dots [input-name] [-- <nix-flake-update-args>...]
      #
      # Examples:
      #   update-dots                    # Update all inputs
      #   update-dots nixpkgs            # Update specific input
      #   update-dots -- --refresh       # Pass --refresh to nix flake update
      #   update-dots nixpkgs -- --refresh  # Input + extra args

      set -e

      DOTS_DIR="''${DOTS_DIR:-$HOME/dots}"
      DOTS_LOCAL_DIR="''${DOTS_LOCAL_DIR:-$HOME/dots-local}"

      # Colors
      BLUE='\033[0;34m'
      GREEN='\033[0;32m'
      YELLOW='\033[1;33m'
      CYAN='\033[0;36m'
      NC='\033[0m'
      BOLD='\033[1m'

      USE_GUM=0
      if command -v gum >/dev/null 2>&1; then
        USE_GUM=1
      fi

      print_section() {
        local icon="$1"
        local text="$2"
        if [ "$USE_GUM" -eq 1 ]; then
          gum style --foreground 99 --bold "$icon $text"
        else
          echo -e "''${BOLD}$text''${NC}"
        fi
      }

      # Parse arguments: input name (optional) followed by -- and nix flake update args
      INPUT_NAME=""
      EXTRA_ARGS=()
      FOUND_SEP=false

      for arg in "$@"; do
        if [[ "$arg" == "--" ]]; then
          FOUND_SEP=true
          continue
        fi
        if [[ "$FOUND_SEP" == true ]]; then
          EXTRA_ARGS+=("$arg")
        elif [[ -z "$INPUT_NAME" ]]; then
          INPUT_NAME="$arg"
        fi
      done

      echo ""
      print_section "🔄" "Updating dots flake inputs..."
      echo ""

      cd "$DOTS_DIR"

      if [[ -n "$INPUT_NAME" ]]; then
          echo -e "''${YELLOW}Updating input: $INPUT_NAME''${NC}"
          if [[ ''${#EXTRA_ARGS[@]} -gt 0 ]]; then
              echo -e "''${CYAN}Extra args: ''${EXTRA_ARGS[*]}''${NC}"
              nix flake update "$INPUT_NAME" "''${EXTRA_ARGS[@]}" --override-input dots-local "git+file://$DOTS_LOCAL_DIR"
          else
              nix flake update "$INPUT_NAME" --override-input dots-local "git+file://$DOTS_LOCAL_DIR"
          fi
      else
          echo -e "''${YELLOW}Updating all inputs...''${NC}"
          if [[ ''${#EXTRA_ARGS[@]} -gt 0 ]]; then
              echo -e "''${CYAN}Extra args: ''${EXTRA_ARGS[*]}''${NC}"
              nix flake update "''${EXTRA_ARGS[@]}" --override-input dots-local "git+file://$DOTS_LOCAL_DIR"
          else
              nix flake update --override-input dots-local "git+file://$DOTS_LOCAL_DIR"
          fi
      fi

      echo ""
      if [ "$USE_GUM" -eq 1 ]; then
          gum style --foreground 42 --bold "✅ Flake inputs updated successfully!"
      else
          echo -e "''${GREEN}Flake inputs updated successfully!''${NC}"
      fi
      echo -e "''${BLUE}Run 'apply-dots' to apply the changes.''${NC}"
      echo ""
    '')

    (pkgs.writeShellScriptBin "appimage-update" ''
      #!/usr/bin/env bash
      # appimage-update - Update AppImages
      # Usage: appimage-update [app-name] [--all] [--unregistered] [--include-shared]

      DOTS_LOCAL_DIR="''${DOTS_LOCAL_DIR:-$HOME/dots-local}"
      DOTS_DIR="''${DOTS_DIR:-$HOME/dots}"

      # Colors
      GREEN='\033[0;32m'
      YELLOW='\033[1;33m'
      CYAN='\033[0;36m'
      RED='\033[0;31m'
      NC='\033[0m'

      log_info() { echo -e "''${CYAN}[INFO]''${NC} $1"; }
      log_success() { echo -e "''${GREEN}[OK]''${NC} $1"; }
      log_warn() { echo -e "''${YELLOW}[WARN]''${NC} $1"; }
      log_error() { echo -e "''${RED}[ERROR]''${NC} $1"; }

      # Get profile from dots-local
      PROFILE=$(nix eval "git+file://$DOTS_LOCAL_DIR#profile" 2>/dev/null | tr -d '"' || echo "priv")
      PROFILE="''${PROFILE:-priv}"

      # Get localDir from Home Manager config
      LOCAL_DIR=$(nix eval --raw "$DOTS_DIR#homeConfigurations.$PROFILE.config.features.appimages.localDir" 2>/dev/null || echo "$HOME/Applications/AppImages")

      # Parse arguments
      UPDATE_ALL=false
      UNREGISTERED=false
      INCLUDE_SHARED=false
      TARGET_APP=""

      for arg in "$@"; do
          case "$arg" in
              --all)
                  UPDATE_ALL=true
                  ;;
              --unregistered)
                  UNREGISTERED=true
                  ;;
              --include-shared)
                  INCLUDE_SHARED=true
                  ;;
              --help|-h)
                  echo "Usage: appimage-update [options] [app-name]"
                  echo ""
                  echo "Update AppImages using appimageupdatetool."
                  echo ""
                  echo "Options:"
                  echo "  --all              Update all AppImages (registered + unregistered + shared)"
                  echo "  --unregistered     Also update unregistered AppImages in localDir"
                  echo "  --include-shared   Also update shared AppImages from dots/ (modifies dots repo)"
                  echo "  --help             Show this help"
                  echo ""
                  echo "By default, only updates registered host-local AppImages."
                  echo ""
                  echo "Updates use 'appimageupdatetool -r' which removes the old file after"
                  echo "successful update. This handles versioned filenames where the new release"
                  echo "has a different version in the filename."
                  echo ""
                  echo "Examples:"
                  echo "  appimage-update              # Update registered host-local apps"
                  echo "  appimage-update steam        # Update specific app"
                  echo "  appimage-update --unregistered # Update all AppImages in \$LOCAL_DIR"
                  echo "  appimage-update --all        # Update everything"
                  exit 0
                  ;;
              -*)
                  log_error "Unknown option: $arg"
                  exit 1
                  ;;
              *)
                  if [[ -z "$TARGET_APP" ]]; then
                      TARGET_APP="$arg"
                  fi
                  ;;
          esac
      done

      echo ""
      log_info "Local directory: $LOCAL_DIR"
      log_info "Profile: $PROFILE"
      if [[ -n "$TARGET_APP" ]]; then
          log_info "Target: $TARGET_APP"
      elif [[ "$UPDATE_ALL" == "true" ]]; then
          log_info "Target: all (registered + unregistered + shared)"
      elif [[ "$UNREGISTERED" == "true" ]]; then
          log_info "Target: registered + unregistered"
      else
          log_info "Target: registered host-local apps"
      fi
      echo ""

      # Track results
      UPDATED=0
      SKIPPED=0
      FAILED=0
      
      # Track processed files to avoid duplicates
      declare -A PROCESSED_FILES

      # Function to update a single AppImage
      update_single() {
          local app_name="$1"
          local app_path="$2"
          
          echo "  $app_name: Checking for updates..."
          
          if [[ ! -f "$app_path" ]]; then
              log_warn "File not found: $app_path"
              return 1
          fi
          
          # Record if executable
          local was_exec=0
          [[ -x "$app_path" ]] && was_exec=1
          
          # Try to update
          if appimageupdatetool -r "$app_path" >/dev/null 2>&1; then
              # Restore exec bit if needed and was executable
              if [[ $was_exec -eq 1 ]] && [[ -f "$app_path" ]] && [[ ! -x "$app_path" ]]; then
                  chmod +x "$app_path"
              fi
              log_success "Updated"
              return 0
          else
              # Check if not updateable
              if appimageupdatetool --check-for-update "$app_path" 2>&1 | grep -q "No update information"; then
                  log_warn "No embedded update info"
                  return 2
              else
                  log_error "Update failed"
                  return 1
              fi
          fi
      }

      # Process registered apps
      log_info "Processing registered host-local AppImages..."
      
      # Read manifest
      REGISTERED_JSON=$(nix eval --json "git+file://$DOTS_LOCAL_DIR#appimages" 2>/dev/null)
      if [[ -z "$REGISTERED_JSON" ]]; then
          log_warn "Could not read appimages manifest from dots-local"
      else
          # Get app names
          APP_LIST=$(echo "$REGISTERED_JSON" | jq -r 'keys[]' 2>/dev/null)
          
          if [[ -z "$APP_LIST" ]]; then
              log_warn "No apps found in manifest"
          else
              # Process each app using here-string to avoid subshell
              while read -r app_name; do
                  [[ -z "$app_name" ]] && continue
                  
                  # Skip if targeting specific app
                  if [[ -n "$TARGET_APP" && "$app_name" != "$TARGET_APP" ]]; then
                      continue
                  fi
                  
                  # Get file pattern using jq with proper variable passing
                  file_pattern=$(echo "$REGISTERED_JSON" | jq -r --arg name "$app_name" '.[$name].file // empty' 2>/dev/null)
                  if [[ -z "$file_pattern" ]]; then
                      echo "  $app_name: No file pattern defined"
                      continue
                  fi
                  
                  # Find matching files
                  matches=$(find "$LOCAL_DIR" -maxdepth 1 -name "$file_pattern" -type f 2>/dev/null)
                  count=$(echo "$matches" | grep -c '^' 2>/dev/null || echo "0")
                  
                  if [[ "$count" -eq 0 ]]; then
                      echo "  $app_name: No file matching '$file_pattern'"
                      continue
                  fi
                  
                  if [[ "$count" -gt 1 ]]; then
                      log_error "Multiple files matching '$file_pattern':"
                      echo "$matches" | sed 's/^/    /'
                      echo "    Please keep only one version."
                      ((FAILED++))
                      continue
                  fi
                  
                  # Single match found
                  app_path=$(echo "$matches" | head -1)
                  app_file=$(basename "$app_path")
                  
                  # Mark as processed (by filename)
                  PROCESSED_FILES[$app_file]=1
                  
                  echo "  $app_name: Found $app_file"
                  
                  if update_single "$app_name" "$app_path"; then
                      ((UPDATED++))
                  elif [[ $? -eq 2 ]]; then
                      ((SKIPPED++))
                  else
                      ((FAILED++))
                  fi
              done <<< "$APP_LIST"
          fi
      fi

      # Process unregistered apps if requested
      if [[ "$UNREGISTERED" == "true" || "$UPDATE_ALL" == "true" ]]; then
          echo ""
          log_info "Processing unregistered AppImages..."
          
          if [[ -d "$LOCAL_DIR" ]]; then
              for app_path in "$LOCAL_DIR"/*.AppImage; do
                  [[ -f "$app_path" ]] || continue
                  
                  app_file=$(basename "$app_path")
                  
                  # Skip if already processed (check by filename)
                  if [[ -n "''${PROCESSED_FILES[$app_file]}" ]]; then
                      continue
                  fi
                  
                  app_name="''${app_file%.AppImage}"
                  
                  # Skip if targeting specific app
                  if [[ -n "$TARGET_APP" && "$app_name" != "$TARGET_APP" ]]; then
                      continue
                  fi
                  
                  echo "  $app_name: Processing (unregistered)"
                  if update_single "$app_name" "$app_path"; then
                      ((UPDATED++))
                  elif [[ $? -eq 2 ]]; then
                      ((SKIPPED++))
                  else
                      ((FAILED++))
                  fi
              done
          fi
      fi

      # Process shared apps if requested
      if [[ "$INCLUDE_SHARED" == "true" || "$UPDATE_ALL" == "true" ]]; then
          echo ""
          log_info "Processing shared AppImages from dots/..."
          
          # Common
          if [[ -d "$DOTS_DIR/profiles/common/appimages" ]]; then
              for app_path in "$DOTS_DIR/profiles/common/appimages"/*.AppImage; do
                  [[ -f "$app_path" ]] || continue
                  app_file=$(basename "$app_path")
                  app_name="''${app_file%.AppImage}"
                  
                  if [[ -n "$TARGET_APP" && "$app_name" != "$TARGET_APP" ]]; then
                      continue
                  fi
                  
                  echo "  $app_name: Processing (profiles/common)"
                  if update_single "$app_name" "$app_path"; then
                      ((UPDATED++))
                  elif [[ $? -eq 2 ]]; then
                      ((SKIPPED++))
                  else
                      ((FAILED++))
                  fi
              done
          fi

          # Profile-specific
          if [[ -d "$DOTS_DIR/profiles/$PROFILE/appimages" ]]; then
              for app_path in "$DOTS_DIR/profiles/$PROFILE/appimages"/*.AppImage; do
                  [[ -f "$app_path" ]] || continue
                  app_file=$(basename "$app_path")
                  app_name="''${app_file%.AppImage}"
                  
                  if [[ -n "$TARGET_APP" && "$app_name" != "$TARGET_APP" ]]; then
                      continue
                  fi
                  
                  echo "  $app_name: Processing (profiles/$PROFILE)"
                  if update_single "$app_name" "$app_path"; then
                      ((UPDATED++))
                  elif [[ $? -eq 2 ]]; then
                      ((SKIPPED++))
                  else
                      ((FAILED++))
                  fi
              done
          fi
      fi

      echo ""
      log_info "Results: $UPDATED updated, $SKIPPED not updateable, $FAILED failed"
      echo ""
      
      if [[ $UPDATED -gt 0 ]]; then
          if [[ "$INCLUDE_SHARED" == "true" || "$UPDATE_ALL" == "true" ]]; then
              log_info "Run apply-dots to activate any updated shared AppImages"
          fi
      fi
    '')
  ];

  # Ensure user-local and repo helper bins are on PATH
  home.sessionPath = [ "$HOME/.local/bin" "$HOME/dots/bin" ];
}
