#!/usr/bin/env bash
# sync.sh - Manage handcrafted configs between system and git
# Maps: settings/<hostname>/home/** → ~/**
#       settings/<hostname>/root/** → /**
#
# Usage: ./sync.sh [-f] [-n] [-i] [-g] [--help]
#   (no flags)      Capture missing/changed files: System → Git
#   -f, --force     Full sync System → Git (overwrite git + remove orphans)
#   -n, --dry-run   Preview what would happen
#   -i, --install   Generate script: Git → System (reverse)
#   -g, --force-regen  Force-regenerate sync-config.json from dots-local's
#                      flake.nix even if it's not stale (normally this only
#                      happens automatically when flake.nix is newer)
#   --help          Show this help

DOTS_DIR="${DOTS_DIR:-$(cd "$(dirname "$0")" && pwd)}"
DOTS_LOCAL_DIR="${DOTS_LOCAL_DIR:-$HOME/dots-local}"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_prompt() { echo -e "${CYAN}[PROMPT]${NC} $1"; }
log_system() { echo -e "${BLUE}[SYSTEM]${NC} $1"; }

# Check jq is available
if ! command -v jq &> /dev/null; then
    log_error "jq is required but not installed"
    exit 1
fi

# Get hostname
CURRENT_HOSTNAME=$(cat /proc/sys/kernel/hostname 2>/dev/null || /bin/hostname 2>/dev/null || echo "unknown")

# Get context from dots-local
get_context_from_dots_local() {
    # Try to get context from dots-local flake input
    # This is passed via the apply-dots function or can be read from nix eval
    if command -v nix &> /dev/null && [[ -d "$DOTS_LOCAL_DIR" ]]; then
        nix eval "git+file://$DOTS_LOCAL_DIR#context" 2>/dev/null | tr -d '"' || echo "priv"
    else
        echo "priv"
    fi
}

# Load global ignores from context sync files
load_global_ignores() {
    local context="$1"
    local global_ignores=()
    
    # Load common if exists (skip silently if not)
    local common_file="$DOTS_DIR/contexts/common/sync.json"
    if [[ -f "$common_file" ]]; then
        while IFS= read -r pattern; do
            [[ -n "$pattern" ]] && global_ignores+=("$pattern")
        done < <(jq -r '.global_ignores[]?' "$common_file" 2>/dev/null)
    fi
    
    # Load context-specific ignores. NOTE: `context` here is dotsLocal's
    # `context` field (e.g. "priv"/"work") - it never has a "-opt" suffix;
    # that distinction belongs only to the flake output name
    # (homeConfigurations.default/default-opt), which is a separate,
    # unrelated axis (baseline vs. optimized build), not a context variant.
    local context_file="$DOTS_DIR/contexts/$context/sync.json"
    if [[ -f "$context_file" ]]; then
        while IFS= read -r pattern; do
            [[ -n "$pattern" ]] && global_ignores+=("$pattern")
        done < <(jq -r '.global_ignores[]?' "$context_file" 2>/dev/null)
    fi
    
    printf '%s\n' "${global_ignores[@]}"
}


# Load local config from dots-local
load_local_config() {
    local local_config="$DOTS_LOCAL_DIR/sync-config.json"
    if [[ -f "$local_config" ]]; then
        cat "$local_config"
    else
        echo '{"tracked":[]}'
    fi
}

