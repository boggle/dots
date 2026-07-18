# System Overview

This repository provides a complete, portable development environment using Nix and Home Manager.

## Environment Variables

```bash
DOTS_DIR="$HOME/dots"              # Location of dots repository
DOTS_LOCAL_DIR="$HOME/dots-local"  # Location of dots-local repository
```

Both default to `~/dots` and `~/dots-local` respectively. Override for custom installations.

## Distro Backends

`dots-local/flake.nix` sets `distro`, which selects alien package manager backends:

- `cachyos` -> `pacman`, `paru`
- `opensuse` -> `zypper`
- `azurelinux3` -> `tdnf`
- `azurelinux4` -> `dnf5` (Azure Linux 4.0 replaced tdnf with dnf5; CLI-relevant
  specs only - see `modules/*/*.azurelinux4-packages.nix`)
- `debian` -> `apt` (CLI-relevant specs only so far - see
  `modules/*/*.debian-packages.nix`)

Azure Linux 3 package mappings are intentionally conservative and only include packages verified to exist in the official Azure Linux 3 repositories.

## Cross-Platform Utilities

Three essential commands that work consistently across Linux (Wayland/X11), WSL, and macOS:

### `o` - File Opener

Opens files with the system default application.

```bash
o document.pdf          # Opens in PDF viewer
o image.png             # Opens in image viewer  
o https://example.com   # Opens in browser
```

**How it works:** Uses `xdg-open` (Linux), `open` (macOS), or `wslview` (WSL) depending on the `backend` setting.

### Clipboard Commands

**`clipin`** - Copy to clipboard
```bash
cat file.txt | clipin    # Copy file contents
echo "text" | clipin     # Copy text
clipin < file.txt        # Copy from file
```

**`clipout`** - Paste from clipboard
```bash
clipout                  # Print to stdout
clipout > file.txt       # Save to file
clipout | grep text      # Pipe to command
```

**Features:**
- Cross-platform: Wayland (wl-clipboard), X11 (xclip), WSL (clip.exe), macOS (pbcopy)
- ANSI stripping: `clipin -s` removes color codes before copying
- WSL line ending handling: Converts CRLF automatically

### `v` - Smart File Viewer

Views files in the terminal with appropriate tools.

```bash
# Single file (interactive mode)
v README.md             # Renders markdown with glow
v image.png             # Shows image in terminal (chafa/timg)
v app.log               # Syntax highlighted with bat

# Multiple files (continuous/streaming mode)
v *.md                  # Views all markdown files
v -c *.json | less      # Stream to less for manual control
v -p file1 file2        # Pause between files

# Flags
v -c file.md            # Continuous mode (no pager)
v -s binary.dat         # Strip ANSI colors
v -h                    # Show full help
```

**File Type Support:**

| Extension | Viewer | Notes |
|-----------|--------|-------|
| `.md` | `glow` | Renders to formatted text |
| Images | `chafa` → `timg` | Terminal graphics via sixel |
| `.pdf` | `meowpdf` | PDF pages as images |
| `.mp4` | `mpv` | Video playback in terminal |
| `.csv` | `column` | Table formatting |
| `.json` | `jq` | Pretty-printed |
| `.log` | `bat` | With line numbers |
| `.diff` | `delta` | Side-by-side if available |
| Archives | `unzip`/`tar` | Lists contents only |
| Binary | `xxd` | Hex dump |

**Mode Details:**
- **Single file** → Interactive (glow -t, bat with pager)
- **Multiple files** → Continuous streaming (no pager)
- **Video in continuous** → Shows metadata only
- **FZF picker** → When run with no arguments

---

# Tuning System

Optimize specific packages for your CPU microarchitecture.

## Why Tune?

Most Nix packages are built for generic `x86_64-linux` to work on any machine. If you have a modern CPU (Zen 3, Alder Lake, etc.), you can rebuild packages with flags like `-march=znver3` for better performance.

## Three Scopes

### Global (Overlay)
Replaces the package everywhere in your configuration.

