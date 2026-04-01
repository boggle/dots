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
```

## Feature System

Enable features in `profiles/priv/home.nix` or `profiles/work/home.nix`:

```nix
# Core environment
features.nix.enable = true;                    # Nix tooling
features.terminal.enable = true;               # Terminal emulators
features.terminal.wezterm = true;              # Specific terminal
features.devtools.enable = true;               # Dev tools (nixd, entr)
features.devtools.entr = true;                 # File watcher for HMR

# Applications
features.apps.enable = true;                   # GUI applications
features.apps.vscodium = true;                 # Code editor
features.apps.keepassxc = true;                # Password manager

# AI integration
features.ai.enable = true;                     # AI tooling
features.ai.opencode = true;                   # AI assistant CLI
features.ai.grabcontext = true;                # Context gathering for AI

# Media & docs
features.sixel.enable = true;                  # Terminal images
features.sixel.mpv = true;                     # Video player
features.dtp.enable = true;                    # Document tools
features.dtp.zathura = true;                   # PDF viewer

# System integration
features.clipboard.enable = true;              # Clipboard manager
features.clipboard.backend = "wayland";        # Wayland or X11
features.networkmanager.enable = true;         # Network applet
features.flatpak.enable = true;                # Flatpak support
```

### Available Features

| Feature | Options | Description |
|---------|---------|-------------|
| `ai` | `enable`, `grabcontext`, `opencode`, `copilot` | AI assistants and context tools |
| `alienPackages` | `enable`, `enabledPackages` | Native package manager integration |
| `apps` | `enable`, `vscodium`, `keepassxc`, `gimp`, `inkscape`, `vlc`, `ffmpeg`, ... | Desktop applications |
| `clipboard` | `enable`, `backend` (wayland/x11/wsl/macos) | Cross-platform clipboard manager |
| `cloud` | `enable`, `github` | Cloud service integration |
| `devtools` | `enable`, `nixd`, `entr`, `rust` | Development tooling |
| `dtp` | `enable`, `zathura` | Document processing |
| `email` | `enable` | Email client setup |
| `flatpak` | `enable`, `steam`, `discord`, ... | Flatpak applications |
| `fonts` | `enable` | Font configuration |
| `git` | `enable`, `git`, `jj`, `delta` | Version control tools |
| `network` | `enable`, `sshAgent`, `gpgAgent` | Network and crypto agents |
| `networkmanager` | `enable`, `applet` | Network Manager integration |
| `niri` | `enable` | Niri compositor |
| `opener` | `enable`, `backend`, `alias` | Cross-platform file opener (`o` command) |
| `scanning` | `enable`, `simple-scan`, `gscan2pdf` | Document scanning |
| `sixel` | `enable`, `chafa`, `timg`, `mpv`, `ytdlp` | Terminal graphics & media |
| `terminal` | `enable`, `ghostty`, `wezterm`, `zellij`, `yazi` | Terminal environment |
| `tune` | See [OVERVIEW.md](OVERVIEW.md) | Package optimization |
| `viewer` | `enable`, `alias`, `preferImageViewer`, ... | Terminal file viewer (`v` command) |

## Essential Commands

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

See [OVERVIEW.md](OVERVIEW.md) for detailed architecture.