# Check and regenerate sync-config.json if needed
#
# dots-local's `#sync` output is `{ enable = [ "name" ... ]; tracked = [
# ...raw ad-hoc entries...]; }`. `enable`'s names are resolved against
# dots's shared syncables registry (modules/core/syncables.nix) here,
# then combined with `tracked`'s raw entries - the final merged list is
# what gets written to sync-config.json in the same `{tracked: [...]}`
# shape the rest of this script already consumes, so nothing downstream
# needs to know about the enable/registry split at all.
ensure_sync_config_current() {
    local force_regen="${1:-false}"
    local config_file="$DOTS_LOCAL_DIR/sync-config.json"
    local flake_file="$DOTS_LOCAL_DIR/flake.nix"
    local syncables_file="$DOTS_DIR/modules/core/syncables.nix"
    
    # Check if we need to regenerate (dots-local's flake.nix changed, or
    # dots's own syncables registry changed - either can affect the
    # resolved output)
    if [[ "$force_regen" == "true" ]] || [[ ! -f "$config_file" ]] \
        || [[ "$flake_file" -nt "$config_file" ]] \
        || { [[ -f "$syncables_file" ]] && [[ "$syncables_file" -nt "$config_file" ]]; }; then
        log_info "Regenerating sync-config.json from dots-local flake.nix + dots's syncables registry..."
        if [[ -d "$DOTS_LOCAL_DIR" ]] && command -v nix &> /dev/null; then
            local local_sync syncables_json
            local_sync=$(cd "$DOTS_LOCAL_DIR" && nix eval --json .#sync 2>/dev/null)
            if [[ -z "$local_sync" ]]; then
                log_warn "Failed to regenerate sync-config.json (no sync config in flake.nix?)"
                return
            fi
            syncables_json=$(nix eval --json --file "$syncables_file" 2>/dev/null)
            [[ -z "$syncables_json" ]] && syncables_json='{}'

            # Warn (don't fail) about any enabled name with no matching
            # registry entry - likely a typo, but shouldn't block sync.
            local unknown
            unknown=$(echo "$local_sync" | jq -r --argjson syncables "$syncables_json" \
                '(.enable // [])[] as $n | select(($syncables[$n] // null) == null) | $n')
            if [[ -n "$unknown" ]]; then
                while IFS= read -r name; do
                    log_warn "sync.enable references unknown syncable '$name' (no entry in modules/core/syncables.nix) - ignored"
                done <<< "$unknown"
            fi

            if echo "$local_sync" | jq --argjson syncables "$syncables_json" '
                {
                  tracked: (
                    [ (.enable // [])[] as $name | $syncables[$name] // empty ]
                    + (.tracked // [])
                  )
                }
            ' > "$config_file" 2>/dev/null; then
                log_system "Regenerated: $config_file"
            else
                log_warn "Failed to regenerate sync-config.json"
            fi
        else
            log_warn "Cannot regenerate: dots-local not found or nix not available"
        fi
    fi
}

# Verify config exists and is valid
verify_config() {
    local local_config="$DOTS_LOCAL_DIR/sync-config.json"
    if [[ ! -f "$local_config" ]]; then
        log_error "Local sync config not found: $local_config"
        log_error "Run setup.sh in dots-local to generate it"
        return 1
    fi
    return 0
}

# Get base path for a file type
get_base_path() {
    local type="$1"
    case "$type" in
        home) echo "$DOTS_DIR/settings/$CURRENT_HOSTNAME/home" ;;
        root) echo "$DOTS_DIR/settings/$CURRENT_HOSTNAME/root" ;;
        *) echo "$DOTS_DIR/settings/$CURRENT_HOSTNAME/home" ;;
    esac
}

# Get destination base for a file type
get_dest_base() {
    local type="$1"
    case "$type" in
        home) echo "$HOME" ;;
        root) echo "" ;;
        *) echo "$HOME" ;;
    esac
}

# Match glob pattern (basic support for * and **)
match_glob() {
    local pattern="$1"
    local path="$2"
    
    local regex="$pattern"
    # Step 1: Mark **/ (zero or more dirs + slash) with placeholder
    regex="${regex//\*\*\//__DOUBLESLASH__}"
    # Step 2: Mark ** (zero or more dirs) with different placeholder  
    regex="${regex//\*\*/__DOUBLESTAR__}"
    # Step 3: Convert single * (anything except /)
    regex="${regex//\*/[^/]*}"
    # Step 4: Convert ** (must come after * conversion)
    regex="${regex//__DOUBLESTAR__/.*}"
    # Step 5: Convert **/ (must come after * conversion)
    regex="${regex//__DOUBLESLASH__/(.*\/)?}"
    
    [[ "$path" =~ ^$regex$ ]]
}

