# dots-local integration module
# Displays configuration info and runs sync on activation for all profiles

{ config, lib, pkgs, inputs, ... }:

let
  local = inputs.dots-local;
in
{
  # Pretty print dots-local configuration on activation
  home.activation.printDotsLocalInfo = lib.hm.dag.entryBefore ["writeBoundary"] ''
    # Colors
    BLUE='\033[0;34m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    PURPLE='\033[0;35m'
    NC='\033[0m'
    BOLD='\033[1m'
    
    echo ""
    echo -e "''${BOLD}╔══════════════════════════════════════════════════════════════╗''${NC}"
    echo -e "''${BOLD}║''${NC}  ''${BLUE}⚙️  DOTS CONFIGURATION''${NC}                                      ''${BOLD}║''${NC}"
    echo -e "''${BOLD}╚══════════════════════════════════════════════════════════════╝''${NC}"
    echo ""
    
    # Basic settings from dots-local
    echo -e "''${CYAN}📋 Basic Settings:''${NC}"
    echo -e "   ''${YELLOW}Host:''${NC}     ''${GREEN}${local.host or "unknown"}''${NC}"
    echo -e "   ''${YELLOW}Profile:''${NC}  ''${GREEN}${local.profile or "default"}''${NC}"
    echo -e "   ''${YELLOW}System:''${NC}   ''${GREEN}${local.system or "x86_64-linux"}''${NC}"
    echo -e "   ''${YELLOW}User:''${NC}     ''${GREEN}${local.username or "$(whoami)"}''${NC}"
    echo ""
    
    # Show sync patterns if config exists
    if [ -f "$HOME/dots/sync-config.json" ]; then
      echo -e "''${CYAN}📝 Sync Patterns:''${NC}"
      if command -v jq &> /dev/null; then
        count=$(jq -r '.tracked | length' "$HOME/dots/sync-config.json" 2>/dev/null || echo "0")
        if [ "$count" -gt 0 ]; then
          for ((i=0; i<count; i++)); do
            pattern=$(jq -r ".tracked[$i].pattern" "$HOME/dots/sync-config.json" 2>/dev/null)
            type=$(jq -r ".tracked[$i].type" "$HOME/dots/sync-config.json" 2>/dev/null)
            on_new=$(jq -r ".tracked[$i].on_new" "$HOME/dots/sync-config.json" 2>/dev/null)
            echo -e "   ''${PURPLE}•''${NC} ''${YELLOW}$pattern''${NC} (''${CYAN}$type''${NC}, on_new: ''${CYAN}$on_new''${NC})"
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
    host="${local.host or ""}"
    if [ -n "$host" ] && [ -f "$HOME/dots/modules/hosts/$host.nix" ]; then
      echo -e "''${CYAN}🔧 Host-specific config:''${NC} ''${GREEN}modules/hosts/$host.nix''${NC}"
      echo ""
    fi
    
    echo -e "''${BOLD}══════════════════════════════════════════════════════════════''${NC}"
    echo ""
  '';

  # Sync handcrafted user configs on activation (applies to all profiles)
  home.activation.syncUserConfigs = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ -x "$HOME/dots/sync.sh" ]; then
      echo ""
      echo -e "\033[0;36m🔄 Syncing handcrafted user configs...\033[0m"
      "$HOME/dots/sync.sh" || true
    fi
  '';
}
