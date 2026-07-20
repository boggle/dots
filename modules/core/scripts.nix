# scripts.nix - Generate dots helper scripts
# Creates apply-dots, dots-sync, and update-dots commands

{ config, lib, pkgs, ... }:

{
  # Create the scripts as derivations and add to packages
  home.packages = [
    (pkgs.writeShellScriptBin "apply-dots" ''
      #!/usr/bin/env bash
      # apply-dots - Apply home-manager configuration with dots-local integration
      # Usage: apply-dots [opt] [-- <nh-args>...]
      #
      # Which context bundle you get (priv/work/...) is fully determined
      # by dots-local.flake.nix's `context` field, not a CLI argument. The
      # only CLI choice here is baseline vs. optimized build:
      #
      # Examples:
      #   apply-dots                    # homeConfigurations.default (baseline)
      #   apply-dots opt                # homeConfigurations.default-opt (optimized)
      #   apply-dots -- -b backup       # Pass -b backup to nh home switch
      #   apply-dots opt -- -b backup   # Optimized build + nh flags

      set -e

      DOTS_DIR="''${DOTS_DIR:-$HOME/dots}"
      DOTS_LOCAL_DIR="''${DOTS_LOCAL_DIR:-$HOME/dots-local}"

      source ${./scripts/common.sh}

      # Parse arguments: build variant (optional) followed by -- and nh args
      VARIANT=""
      NH_ARGS=()
      FOUND_SEP=false

      for arg in "$@"; do
        if [[ "$arg" == "--" ]]; then
          FOUND_SEP=true
          continue
        fi
        if [[ "$FOUND_SEP" == true ]]; then
          NH_ARGS+=("$arg")
        elif [[ -z "$VARIANT" && ! "$arg" =~ ^- ]]; then
          VARIANT="$arg"
        fi
      done

      # Normalize the build-variant argument to an actual flake output name.
      case "$VARIANT" in
        ""|default) FLAKE_OUTPUT="default" ;;
        opt|default-opt) FLAKE_OUTPUT="default-opt" ;;
        *)
          print_error "Unknown build variant: '$VARIANT' (expected nothing, 'opt', or 'default-opt')"
          exit 1
          ;;
      esac

      print_header "✦" "DOTS CONFIGURATION"

      # Get info from dots-local (informational only now - dots-local.context
      # selects a modules/contexts/<context>.nix bundle, not a flake output)
      HOST=$(nix eval "git+file://$DOTS_LOCAL_DIR#host" 2>/dev/null | tr -d '"' || echo "unknown")
      CONTEXT=$(nix eval "git+file://$DOTS_LOCAL_DIR#context" 2>/dev/null | tr -d '"' || echo "priv")
      SYSTEM=$(nix eval "git+file://$DOTS_LOCAL_DIR#system" 2>/dev/null | tr -d '"' || echo "x86_64-linux")
      USER=$(nix eval "git+file://$DOTS_LOCAL_DIR#username" 2>/dev/null | tr -d '"' || echo "$(whoami)")

      print_section "📋" "Settings:"
      echo -e "   ''${YELLOW}Host:''${NC}      ''${GREEN}$HOST''${NC}"
      echo -e "   ''${YELLOW}Context:''${NC}   ''${GREEN}$CONTEXT''${NC}"
      echo -e "   ''${YELLOW}Build:''${NC}     ''${GREEN}$FLAKE_OUTPUT''${NC}"
      echo -e "   ''${YELLOW}System:''${NC}    ''${GREEN}$SYSTEM''${NC}"
      echo -e "   ''${YELLOW}User:''${NC}      ''${GREEN}$USER''${NC}"
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
          nh home switch "$DOTS_DIR" -c "$FLAKE_OUTPUT" "''${NH_ARGS[@]}" -- --override-input dots-local "git+file://$DOTS_LOCAL_DIR" 2>&1 | tee "$BUILD_LOG"
      else
          nh home switch "$DOTS_DIR" -c "$FLAKE_OUTPUT" -- --override-input dots-local "git+file://$DOTS_LOCAL_DIR" 2>&1 | tee "$BUILD_LOG"
      fi
      result=''${PIPESTATUS[0]}

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

      # NOTE: sync.sh already runs automatically during the switch above,
      # via the home.activation.syncUserConfigs hook
      # (modules/core/dots-local.nix) - that hook fires on every
      # activation regardless of entry point, so it's not called again
      # here.

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

    (pkgs.writeShellScriptBin "dots-local-options" ''
      #!/usr/bin/env bash
      # dots-local-options - Show every option settable in dots-local/flake.nix
      # Usage: dots-local-options [-i|--interactive] [search-term]
      #
      # Reads the option list straight from modules/local/schema.nix (via
      # the .#dotsLocalOptionsDoc flake output, generated with nixpkgs's
      # own lib.optionAttrSetToDocList - the same machinery NixOS/Home
      # Manager use for their own option docs) - so this is always exactly
      # in sync with the real schema, never a separate doc that can drift.
      #
      # Examples:
      #   dots-local-options              # show everything
      #   dots-local-options machine      # only machine.* options
      #   dots-local-options sync         # only sync.* options (enable/tracked)
      #   dots-local-options -i           # fuzzy-search/browse interactively (needs gum)
      #   dots-local-options -i machine   # interactive, pre-narrowed to machine.*

      set -e

      DOTS_DIR="''${DOTS_DIR:-$HOME/dots}"
      DOTS_LOCAL_DIR="''${DOTS_LOCAL_DIR:-$HOME/dots-local}"

      source ${./scripts/common.sh}

      INTERACTIVE=0
      FILTER=""
      for arg in "$@"; do
        case "$arg" in
          -i|--interactive) INTERACTIVE=1 ;;
          *) FILTER="$arg" ;;
        esac
      done

      print_header "📋" "dots-local options"
      if [ -n "$FILTER" ]; then
        echo -e "   ''${YELLOW}Filter:''${NC} ''${GREEN}$FILTER''${NC}"
      fi
      echo ""

      DOC_JSON=$(nix eval --json "$DOTS_DIR#dotsLocalOptionsDoc" \
        --override-input dots-local "git+file://$DOTS_LOCAL_DIR" 2>/dev/null) \
        || { print_error "Failed to evaluate .#dotsLocalOptionsDoc"; exit 1; }

      render_option() {
        # $1 = a single option's JSON object
        echo "$1" | jq -r '
          "\u001b[1;36m\(.path)\u001b[0m\n" +
          "  \u001b[1;33mtype:\u001b[0m \(.type)\n" +
          "  \u001b[1;33mdefault:\u001b[0m \(if .default == null then "(required, no default)" else .default end)\n" +
          "  " + (.description | gsub("\n"; "\n  ")) + "\n"
        '
      }

      if [ "$INTERACTIVE" -eq 1 ]; then
        if [ "$USE_GUM" -ne 1 ]; then
          print_error "Interactive mode (-i/--interactive) needs gum, which isn't on PATH."
          exit 1
        fi

        # One tab-separated "path<TAB>type<TAB>default" line per option, fed
        # to gum filter for fuzzy narrowing (path is the sortable/filterable
        # column; type+default ride along as a quick-glance preview).
        LINES=$(echo "$DOC_JSON" | jq -r --arg filter "$FILTER" '
          .[] | select($filter == "" or (.path | contains($filter))) |
          "\(.path)\t\(.type)\t\(if .default == null then "(required)" else .default end)"
        ')

        if [ -z "$LINES" ]; then
          print_error "No options match filter: $FILTER"
          exit 1
        fi

        while true; do
          SELECTED_PATH=$(echo "$LINES" | gum filter \
            --placeholder "Search dots-local options... (esc to quit)" \
            --height 20 --indicator "→" \
            --header "↑↓/type to narrow · enter to view · esc to quit" \
            | cut -f1) || break
          [ -z "$SELECTED_PATH" ] && break

          OPTION_JSON=$(echo "$DOC_JSON" | jq -c --arg path "$SELECTED_PATH" '.[] | select(.path == $path)')
          render_option "$OPTION_JSON" | gum style --border rounded --border-foreground 62 --padding "0 1"
        done
        exit 0
      fi

      echo "$DOC_JSON" | jq -r --arg filter "$FILTER" '
        .[] | select($filter == "" or (.path | contains($filter))) |
        "\u001b[1;36m\(.path)\u001b[0m\n" +
        "  \u001b[1;33mtype:\u001b[0m \(.type)\n" +
        "  \u001b[1;33mdefault:\u001b[0m \(if .default == null then "(required, no default)" else .default end)\n" +
        "  " + (.description | gsub("\n"; "\n  ")) + "\n"
      '
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

      source ${./scripts/common.sh}

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

      source ${./scripts/common.sh}

      # Get context from dots-local (used below only to locate
      # contexts/$CONTEXT/appimages/ - the shared/store-backed AppImages
      # dir, unrelated to Nix's homeConfigurations output name)
      CONTEXT=$(nix eval "git+file://$DOTS_LOCAL_DIR#context" 2>/dev/null | tr -d '"' || echo "priv")
      CONTEXT="''${CONTEXT:-priv}"

      # Get localDir from Home Manager config. NOTE: "default" here is the
      # flake output name (see flake.nix) - unrelated to $CONTEXT above.
      # localDir doesn't differ between default/default-opt.
      LOCAL_DIR=$(nix eval --raw "$DOTS_DIR#homeConfigurations.default.config.features.appimages.localDir" 2>/dev/null || echo "$HOME/Applications/AppImages")

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
      log_info "Context: $CONTEXT"
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
          if [[ -d "$DOTS_DIR/contexts/common/appimages" ]]; then
              for app_path in "$DOTS_DIR/contexts/common/appimages"/*.AppImage; do
                  [[ -f "$app_path" ]] || continue
                  app_file=$(basename "$app_path")
                  app_name="''${app_file%.AppImage}"
                  
                  if [[ -n "$TARGET_APP" && "$app_name" != "$TARGET_APP" ]]; then
                      continue
                  fi
                  
                  echo "  $app_name: Processing (contexts/common)"
                  if update_single "$app_name" "$app_path"; then
                      ((UPDATED++))
                  elif [[ $? -eq 2 ]]; then
                      ((SKIPPED++))
                  else
                      ((FAILED++))
                  fi
              done
          fi

          # Context-specific
          if [[ -d "$DOTS_DIR/contexts/$CONTEXT/appimages" ]]; then
              for app_path in "$DOTS_DIR/contexts/$CONTEXT/appimages"/*.AppImage; do
                  [[ -f "$app_path" ]] || continue
                  app_file=$(basename "$app_path")
                  app_name="''${app_file%.AppImage}"
                  
                  if [[ -n "$TARGET_APP" && "$app_name" != "$TARGET_APP" ]]; then
                      continue
                  fi
                  
                  echo "  $app_name: Processing (contexts/$CONTEXT)"
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

  # Ensure user-local bins are on PATH. NOTE: this used to also include
  # "$HOME/dots/bin" - that directory never actually existed (Phase 8
  # externalized scripts into per-module scripts/ subdirectories instead,
  # e.g. modules/features/viewer/v.sh, and this leftover PATH entry was
  # never cleaned up alongside it).
  home.sessionPath = [ "$HOME/.local/bin" ];
}