# Check if file matches any pattern in ignore list
should_ignore() {
    local filepath="$1"
    shift
    local ignores=("$@")
    local pattern
    
    for pattern in "${ignores[@]}"; do
        if [[ "$pattern" == !* ]]; then
            local neg_pattern="${pattern:1}"
            if match_glob "$neg_pattern" "$filepath"; then
                return 1
            fi
        else
            if match_glob "$pattern" "$filepath"; then
                return 0
            fi
        fi
    done
    
    return 1
}

# Find all files matching a pattern
find_matching_files() {
    local base_dir="$1"
    local pattern="$2"
    shift 2
    local ignores=("$@")
    
    local search_dir="$base_dir"
    local file_pattern="$pattern"
    
    if [[ "$pattern" == */* ]]; then
        local dir_part="${pattern%/*}"
        file_pattern="${pattern##*/}"
        search_dir="$base_dir/$dir_part"
        if [[ "$pattern" == */ ]]; then
            file_pattern="*"
        fi
    fi
    
    if [[ ! -d "$search_dir" ]]; then
        return 0
    fi
    
    local files=()
    
    if [[ "$pattern" == *\*\** || "$pattern" == */ ]]; then
        while IFS= read -r -d '' file; do
            local rel_path="${file#$base_dir/}"
            if match_glob "$pattern" "$rel_path"; then
                if ! should_ignore "$rel_path" "${ignores[@]}"; then
                    files+=("$rel_path")
                fi
            fi
        done < <(find "$search_dir" -type f -print0 2>/dev/null)
    else
        while IFS= read -r -d '' file; do
            local rel_path="${file#$base_dir/}"
            if match_glob "$pattern" "$rel_path"; then
                if ! should_ignore "$rel_path" "${ignores[@]}"; then
                    files+=("$rel_path")
                fi
            fi
        done < <(find "$search_dir" -maxdepth 1 -type f -name "$file_pattern" -print0 2>/dev/null)
    fi
    
    printf '%s\n' "${files[@]}"
}

# Prompt user for yes/no
prompt_yes_no() {
    local message="$1"
    echo -e "${CYAN}[PROMPT]${NC} $message [y/N]: " >&2
    if [[ -e /dev/tty ]]; then
        read -r response < /dev/tty
    else
        read -r response
    fi
    [[ "$response" =~ ^[Yy]$ ]]
}

# Capture file from system to git
capture_file() {
    local rel_path="$1"
    local type="$2"
    local force="$3"
    local on_new="$4"
    local dry_run="$5"
    
    local git_base=$(get_base_path "$type")
    local dest_base=$(get_dest_base "$type")
    
    local git_file="$git_base/$rel_path"
    local dest_file="$dest_base/$rel_path"
    
    if [[ "$dry_run" != "true" ]]; then
        mkdir -p "$(dirname "$git_file")" || { log_error "Failed to create directory for $rel_path"; return 1; }
    fi
    
    if diff -q "$dest_file" "$git_file" > /dev/null 2>&1; then
        log_info "Unchanged: $rel_path"
        return
    fi
    
    if [[ "$force" == "true" ]]; then
        if [[ "$dry_run" == "true" ]]; then
            echo "[DRY-RUN] Would update git: $rel_path"
        else
            cp "$dest_file" "$git_file" || { log_error "Failed to update $rel_path"; return 1; }
            log_system "Updated: $rel_path"
        fi
    else
        log_warn "Changed (use -f to update git): $rel_path"
    fi
}

# Capture new file from system to git  
capture_new_file() {
    local rel_path="$1"
    local type="$2"
    local on_new="$3"
    local force="$4"
    local dry_run="$5"
    
    local git_base=$(get_base_path "$type")
    local dest_base=$(get_dest_base "$type")
    
    local git_file="$git_base/$rel_path"
    local dest_file="$dest_base/$rel_path"
    
    if [[ "$dry_run" != "true" ]]; then
        mkdir -p "$(dirname "$git_file")" || { log_error "Failed to create directory for $rel_path"; return 1; }
    fi
    
    local effective_on_new="$on_new"
    if [[ "$force" == "true" && "$on_new" == "prompt" ]]; then
        effective_on_new="auto"
    fi
    
    case "$effective_on_new" in
        auto)
            if [[ "$dry_run" == "true" ]]; then
                echo "[DRY-RUN] Would capture: $rel_path"
            else
                cp "$dest_file" "$git_file" || { log_error "Failed to copy $rel_path"; return 1; }
                log_system "Captured: $rel_path"
            fi
            ;;
        ignore)
            log_info "Ignored (on_new=ignore): $rel_path"
            ;;
        prompt)
            if [[ "$dry_run" == "true" ]]; then
                echo "[DRY-RUN] Would prompt for: $rel_path"
            elif prompt_yes_no "New file $rel_path - capture to git?"; then
                cp "$dest_file" "$git_file" || { log_error "Failed to copy $rel_path"; return 1; }
                log_system "Captured: $rel_path"
            else
                log_info "Skipped: $rel_path"
            fi
            ;;
    esac
}

