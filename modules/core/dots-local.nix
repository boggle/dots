# dots-local integration module
# Displays configuration info and runs sync on activation for all profiles

{ config, lib, pkgs, dotsLocal, ... }:

let
  # dotsLocal.host is nullable (no default host file) - `or` only helps for
  # missing attrs, not a present-but-null value, so this needs an explicit
  # check rather than `dotsLocal.host or "unknown"`.
  hostOrUnknown = if dotsLocal.host != null then dotsLocal.host else "unknown";
  hostOrEmpty = if dotsLocal.host != null then dotsLocal.host else "";
in
{
  # Pretty print dots-local configuration on activation
  home.activation.printDotsLocalInfo = lib.hm.dag.entryBefore ["writeBoundary"] ''
    DOTS_DIR="''${DOTS_DIR:-$HOME/dots}"
    DOTS_LOCAL_DIR="''${DOTS_LOCAL_DIR:-$HOME/dots-local}"

    # Colors
    BLUE='\033[0;34m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    PURPLE='\033[0;35m'
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

    BULLET="*"
    if [ "$USE_GUM" -eq 1 ]; then
      BULLET="•"
    fi
    
    print_header "✦" "DOTS CONFIGURATION"
    
    # Basic settings from dots-local
    print_section "📋" "Basic Settings:"
    echo -e "   ''${YELLOW}Host:''${NC}     ''${GREEN}${hostOrUnknown}''${NC}"
    echo -e "   ''${YELLOW}Profile:''${NC}  ''${GREEN}${dotsLocal.profile}''${NC}"
    echo -e "   ''${YELLOW}System:''${NC}   ''${GREEN}${dotsLocal.system}''${NC}"
    echo -e "   ''${YELLOW}User:''${NC}     ''${GREEN}${dotsLocal.username}''${NC}"
    echo ""
    
    # Show sync patterns if config exists
    # NOTE: sync-config.json lives in dots-local (generated from its
    # flake.nix), not in dots itself - was previously checked at the wrong
    # path ($HOME/dots/sync-config.json), so this section always showed
    # nothing.
    if [ -f "$DOTS_LOCAL_DIR/sync-config.json" ]; then
      print_section "📝" "Sync Patterns:"
      if command -v jq &> /dev/null; then
        count=$(jq -r '.tracked | length' "$DOTS_LOCAL_DIR/sync-config.json" 2>/dev/null || echo "0")
        if [ "$count" -gt 0 ]; then
          for ((i=0; i<count; i++)); do
            pattern=$(jq -r ".tracked[$i].pattern" "$DOTS_LOCAL_DIR/sync-config.json" 2>/dev/null)
            type=$(jq -r ".tracked[$i].type" "$DOTS_LOCAL_DIR/sync-config.json" 2>/dev/null)
            on_new=$(jq -r ".tracked[$i].on_new" "$DOTS_LOCAL_DIR/sync-config.json" 2>/dev/null)
            echo -e "   ''${PURPLE}$BULLET''${NC} ''${YELLOW}$pattern''${NC} (''${CYAN}$type''${NC}, on_new: ''${CYAN}$on_new''${NC})"
          done
        else
          echo -e "   ''${YELLOW}No patterns configured''${NC}"
        fi
      else
        echo -e "   ''${YELLOW}Install jq to see patterns''${NC}"
      fi
      echo ""
    fi
    
    # Show host-specific config if detected
    # NOTE: host files live at profiles/<profile>/hosts/<host>.nix, not
    # modules/hosts/<host>.nix (that path never existed) - was previously
    # checked at the wrong path, so this section never fired.
    host="${hostOrEmpty}"
    profile="${dotsLocal.profile}"
    if [ -n "$host" ] && [ -f "$DOTS_DIR/profiles/$profile/hosts/$host.nix" ]; then
      print_section "🔧" "Host-specific config:"
      echo -e "   ''${GREEN}profiles/$profile/hosts/$host.nix''${NC}"
      echo ""
    fi
    
    echo -e "''${BOLD}══════════════════════════════════════════════════════════════''${NC}"
    echo ""
  '';

  # Sync handcrafted user configs on activation (applies to all profiles).
  #
  # This fires automatically on EVERY Home Manager activation (bare
  # `home-manager switch`, `nh home switch`, or via `apply-dots`), which is
  # what makes it the right place for this to live - it's the single source
  # of truth for "sync runs after every successful switch, however it was
  # triggered." `apply-dots` (modules/core/scripts.nix) used to ALSO call
  # sync.sh explicitly right after `nh home switch` returned, which is
  # redundant with this hook (which already ran during that same switch) -
  # that explicit second call has been removed from scripts.nix.
  home.activation.syncUserConfigs = lib.hm.dag.entryAfter ["writeBoundary"] ''
    DOTS_DIR="''${DOTS_DIR:-$HOME/dots}"
    if [ -x "$DOTS_DIR/sync.sh" ]; then
      echo ""
      if command -v gum >/dev/null 2>&1; then
        gum style --foreground 51 --bold "🔄 Syncing handcrafted user configs..."
      else
        echo -e "\033[0;36mSyncing handcrafted user configs...\033[0m"
      fi
      "$DOTS_DIR/sync.sh" || true
    fi
  '';
}
