# Modular Nix Home Environment

A declarative, reproducible home setup for Linux workstations with per-machine optimization.

## What You Get

- **Declarative config** - Your entire environment defined in code
- **Modular features** - Enable only what you need (AI, terminal, apps, etc.)
- **Per-machine tuning** - Optimize packages for your specific CPU
- **Two profiles** - Separate work and personal configurations
- **Fast or optimized builds** - Use cache or rebuild with microarchitecture flags

## Quick Start

```bash
# First time setup
./setup.sh priv    # Creates ~/dots-local with your identity

# Daily workflow
apply-dots         # Apply your profile
apply-dots priv    # Explicit baseline (uses cache.nixos.org)
apply-dots priv-opt # Optimized for your CPU (slower, faster binaries)

# Manage native packages
update-alien-packages                    # Install missing native packages
update-alien-packages --action remove    # Clean up orphaned packages

# Manage AppImages
appimage-update                          # Update registered AppImages
appimage-update --all                    # Update all AppImages
```

## Feature System

Enable features in `profiles/priv/home.nix` or `profiles/work/home.nix`:

```nix
# Core environment (always enabled via common profile)
features.viewer.enable = true;                 # Terminal file viewer ('v' command)
features.network.enable = true;                # SSH/GPG agents, network tools
features.git.enable = true;                    # Git tooling (delta, lazygit, etc.)
features.dev-tools.enable = true;              # Dev tools (nixd, entr, rust, etc.)

# GUI and applications
features.opener.enable = true;                 # File opener ('o' command)
features.opener.backend = "wayland";           # wayland, x11, wsl, or macos
features.clipboard.enable = true;              # Clipboard manager (clipin/clipout)
features.clipboard.backend = "wayland";        # Wayland or X11
features.fonts.enable = true;                  # Font configuration

# Application suites
suites.gui-apps.enable = true;                 # GUI applications (browser, editor, etc.)
suites.gui-apps.chromium = true;               # Specific apps
suites.tui-apps.enable = true;                 # TUI tools (btop, yazi, etc.)
suites.sixel-tools.enable = true;              # Terminal graphics (chafa, mpv)
suites.ai-apps.enable = true;                  # AI tooling (opencode, grabcontext)
suites.ai-apps.opencode = true;
suites.scanning.enable = true;                 # Document scanning tools

# Tuning
features.tune.enable = true;                   # Package optimization
features.tune.packages.ripgrep = {             # Tune specific packages
  enable = true; mode = "fast"; lang = "rust";
};

# AppImages
features.appimages.enable = true;              # Host-local AppImage support
```

### Available Features & Suites

**Features** (`features.<name>`) - Individual capabilities:

| Feature | Options | Description |
|---------|---------|-------------|
| `appimages` | `enable`, `localDir`, `apps` | Host-local AppImage integration |
| `bookokrat` | `enable` | Documentation tool |
| `clipboard` | `enable`, `backend` (wayland/x11/wsl/macos) | Cross-platform clipboard (clipin/clipout) |
| `dev-tools` | `enable`, `nixd`, `entr`, `rust`, `python`, ... | Development tooling |
| `fonts` | `enable` | Font configuration |
| `git` | `enable`, `git`, `jj`, `delta`, `lazygit` | Version control tools |
| `network` | `enable`, `sshAgent`, `gpgAgent`, `gpgSsh` | Network and crypto agents |
| `niri-noctalia` | `enable`, `renderDrmDevice`, `terminal` | Niri compositor with Noctalia integration |
| `opener` | `enable`, `backend`, `alias` | Cross-platform file opener (`o` command) |
| `tune` | `enable`, `packages` | Package optimization (see [OVERVIEW.md](OVERVIEW.md)) |
| `viewer` | `enable`, `alias`, `ripgrepAll`, `preferImageViewer` | Terminal file viewer (`v` command) |

**Suites** (`suites.<name>`) - Bundled application groups:

| Suite | Options | Description |
|---------|---------|-------------|
| `ai-apps` | `enable`, `opencode`, `grabcontext` | AI assistants and context tools |
| `cloud-tools` | `enable`, `aws`, `azure`, `gcp`, `k8s` | Cloud CLI tools |
| `gui-apps` | `enable`, `ghostty`, `librewolf`, `vscodium`, `keepassxc`, ... | Desktop GUI applications |
| `pim-apps` | `enable`, `superproductivity` | Personal information management |
| `scanning` | `enable`, `simple-scan`, `gscan2pdf`, `tesseract` | Document scanning tools |
| `sixel-tools` | `enable`, `chafa`, `catimg`, `mpv`, `ytdlp` | Terminal graphics & media |
| `tui-apps` | `enable`, `btop`, `yazi`, `zellij`, `lazygit`, ... | Terminal UI applications |

## Essential Commands

Daily workflow commands (installed via Home Manager):

```bash
# Apply configuration
apply-dots                    # Apply default profile from dots-local
apply-dots priv               # Apply specific profile
apply-dots -- -b backup       # Pass arguments to nh home switch
apply-dots priv -- -b backup --dry  # Profile + nh arguments

# Update flake inputs
update-dots                   # Update all flake inputs
update-dots nixpkgs           # Update specific input
update-dots -- --refresh      # Pass arguments to nix flake update

# Sync handcrafted configs
dots-sync                     # Sync system → git (safe mode)
dots-sync -f                  # Force sync (overwrite git)
dots-sync -i                  # Generate install script (git → system)
dots-sync -n                  # Dry run (preview changes)
```

Three cross-platform utilities for daily workflow:

### `o` - File Opener (opener)

Opens files with the default application (xdg-open, open, wslview, etc.)

```bash
o file.pdf              # Open PDF in default viewer
o image.png             # Open image
o https://example.com   # Open URL in browser
```