# Handle orphaned file (in git but deleted from system)
handle_orphan() {
    local rel_path="$1"
    local type="$2"
    local on_new="$3"
    local force="$4"
    local dry_run="$5"
    
    local git_base=$(get_base_path "$type")
    local git_file="$git_base/$rel_path"
    
    if [[ "$force" == "true" ]]; then
        if [[ "$dry_run" == "true" ]]; then
            echo "[DRY-RUN] Would remove from git (deleted from system): $rel_path"
        else
            rm -f "$git_file"
            local dir="$(dirname "$git_file")"
            while [[ "$dir" != "$git_base" && -d "$dir" ]]; do
                if [[ -z "$(ls -A "$dir" 2>/dev/null)" ]]; then
                    rmdir "$dir" 2>/dev/null || true
                fi
                dir="$(dirname "$dir")"
            done
            log_warn "Removed from git (deleted from system): $rel_path"
        fi
    else
        case "$on_new" in
            prompt)
                if [[ "$dry_run" == "true" ]]; then
                    echo "[DRY-RUN] Would prompt: Delete $rel_path from git (file removed from system)?"
                elif prompt_yes_no "File $rel_path was deleted from system - also delete from git?"; then
                    rm -f "$git_file"
                    log_warn "Removed from git: $rel_path"
                else
                    log_info "Kept in git (orphan): $rel_path"
                fi
                ;;
            *)
                log_warn "Deleted from system (use -f to remove from git, or on_new=prompt to decide): $rel_path"
                ;;
        esac
    fi
}