```nix
# In flake.nix
priv = mkProfile { 
  tunePackages = {
    ripgrep = { enable = true; mode = "fast"; };
  };
};
```

**Use for:** Tools you always want optimized (ripgrep, fd, etc.)

### Local (PATH Shadowing)
Adds tuned version to PATH, shadows baseline.

```nix
# In profile/home.nix
features.tune.packages.bat = {
  enable = true; 
  scope = "local"; 
  mode = "fast";
};
```

**Use for:** Replacing baseline packages with tuned versions

### Wrapped (Suffix)
Creates separate binary with suffix for explicit use.

```nix
features.tune.packages.yazi = {
  enable = true; 
  scope = "wrapped"; 
  suffix = "-tuned";  # Optional, default: "-tuned"
  mode = "fast";
};
```

**Use for:** Comparing baseline vs tuned, or tools you rarely need optimized

After applying:
```bash
yazi           # Baseline version
yazi-tuned     # Optimized version
```

## Optimization Modes

| Mode | C/C++ | Rust | Use Case |
|------|-------|------|----------|
| `safe` | `-O2` | `-C opt-level=2` | Compatibility first |
| `default` | `-O3 -march=${march}` | `-C opt-level=3` | Good balance |
| `fast` | `-Ofast -ffast-math` | Aggressive opt | Maximum speed |

**Note:** `fast` mode with `-ffast-math` relaxes IEEE-754 compliance. Safe for most CLI tools, avoid for numerical/scientific code.

## Custom Flags

Override mode completely:

```nix
fd = { 
  enable = true; 
  flags = "-C target-cpu=znver3 -C opt-level=3"; 
  lang = "rust"; 
};
```

## Architecture Config

Set your CPU in `~/dots-local/flake.nix`:

```nix
{
  outputs = _: 
    let
      march = "znver3";     # Your CPU (skylake, alderlake, etc.)
      barch = "x86_64-v3";  # Baseline level (v2/v3/v4)
    in {
      inherit barch march;
      
      # Override defaults per language/mode
      tune.flags.c.fast = "-Ofast -march=${march} -ffast-math";
    };
}
```

Common `march` values: `znver3` (AMD Zen 3), `skylake`, `alderlake`, `sapphirerapids`

## Profiles

- **`priv`/`work`** - Baseline, uses cache.nixos.org + tune overlay
- **`priv-opt`/`work-opt`** - Rebuilds everything with `localSystem.gcc.arch = barch`

Baseline is faster to install. Optimized profiles rebuild all packages locally (takes hours first time).

## Commands

```bash
apply-dots           # Use dots-local.profile (usually priv)
apply-dots priv      # Baseline + tuned packages
apply-dots priv-opt  # Fully optimized (rebuilds everything)

update-dots          # Update flake inputs
which yazi-tuned     # Verify tuned version exists
```

## AppImages

Two modes supported: **host-local** (runtime, outside Nix store) and **shared** (Nix store).

### Host-Local AppImages (Recommended for most)

Store AppImages in `~/Applications/AppImages/` (or customize via `features.appimages.localDir`).
These run directly without importing into the Nix store.

Define in `~/dots-local/appimages.nix`:
```nix
{
  steam = {
    file = "Steam-*.AppImage";   # Glob pattern - must match exactly one file
    command = "steam";           # Wrapper command name
    desktopName = "Steam";
    categories = [ "Game" ];
    enable = true;               # Optional, defaults to true
  };
}
```

Place the AppImage file and ensure it's executable:
```bash
cp ~/Downloads/Steam-1.0.0.85.AppImage ~/Applications/AppImages/
chmod +x ~/Applications/AppImages/Steam-1.0.0.85.AppImage
```

The wrapper requires exactly one file matching the pattern. It will error if:
- No file matches (you need to place the AppImage)
- Multiple files match (you have multiple versions - keep only one)
- The file is not executable (run `chmod +x`)

### Shared AppImages (Nix Store)

For AppImages that work fine from the Nix store, use shared manifests:

