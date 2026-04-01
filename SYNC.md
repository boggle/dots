# User Config Sync System

Manages handcrafted configuration files that survive Nix rebuilds, tracking them between your system (`~`) and the git repository (`dots/settings/<hostname>/`).

## Architecture

The sync system uses **three levels of configuration** that are merged together:

### 1. Global Profile Ignores (dots repo)

**Location:** `dots/profiles/<profile>/sync.json`

Contains global ignore patterns that apply to ALL tracked files for a given profile. These exclude common files that shouldn't be synced (docs, licenses, images, build artifacts, etc.).

**Files:**
- `dots/profiles/priv/sync.json` - Global ignores for priv profile
- `dots/profiles/work/sync.json` - Global ignores for work profile  
- `dots/profiles/common/sync.json` - Shared ignores across all profiles (optional, skipped if not exists)

**Format:**
```json
{
  "global_ignores": [
    "**/README*",
    "**/LICENSE*",
    "**/*.md",
    "**/*.png",
    ...
  ]
}
```

### 2. Local Tracked Patterns (dots-local)

**Location:** `~/dots-local/sync-config.json` (generated, gitignored)  
**Source:** `~/dots-local/flake.nix` (manual edits here)

Defines what files to actually track for THIS machine. `dots-local` is ALWAYS for the current host (per-machine config).

**Generation:**
```bash
cd ~/dots-local
nix eval --json .#sync | jq '.' > sync-config.json
```

**Or automatically via:**
```bash
dots-sync      # Auto-regenerates if flake.nix is newer
dots-sync -g   # Force regeneration
apply-dots     # Also regenerates before building
```

**Format in flake.nix:**
```nix
{
  outputs = { self, ... }: {
    sync = {
      tracked = [
        {
          # User configs (home level)
          pattern = ".config/noctalia/**";
          type = "home";        # "home" = ~/, "root" = /
          on_new = "prompt";    # "prompt" | "auto" | "ignore"
          ignore = [
            # Pattern-specific ignores (in addition to global)
            "**/preview.png"
            "**/manifest.json"
            "!**/settings.json"  # ! = negation (DON'T ignore)
          ];
        }
        {
          # System configs (root level) - requires sudo to install
          pattern = "etc/NetworkManager/system-connections/**";
          type = "root";
          on_new = "auto";
          ignore = [];
        }
        # Add more patterns...
      ];
    };
  };
}
```

### 3. Storage Location (dots/settings)

**Location:** `dots/settings/<hostname>/`

Where synced files are actually stored in git. The `type` field determines the mapping:

