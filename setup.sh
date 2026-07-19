#!/usr/bin/env bash

# Exit on error
set -e

PROFILE=$1

if [ -z "$PROFILE" ]; then
    echo "Usage: ./setup.sh <profile-name>"
    echo "Example: ./setup.sh work"
    exit 1
fi

DOTS_LOCAL="$HOME/dots-local"

# Determine hostname (use short hostname by default)
HOSTNAME="$HOSTNAME"
SYSTEM="x86_64-linux"
MARCH="native"
BARCH="x86_64-v3"
DISTRO="cachyos"
# Supported distro values: cachyos | opensuse | azurelinux3 | azurelinux4 | debian
# (selects the alien-package backend - see modules/local/schema.nix's
# `distro` option description for the full list)

# 1. Create dots-local if it doesn't exist
if [ ! -d "$DOTS_LOCAL" ]; then
    echo "Creating private identity repo at $DOTS_LOCAL..."
    mkdir -p "$DOTS_LOCAL"
    cd "$DOTS_LOCAL"
    git init
    
    # Create .gitignore
    cat > .gitignore << 'EOF'
# Generated files - do not commit
sync-config.json
result
result-*
*.lock

# AppImage runtime files
cache/
*.zsync
EOF
    
    # Create empty appimages.nix
    cat > appimages.nix << 'EOF'
# Host-local AppImages configuration
# Add entries here for AppImages stored in ~/Applications/AppImages/
# Example:
# {
#   steam = {
#     file = "Steam-*.AppImage";
#     command = "steam";
#     desktopName = "Steam";
#     categories = [ "Game" ];
#     icon = "steam";  # optional: theme icon name
#   };
# }

{}
EOF
    
    cat <<EOF > flake.nix
{
  outputs = { self, ... }:
    let
      system = "${SYSTEM}";
      barch = "${BARCH}";
      march = "${MARCH}";
      distro = "${DISTRO}";
    in {
      inherit system barch march distro;
      host = "${HOSTNAME}";
      realname = "First Last";
      realmail = "first@last.com";
      username = "$(whoami)";
      uid = "$(id -u)";
      gid = "$(id -g)";
      homeDirectory = "${HOME}";
      profile = "${PROFILE}";
      enableGuiDefaults = true;
      graphicalBackend = "wayland";
      nixonDefault = false;

      # Hardware/context axes - all optional, uncomment and set what
      # applies to this machine. See modules/local/schema.nix and
      # README.md's "Adding a New Host" section for the full list and
      # what each one drives (via modules/rules.nix).
      # gpu = "nvidia";           # or "amd" / "intel" / omit entirely
      # compositor = "niri";      # omit for a CLI-only machine
      # isWsl = true;              # if running under WSL

      # Per-machine hardware/peripheral config - all fields optional.
      # machine = {
      #   sshIdentityFile = "~/.ssh/id_github_${HOSTNAME}";
      #   terminal = "ghostty";                # only used if compositor == "niri"
      #   renderDrmDevice = null;               # let niri auto-detect, or set explicitly
      #   display = {                           # omit entirely to skip power-toggle.sh
      #     output = "eDP-1";
      #     ecoMode = { resolution = "1920x1200"; brightness = "30%"; };
      #     perfMode = { resolution = "1920x1200"; refreshRate = "120.000"; };
      #   };
      # };

      # For anything too bespoke to express as an axis above (e.g. exact
      # CUDA/compiler flags for one particular GPU), add a small module
      # file next to this one and reference it here:
      # extraModules = [ ./host-${HOSTNAME}.nix ];
      
      # AppImages configuration
      appimagesDir = "${HOME}/Applications/AppImages";
      appimages = import ./appimages.nix;
      
      # Tuning flags per language and mode - OPTIONAL overrides only.
      # dots itself already ships sensible defaults for every
      # lang/mode combination (see dots/modules/core/tune-defaults.nix) -
      # you only need to set tune.flags here if you want to override one
      # of those defaults for this specific machine. Example:
      # tune = {
      #   flags = {
      #     c.fast = "-Ofast -march=\${march} -pipe -flto=auto -ffast-math";
      #   };
      # };
      
      # Sync configuration - track handcrafted configs that survive nix rebuilds
      # Uncomment and customize sync.tracked to enable
      # sync = {
      #   tracked = [
      #     {
      #       pattern = ".config/noctalia/**";
      #       type = "home";
      #       on_new = "prompt";
      #       ignore = [
      #         "**/preview.png"
      #         "**/manifest.json"
      #         "**/i18n/**"
      #         "**/shaders/**"
      #         "**/Assets/**"
      #         "**/components/**"
      #         "**/Components/**"
      #         "**/LICENSES/**"
      #         "**/REUSE.toml"
      #         "!**/settings.json"
      #         "!**/colors.json"
      #       ];
      #     }
      #   ];
      # };
    };
}
EOF
    git add flake.nix .gitignore appimages.nix
    git commit -m "Initial identity for ${PROFILE}"
    cd - > /dev/null
else
    echo "Using existing identity at ${DOTS_LOCAL}"
fi

# 2. Perform the initial bootstrap
# NOTE: the flake output is always "default" - which context (priv/work/
# ...) you get is fully determined by dots-local's `profile` field above,
# not by the flake output name.
echo "Running initial Home Manager bootstrap for context: ${PROFILE}..."

nix run home-manager -- switch \
  --flake .#default \
  --override-input dots-local git+file://"${DOTS_LOCAL}"

echo "--------------------------------------------------"
echo "Setup complete! Restart your shell to use 'apply-dots'."
echo ""
echo "Next steps:"
echo "1. Edit ~/dots-local/flake.nix to set your name, email, and (optionally) tune flag overrides"
echo "2. Uncomment gpu/compositor/isWsl/machine if this host has a GPU, a niri desktop,"
echo "   is under WSL, or needs an SSH identity/display config (see README.md's"
echo "   'Adding a New Host' section for the full explanation of each field)"
echo "3. Add AppImages to ~/dots-local/appimages.nix"
echo "4. Uncomment and configure sync.tracked if desired"
echo "5. Run apply-dots to activate changes"