generate_install_script() {
    local force="$1"
    
    echo "#!/bin/bash"
    echo "# Generated: Git → System"
    echo "# Host: $CURRENT_HOSTNAME"
    echo "# Date: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    local local_config="$DOTS_LOCAL_DIR/sync-config.json"
    local count=$(jq '.tracked | length' "$local_config")
    [[ $count -eq 0 ]] && echo "# No tracked patterns" && echo "exit 0" && return
    
    local missing_home=()
    local missing_root=()
    local changed_home=()
    local changed_root=()
    
    for ((i=0; i<count; i++)); do
        local pattern=$(jq -r ".tracked[$i].pattern" "$local_config")
        local type=$(jq -r ".tracked[$i].type // \"home\"" "$local_config")
        local ignores=($(jq -r ".tracked[$i].ignore[]?" "$local_config" 2>/dev/null || true))
        
        local git_base=$(get_base_path "$type")
        local dest_base=$(get_dest_base "$type")
        
        while IFS= read -r rel_path; do
            [[ -z "$rel_path" ]] && continue
            
            local git_file="$git_base/$rel_path"
            local dest_file="$dest_base/$rel_path"
            
            if [[ ! -e "$dest_file" ]]; then
                if [[ "$type" == "root" ]]; then
                    missing_root+=("$git_file|$dest_file|$rel_path")
                else
                    missing_home+=("$git_file|$dest_file|$rel_path")
                fi
            elif ! diff -q "$git_file" "$dest_file" > /dev/null 2>&1; then
                if [[ "$force" == "true" ]]; then
                    if [[ "$type" == "root" ]]; then
                        changed_root+=("$git_file|$dest_file|$rel_path")
                    else
                        changed_home+=("$git_file|$dest_file|$rel_path")
                    fi
                fi
            fi
        done < <(find_matching_files "$git_base" "$pattern" "${ignores[@]}")
    done
    
    if [[ ${#missing_home[@]} -gt 0 || ${#missing_root[@]} -gt 0 ]]; then
        echo "# === MISSING ON SYSTEM ==="
        echo ""
        [[ ${#missing_home[@]} -gt 0 ]] && echo "# --- Home files ---" && ""
        for entry in "${missing_home[@]}"; do
            IFS='|' read -r git_file dest_file rel_path <<< "$entry"
            echo "mkdir -p \"$(dirname "$dest_file")\""
            echo "cp \"$git_file\" \"$dest_file\""
            echo "echo \"Installed: ~/$rel_path\""
            echo ""
        done
        
        [[ ${#missing_root[@]} -gt 0 ]] && echo "# --- System files (sudo) ---" && ""
        for entry in "${missing_root[@]}"; do
            IFS='|' read -r git_file dest_file rel_path <<< "$entry"
            echo "sudo mkdir -p \"$(dirname "$dest_file")\""
            echo "sudo cp \"$git_file\" \"$dest_file\""
            echo "echo \"Installed: $rel_path\""
            echo ""
        done
    fi
    
    if [[ ${#changed_home[@]} -gt 0 || ${#changed_root[@]} -gt 0 ]]; then
        echo ""
        echo "# === CHANGED ON SYSTEM (will overwrite) ==="
        echo ""
        for entry in "${changed_home[@]}"; do
            IFS='|' read -r git_file dest_file rel_path <<< "$entry"
            echo "cp \"$dest_file\" \"${dest_file}.backup.\$(date +%Y%m%d_%H%M%S)\""
            echo "cp \"$git_file\" \"$dest_file\""
            echo ""
        done
        for entry in "${changed_root[@]}"; do
            IFS='|' read -r git_file dest_file rel_path <<< "$entry"
            echo "sudo cp \"$dest_file\" \"${dest_file}.backup.\$(date +%Y%m%d_%H%M%S)\""
            echo "sudo cp \"$git_file\" \"$dest_file\""
            echo ""
        done
    fi
    
    echo "# Done!"
}

# Main function
main() {
    local force=false
    local dry_run=false
    local install_mode=false
    local force_regen=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--force) force=true; shift ;;
            -n|--dry-run) dry_run=true; shift ;;
            -i|--install) install_mode=true; shift ;;
            -g|--force-regen) force_regen=true; shift ;;
            -h|--help)
                echo "Usage: $0 [-f] [-n] [-i] [-g] [-h]"
                echo ""
                echo "Sync handcrafted configs:"
                echo "  (no flags)    Capture System→Git (respects per-pattern on_new setting)"
                echo "  -f, --force   Force System→Git (overwrite + remove orphans)"
                echo "  -n, --dry-run Dry run (preview only)"
                echo "  -i, --install Install mode: Git→System (reverse)"
                echo "  -g, --force-regen  Force-regenerate sync-config.json from flake.nix"
                echo "  -h, --help    Show this help"
                echo ""
                echo "Configuration:"
                echo "  Global ignores: dots/contexts/<context>/sync.json"
                echo "  Local tracked:  dots-local/sync-config.json (generated from flake.nix)"
                exit 0
                ;;
            *) log_error "Unknown: $1"; exit 1 ;;
        esac
    done
     
    if [[ "$install_mode" == "true" ]]; then
        generate_install_script "$force"
        exit 0
    fi
    
    # Ensure sync-config.json is current (regenerate if flake.nix is newer,
    # or unconditionally if -g/--force-regen was passed)
    ensure_sync_config_current "$force_regen"
    
    # Verify local config exists
    if ! verify_config; then
        exit 1
    fi
    
    # Get context
    local context=$(get_context_from_dots_local)
    log_info "Context: $context"
    
    # Load global ignores (disable glob expansion)
    local global_ignores=()
    set -f
    while IFS= read -r ignore_pattern; do
        [[ -n "$ignore_pattern" ]] && global_ignores+=("$ignore_pattern")
    done < <(load_global_ignores "$context")
    set +f
    if [[ ${#global_ignores[@]} -gt 0 ]]; then
        log_info "Global ignores: ${#global_ignores[@]} patterns"
    fi
    
    # Load local config
    local local_config=$(load_local_config)
    local count=$(echo "$local_config" | jq '.tracked | length')
    [[ $count -eq 0 ]] && log_warn "No tracked patterns in local config" && exit 0
    
    log_info "Found $count tracked pattern(s)"
    echo ""
    
    for ((i=0; i<count; i++)); do
        local pattern=$(echo "$local_config" | jq -r ".tracked[$i].pattern")
        local type=$(echo "$local_config" | jq -r ".tracked[$i].type // \"home\"")
        local on_new=$(echo "$local_config" | jq -r ".tracked[$i].on_new // \"prompt\"")
        # Load pattern-specific ignores (disable glob expansion to prevent pattern expansion)
        local pattern_ignores=()
        set -f
        while IFS= read -r ignore_pattern; do
            [[ -n "$ignore_pattern" ]] && pattern_ignores+=("$ignore_pattern")
        done < <(echo "$local_config" | jq -r ".tracked[$i].ignore[]?" 2>/dev/null || true)
        set +f
        
        # Combine global and pattern ignores
        local ignores=("${global_ignores[@]}" "${pattern_ignores[@]}")
        
        log_info "Processing: $pattern ($type)"
        
        local git_base=$(get_base_path "$type")
        local dest_base=$(get_dest_base "$type")
        local files_found=0
        declare -A processed_files
        
        # Phase 1: Find all files on system and process them
        while IFS= read -r rel_path; do
            [[ -z "$rel_path" ]] && continue
            files_found=$((files_found + 1))
            processed_files["$rel_path"]=1
            
            local git_file="$git_base/$rel_path"
            local dest_file="$dest_base/$rel_path"
            
            if [[ -e "$git_file" ]]; then
                capture_file "$rel_path" "$type" "$force" "$on_new" "$dry_run"
            else
                capture_new_file "$rel_path" "$type" "$on_new" "$force" "$dry_run"
            fi
        done < <(find_matching_files "$dest_base" "$pattern" "${ignores[@]}")
        
        # Phase 2: Find orphaned files (in git but not on system)
        # NOTE: Don't apply ignore patterns here - we need to find ALL files in git
        # so that previously-tracked files that now match ignores are detected as orphans
        local orphans_found=0
        while IFS= read -r rel_path; do
            [[ -z "$rel_path" ]] && continue
            [[ -n "${processed_files[$rel_path]}" ]] && continue
            
            orphans_found=$((orphans_found + 1))
            handle_orphan "$rel_path" "$type" "$on_new" "$force" "$dry_run"
        done < <(find_matching_files "$git_base" "$pattern")
        
        if [[ $files_found -eq 0 && $orphans_found -eq 0 ]]; then
            log_warn "Pattern matched no files: $pattern"
        elif [[ $files_found -gt 0 ]]; then
            log_info "Processed $files_found file(s)"
        fi
        
        if [[ $orphans_found -gt 0 ]]; then
            log_warn "Found $orphans_found orphaned file(s) in git (deleted from system)"
        fi
        
        echo ""
    done
    
    log_info "Capture complete!"
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