**Home level (`type = "home"`):**
- **Source:** `~/`** (user's home directory) - where files live on your system
- **Destination:** `dots/settings/<hostname>/home/**` - where they're stored in git
- Use for: Application configs, dotfiles, user-specific settings
- Example: `~/.config/noctalia/**` → `dots/settings/<hostname>/home/.config/noctalia/**`

**System level (`type = "root"`):**
- **Source:** `/`** (system root) - where files live on your system
- **Destination:** `dots/settings/<hostname>/root/**` - where they're stored in git  
- Use for: System-wide configs requiring root/sudo
- Example: `/etc/NetworkManager/system-connections/**` → `dots/settings/<hostname>/root/etc/NetworkManager/system-connections/**`

**Example:**
```
~/.config/noctalia/settings.json
                    ↓
dots/settings/laputa/home/.config/noctalia/settings.json

/etc/NetworkManager/system-connections/Wifi.nmconnection
                    ↓
dots/settings/laputa/root/etc/NetworkManager/system-connections/Wifi.nmconnection
```

## Commands

### apply-dots
```bash
apply-dots [profile]    # Apply dots config + run sync
```

Features:
- Shows pretty configuration info
- Auto-regenerates `sync-config.json` if `flake.nix` is newer (via mtime check)
- Runs home-manager switch
- Runs sync automatically after successful switch

### dots-sync
```bash
dots-sync               # Sync files (auto-regenerate config if stale)
dots-sync -g            # Force regenerate config, then sync
dots-sync -f            # Force mode (auto-capture all new files)
dots-sync -n            # Dry run (preview only)
dots-sync -i            # Install mode (git → system)
dots-sync -h            # Help
```

Features:
- Automatically regenerates `sync-config.json` if needed (mtime check)
- `-g` flag forces regeneration even if current
- Combines global ignores + local patterns
- Prompts for new files (unless `-f` or `on_new: auto`)

### update-dots
```bash
update-dots             # Update all flake inputs
```

## Pattern Matching

Uses glob patterns with `**` support:
- `**` - Matches any number of directory levels
- `*` - Matches anything except `/`
- `!pattern` - Negation (don't ignore this even if it matches other patterns)

**Examples:**
```
"**/*.md"           # All .md files anywhere
".config/**"        # Everything in .config
"**/settings.json"  # All files named settings.json
"!**/settings.json" # DON'T ignore settings.json (override)
```

## Workflow

### Initial setup on new machine:
```bash
cd ~/dots-local
./setup.sh                    # Creates flake.nix template
# Edit flake.nix, add your sync patterns
nix eval --json .#sync > sync-config.json
```

### Daily usage:
```bash
apply-dots                    # Apply dots + sync
# or
dots-sync                     # Just sync files
```

### After editing sync config:
```bash
# Edit ~/dots-local/flake.nix
dots-sync -g                  # Force regenerate and sync
# or
apply-dots                    # Will auto-regenerate if needed
```

## Sync Modes

**Normal mode** (default): System → Git
- Captures handcrafted changes from your system into the repo
- Safe: prompts for new files, reports changes without overwriting

**Force mode** (`-f`): System → Git  
- Full sync: overwrites git files, removes orphaned files
- Use when you want git to exactly match your system

**Install mode** (`-i`): Git → System
- Generates a shell script to deploy FROM git TO a new system
- Review the script before running
- Automatically uses `sudo` for `type = "root"` files
- Creates backups before overwriting existing files

## Safety Features

- **Never overwrites** without explicit `-f` flag
- **Prompts** for new files (configurable per pattern via `on_new`)
- **Backups** created before overwriting (`.backup.<timestamp>`)
- **Orphan detection** - alerts when files deleted from system
- **Dry-run mode** (`-n`) - preview all changes first

## File Relationships

```
dots/                           (main repo, committed)
├── profiles/
│   ├── priv/
│   │   └── sync.json          ← Global ignores for priv
│   ├── work/
│   │   └── sync.json          ← Global ignores for work  
│   └── common/
│       └── sync.json          ← (optional) shared ignores
├── bin/
│   ├── apply-dots             ← Main command
│   ├── dots-sync              ← Sync wrapper
│   ├── update-dots            ← Update inputs
│   └── sync.sh                ← Core sync script
├── SYNC.md                    ← This documentation
└── settings/
    └── <hostname>/
        ├── home/**             ← ~/** (user home files stored here)
        └── root/**             ← /** (system files stored here)

dots-local/                     (machine-specific, gitignored)
├── flake.nix                  ← Your config (EDIT THIS!)
├── sync-config.json           ← Generated from flake.nix (gitignored)
├── .gitignore                 ← Ignores generated files
└── setup.sh                   ← One-time setup script
```

## Pattern Options Reference

**`pattern`**: Glob pattern for files to track
- `**` matches any depth (recursive)
- `*` matches files in current level only
- Example: `.config/**` tracks everything under `.config/`

**`type`**: Where files come from
- `"home"`: Maps `~/**` → `settings/<host>/home/**`
- `"root"`: Maps `/**` → `settings/<host>/root/**`

**`on_new`**: How to handle new files found on system
- `"prompt"` (default): Ask before capturing to git
- `"auto"`: Automatically capture to git
- `"ignore"`: Skip new files entirely

**`ignore`**: Patterns to exclude (supports `*` and `**`)
- Supports negation with `!`
- Global ignores apply first, then pattern-specific, then negations

## Important Notes

1. **dots-local is per-machine** - Each machine has its own dots-local with its own sync config in `flake.nix`
2. **Global ignores are shared** - Patterns in `dots/profiles/*/sync.json` apply to all machines using that profile
3. **Regeneration is automatic** - Both `apply-dots` and `dots-sync` check mtime and regenerate if `flake.nix` is newer than `sync-config.json`
4. **Use `-g` to force** - If you want to regenerate even when not needed, use `dots-sync -g`
5. **Negation works** - Use `!pattern` in local ignore lists to override global ignores for specific files
6. **Root files need sudo** - When using `type = "root"`, the install script (`-i` mode) automatically uses `sudo` for those files
7. **Storage paths matter** - Files are stored in `settings/<host>/home/` or `settings/<host>/root/` based on the `type` field