Configuration:
```nix
features.opener = {
  enable = true;
  backend = "wayland";  # wayland, x11, wsl, or macos
  alias = "o";          # Custom alias name
};
```

### `clipin`/`clipout` - Clipboard (clipboard)

Cross-platform clipboard commands supporting Wayland, X11, WSL, and macOS.

```bash
clipin < file.txt       # Copy file contents to clipboard
echo "text" | clipin     # Copy text to clipboard
clipout > file.txt      # Paste to file
clipout                 # Print clipboard contents
```

Configuration:
```nix
features.clipboard = {
  enable = true;
  backend = "wayland";  # wayland, x11, wsl, or macos
};
```

### `v` - Terminal File Viewer (viewer)

Smart file viewer that picks the right tool based on file type.

```bash
v file.md               # Render markdown with glow
v image.png             # View image in terminal (chafa/timg)
v document.pdf          # View PDF in terminal (meowpdf)
v video.mp4             # Play video (mpv)
v *.log                 # View multiple files (continuous mode)
v -c *.json | less      # Stream to less (continuous mode)
v -s binary.dat         # Strip ANSI colors
```

Flags:
- `-c` / `--continuous` - Stream to stdout (no pager)
- `-p` / `--pager` - Pause between multiple files
- `-s` / `--strip` - Strip ANSI color codes
- `-h` / `--help` - Show help

Configuration:
```nix
features.viewer = {
  enable = true;
  alias = "v";
  preferImageViewer = "chafa";  # chafa or timg
  enableVideo = true;
  enableDirectoryTree = true;
};
```

**Multi-file behavior:** Multiple files default to continuous mode (streaming). Interactive tools (mpv, glow -t) only work with single files or `-p` flag.

## Alien Packages

Mix native distro packages (pacman, paru, zypper) with Nix packages for better system integration.

```bash
# Install/update native packages (defined in .cachyos-packages.nix, etc.)
update-alien-packages

# Show orphaned packages (previously installed but no longer required)
update-alien-packages --action remove

# Per-package manager
update-alien-packages --target pacman
```

Packages are tracked in `~/.local/share/dots/packages/`:
- `required/` - What dots wants now
- `installed/` - What was last installed
- `orphaned/` - Packages to review for removal

See [OVERVIEW.md](OVERVIEW.md#alien-packages-native-package-management) for details on defining alien packages.

## Architecture

**Two-repo design:**
- `dots/` - Shared configuration (this repo)
- `~/dots-local/` - Private identity (hostname, username, tuning flags)

**Distro values (in `~/dots-local/flake.nix`):**
- `cachyos` -> `pacman` + `paru`
- `opensuse` -> `zypper`
- `azurelinux3` -> `tdnf`

**Profiles:**
- `priv`/`work` - Baseline using cache.nixos.org
- `priv-opt`/`work-opt` - Optimized with `localSystem.gcc.arch` (rebuilds locally)

## Environment Variables

Customize dots behavior with these environment variables:

```bash
export DOTS_DIR="$HOME/dots"           # Location of dots repository
export DOTS_LOCAL_DIR="$HOME/dots-local"  # Location of dots-local repository
```

These are automatically set if not defined. Useful for non-standard setups.

## Navigation Tips

**Current Profile Symlink:**
After running `apply-dots`, a symlink is created at `~/dots/current-profile` pointing to the active profile:
```bash
cd ~/dots/current-profile        # Quick access to active profile
cd ~/dots/current-profile/hosts  # Access host configs
ls -la ~/dots/current-profile    # See what profile is active
```

**Profile Structure:**
```
profiles/
├── common/          # Minimal CLI baseline (imported by all)
│   └── home.nix
├── priv/            # Personal profile (extends common)
│   ├── home.nix
│   └── hosts/       # Per-machine configs
│       ├── chromaden.nix
│       └── ...
└── work/            # Work profile (extends common) - create your own
```

## Adding a New Host

1. Create host file:
   ```bash
   touch profiles/priv/hosts/myhostname.nix
   ```

2. Add to `dots-local/flake.nix`:
   ```nix
   host = "myhostname";
   ```

3. Configure the host in the new file:
   ```nix
   { config, pkgs, lib, ... }: {
     # Machine-specific packages and settings
     home.packages = with pkgs; [ /* ... */ ];
   }
   ```

4. Run `apply-dots`

## Troubleshooting

### Activation Failures

**File collision errors:**
```
Existing file '/home/user/.config/niri/config.kdl' would be clobbered
```

Solutions:
```bash
# Option 1: Backup conflicting files
apply-dots -- -b backup

# Option 2: Remove the conflicting file manually
mv ~/.config/niri/config.kdl ~/.config/niri/config.kdl.backup
apply-dots

# Option 3: Force overwrite (use with caution)
apply-dots -- --force
```

**Build succeeds but activation fails:**
1. Check the log path shown in the error message
2. Run activation manually to see full error:
   ```bash
   /nix/store/...-home-manager-generation/activate
   ```

### Common Issues

**Stale sync-config.json:**
```bash
dots-sync -g  # Force regenerate from flake.nix
```

**Profile not found:**
Ensure `dots-local/flake.nix` has a valid `profile` attribute (e.g., `profile = "priv";`).

**Nix evaluation errors:**
```bash
# Test evaluation without building
nix eval .#homeConfigurations.priv --override-input dots-local git+file://$HOME/dots-local
```

### Getting Help

- Check full build logs in `/tmp/apply-dots-*.log` on failure
- Use `--dry` flag to test without activating: `apply-dots -- --dry`
- See [OVERVIEW.md](OVERVIEW.md) for detailed architecture
- Review [SYNC.md](SYNC.md) for sync system documentation
