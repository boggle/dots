# User Config Sync System

Manages handcrafted configuration files that survive Nix rebuilds, tracking them between your system (`~`) and the git repository (`dots/settings/<hostname>/`).

## Architecture

The sync system uses **three levels of configuration** that are merged together:

### 1. Global Profile Ignores (dots repo)

**Location:** `dots/profiles/<profile>/sync.json`

Contains global ignore patterns that apply to ALL tracked files for a given profile. These exclude common files that shouldn't be synced (docs, licenses, images, build artifacts, etc.).

**Files** (both are read and merged if present - neither is required):
- `dots/profiles/common/sync.json` - Baseline ignores shared across every profile. This is
  where the actual pattern list lives today.
- `dots/profiles/<profile>/sync.json` (e.g. `dots/profiles/priv/sync.json`) - Optional,
  profile-specific *additions* on top of common - only add one if a profile genuinely
  needs extra patterns beyond the shared baseline. Not present for any profile today
  (there's nothing priv/work-specific to add yet); don't copy the whole common list into
  one of these - `sync.sh` already merges both files, so a per-profile file only needs to
  contain what's actually different for that profile.

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

Defines what files to actually track for THIS machine. `dots-local` is ALWAYS for the current host (per-machine config). There are two ways to define what's tracked, and they're normally used together:

- **`sync.enable`** - a list of names of dots-defined **"syncables"** (see
  section 2a below) - the common case, avoids copy-pasting the same
  pattern/ignore block into every machine's `dots-local`.
- **`sync.tracked`** - raw, full pattern definitions given directly here -
  for genuinely ad-hoc, one-off, machine-specific things not worth
  registering as a shared syncable.

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
      # Activate dots-defined syncables by name (see modules/core/syncables.nix)
      enable = [ "noctalia" "dms" ];

      # Ad-hoc, machine-specific patterns not worth registering as a syncable
      tracked = [
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

### 2a. Named Syncables (dots repo)

**Location:** `dots/modules/core/syncables.nix`

A shared registry of reusable, named sync-pattern bundles - the actual `pattern`/`type`/`on_new`/`ignore` definition for something like Noctalia's settings lives here **once**, instead of being copy-pasted into every machine's `dots-local/flake.nix`. A machine activates one by adding its name to `sync.enable` (see above).

**Format** (same shape as a `sync.tracked` entry, just named and centralized):
```nix
{
  noctalia = {
    pattern = ".config/noctalia/**";
    type = "home";
    on_new = "prompt";
    ignore = [
      "**/preview.png"
      "**/manifest.json"
      "!**/settings.json"  # ! = negation (DON'T ignore)
    ];
  };

  dms = {
    pattern = ".config/dms/**";
    type = "home";
    on_new = "prompt";
    ignore = [ "**/cache/**" ];
  };
}
```

**Features can require a syncable, but never auto-enable it.** A feature
whose config genuinely needs to be tracked (e.g. `features.niri-noctalia`
requiring the `noctalia` syncable) declares an **assertion** checking that
its required syncable is in `dotsLocal.sync.enable` - if you enable the
feature without also enabling the syncable, `apply-dots`/`nix build` fails
outright with a clear message telling you which syncable to add and why,
rather than silently leaving that config untracked.

This is deliberately a *manual, one-time* opt-in rather than an automatic
one: if a required syncable were auto-enabled whenever its feature is on,
temporarily disabling the feature (e.g. to test something else) would
silently drop sync coverage for config you still want kept around. Once
you've enabled a syncable, it stays enabled - and keeps being
tracked/synced - independent of whatever features happen to be on or off
at any given moment.

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
apply-dots [opt] [-- <nh-args>...]    # Apply dots config + run sync
```

Which context (priv/work) you get comes from `dots-local`'s `profile`
field, not a CLI argument - the only argument `apply-dots` takes is the
optional `opt` (baseline vs. optimized build).

Examples:
```bash
apply-dots                    # Baseline build (homeConfigurations.default)
apply-dots opt                # Optimized build (homeConfigurations.default-opt)
apply-dots -- -b backup       # Pass -b backup to nh home switch
apply-dots opt -- -b backup   # Optimized build + nh arguments
```

Features:
- Shows pretty configuration info
- Auto-regenerates `sync-config.json` if `flake.nix` is newer (via mtime check)
- Runs home-manager switch with optional arguments
- Captures full build log on failure (saved to `/tmp/apply-dots-*.log`)
- Runs sync automatically after successful switch
- Provides helpful error messages with common fixes

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
update-dots [input-name] [-- <nix-flake-update-args>...]    # Update flake inputs
```

Examples:
```bash
update-dots                    # Update all inputs
update-dots nixpkgs            # Update specific input
update-dots -- --refresh       # Pass --refresh to nix flake update
update-dots nixpkgs -- --refresh  # Input + extra args
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
cd ~/dots
./setup.sh priv                       # Creates ~/dots-local from templates/local/
# Edit ~/dots-local/flake.nix, add your sync patterns (or sync.enable = [ ... ];)
dots-sync                             # Auto-regenerates sync-config.json from flake.nix - no
                                       # manual `nix eval` step needed, every invocation does this
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
│       └── sync.json          ← Shared ignores across profiles
│       (no per-host directory anymore - host-specific config now comes
│       from dots-local fields/extraModules, see modules/composition.nix)
├── modules/
│   ├── contexts/
│   │   ├── priv.nix           ← Personal context config (was profiles/priv/home.nix)
│   │   └── work.nix           ← Work context config
│   └── core/
│       ├── scripts.nix        ← Commands (apply-dots, dots-sync, etc.)
│       └── syncables.nix      ← Named syncable registry (see section 2a)
├── templates/local/           ← Real template files setup.sh copies + fills in
│   ├── flake.nix               for a brand-new machine (not a bash heredoc)
│   ├── appimages.nix
│   ├── host.nix
│   └── gitignore
├── setup.sh                   ← One-time setup script (creates ~/dots-local from templates/)
├── sync.sh                    ← Core sync script
├── SYNC.md                    ← This documentation
└── settings/
    └── <hostname>/
        ├── home/**             ← ~/** (user home files stored here)
        └── root/**             ← /** (system files stored here)

dots-local/                     (machine-specific, gitignored)
├── flake.nix                  ← Your config (EDIT THIS!)
├── sync-config.json           ← Generated from flake.nix (gitignored)
├── appimages.nix              ← Host-local AppImages config
├── host-<hostname>.nix         ← Bespoke config too specific to generalize
│                                 (referenced via flake.nix's extraModules)
└── .gitignore                 ← Ignores generated files
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
8. **Named syncables reduce copy-paste across machines** - define a pattern once in `dots/modules/core/syncables.nix`, activate it per-machine with `sync.enable = [ "name" ]` instead of redefining it in every `dots-local`
9. **Required syncables never auto-enable** - a feature that needs one (e.g. `features.niri-noctalia` needing `noctalia`) only asserts it's enabled, it never turns it on for you - this is intentional, so disabling a feature never silently stops syncing config you still want kept