```nix
# In profiles/common/appimages/manifest.nix or profiles/<profile>/appimages/manifest.nix
{
  cursor = {
    src = ./Cursor.AppImage;     # Nix path, imported into store
    command = "cursor";
    desktopName = "Cursor";
    categories = [ "Development" ];
  };
}
```

Shared AppImages are updated in the dots repo, then `apply-dots` re-imports them.

### Commands

```bash
# Update registered host-local AppImages (default)
appimage-update

# Update specific app
appimage-update steam

# Update all AppImages in localDir (including unregistered)
appimage-update --unregistered

# Update everything: host-local + unregistered + shared
appimage-update --all

# Update shared AppImages in dots repo
appimage-update --include-shared
```

Exec bit is preserved during updates: if an AppImage was executable before update, it will be chmod +x after.

### Enable/Disable Individual Apps

In your profile or host config:
```nix
features.appimages = {
  enable = true;
  apps = {
    steam.enable = false;    # Disable even if in manifest
  };
};
```

## Alien Packages (Native Package Management)

Manage native distro packages alongside Nix packages. This allows mixing Nix and native package managers (pacman, paru, zypper) for cases where native packages work better.

### Why Alien Packages?

Some packages work better when installed natively:
- **System integration** - Better desktop integration, file associations
- **Faster updates** - No need to wait for Nixpkgs
- **Native dependencies** - Some apps expect system libraries
- **Distribution-optimized** - Packages compiled for your specific distro

### How It Works

1. Define packages in `<feature>.<distro>-packages.nix` files
2. Suites/features declare which alien packages they need
3. Dots generates package lists per package manager
4. Use `update-alien-packages` to install/manage them

### Defining Alien Packages

Create a `<feature>.<distro>-packages.nix` file next to your feature:

```nix
# modules/suites/gui-apps.cachyos-packages.nix
{
  ghostty = {
    feature = "gui-apps";
    packages = {
      pacman = [ "ghostty" ];
    };
  };
}
```

### Using Alien Packages in Features

Features check if an alien package exists and skip the Nix version:

```nix
{ config, lib, pkgs, alien, ... }:

let
  cfg = config.suites.tui-apps;
in {
  options.suites.tui-apps = {
    enable = lib.mkEnableOption "Enable interactive TUI tools";
    yazi = lib.mkEnableOption "Yazi file manager";
  };

  config = lib.mkIf cfg.enable {
    # Use alien.mkEntry - returns null if alien package exists
    home.packages = builtins.filter (p: p != null) [
      (alien.mkEntry cfg.yazi "yazi" pkgs.yazi)
    ];

    # Declare which alien packages are enabled
    alienPackages.enabledPackages =
      lib.optional cfg.yazi "yazi";
  };
}
```

### Commands

```bash
# Update: Install missing packages, detect orphans (default)
update-alien-packages
update-alien-packages --target pacman

# Install only: Skip orphan detection
update-alien-packages --action install --target pacman

# Remove orphans: Interactively remove orphaned packages
update-alien-packages --action remove --target pacman
```

### Package Tracking

Alien packages are tracked in `~/.local/share/dots/packages/`:

```
~/.local/share/dots/packages/
├── required/
│   ├── pacman.txt      # What dots wants NOW
│   └── paru.txt
├── installed/
│   ├── pacman.txt      # What was last installed
│   └── paru.txt
└── orphaned/
    ├── pacman.txt      # Packages to review for removal
    └── paru.txt
```

**Orphan Detection:** When you disable a package in dots, it's detected as an orphan. Run `update-alien-packages --action remove` to clean them up.

**Manual Removals:** If you manually remove a package, dots will detect it and offer to reinstall (with `update` or `install` action).

## Tips

- **Start small:** Tune 2-3 CLI tools you use constantly
- **Use global scope** for daily tools (ripgrep, fd)
- **Use wrapped scope** to test before committing to global
- **Custom flags** when you know exactly what you want
- **Baseline profiles** are fine for most use - optimization is diminishing returns
