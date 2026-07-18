# Agent Development Guide

This document provides architecture and development guidance for AI agents working on this repository.

## Memory Bank (read this first)

This repository is undergoing a large, multi-phase re-architecture. Before
making any non-trivial change, **read `memory-bank/*.md`**, at minimum:

1. `memory-bank/plan.md` — the phased execution tracker with current status.
   Find the current/next phase before starting work.
2. `memory-bank/decisions.md` — dated decision log with rationale. Do not
   re-litigate or silently contradict a logged decision; if you think one
   should change, ask the user and log the outcome.
3. `memory-bank/open-questions.md` — unresolved items that need user input
   before proceeding on the related work.

As you work:
- Update `memory-bank/plan.md` checkboxes/status as tasks progress (mark
  in-progress/done in real time, not batched).
- Append new entries to `memory-bank/decisions.md` for any consequential
  choice, and to `memory-bank/learnings.md` for gotchas/workarounds
  discovered along the way.
- Add anything unresolved to `memory-bank/open-questions.md` rather than
  guessing and moving on.
- See `memory-bank/architecture.md` for the target design and
  `memory-bank/preserved-features-checklist.md` for the regression list that
  must stay intact throughout.

**Transitional state warning:** because this is a phased migration, this
AGENTS.md file (describing the *current/legacy* architecture below) and
`memory-bank/architecture.md` (describing the *target* architecture) may
temporarily disagree — the memory bank always wins for anything already
migrated; this file is authoritative for anything not yet touched. Update
this file's relevant sections as each phase lands so the two never drift for
long.

## Repository Structure

### Two-Repo Design

The system uses a split repository design:

- **`dots/`** (this repo): Shared configuration, modules, profiles
- **`dots-local/`** (private): Per-machine identity, hostname, user info, tuning flags

The `dots-local` repo is passed as a flake input and consumed via `inputs.dots-local`.

### Directory Layout

```
dots/
├── flake.nix                 # Entry point, defines homeConfigurations
├── profiles/                 # Profile definitions
│   ├── common/              # Base profile (minimal CLI)
│   ├── priv/                # Personal profile (extends common)
│   └── work/                # Work profile (extends common)
├── modules/                 # Feature and suite modules
│   ├── core/                # Core infrastructure
│   │   ├── default.nix      # Core packages and settings
│   │   ├── scripts.nix      # Command definitions (apply-dots, etc.)
│   │   ├── dots-local.nix   # dots-local integration
│   │   ├── alien-packages.nix  # Native package manager integration
│   │   ├── tune-support.nix    # Package optimization support
│   │   └── nix-tools.nix    # Nix-related packages
│   ├── features/            # Individual capabilities
│   └── suites/              # Bundled application groups
├── settings/                # Synced handcrafted configs (per-host)
└── sync.sh                  # Config sync script
```

## Architecture

### Profile Hierarchy

```
common (minimal CLI baseline)
  ↓
priv/work (full environment)
  ↓
hosts/<hostname>.nix (machine-specific)
```

Each level imports the previous and adds more specific configuration.

### Module Types

**Features** (`features.<name>`): Individual capabilities
- Can be enabled/disabled independently
- Example: `features.git`, `features.clipboard`

**Suites** (`suites.<name>`): Bundled application groups
- Enable multiple related packages at once
- Example: `suites.gui-apps`, `suites.tui-apps`

### Key Design Patterns

#### 1. mkDefault for Base Profile

Common profile uses `lib.mkDefault` for all options, allowing profiles to override:

```nix
# profiles/common/home.nix
features.git.enable = lib.mkDefault true;
features.git.delta = lib.mkDefault true;

# profiles/priv/home.nix (can override)
features.git.jj = true;  # Also enable jujutsu
```

#### 2. Alien Package Integration

Features check for alien (native) packages and skip Nix versions:

```nix
{ config, lib, pkgs, alien, ... }:

config = lib.mkIf cfg.enable {
  home.packages = builtins.filter (p: p != null) [
    (alien.mkEntry cfg.yazi "yazi" pkgs.yazi)
  ];
  
  alienPackages.enabledPackages =
    lib.optional cfg.yazi "yazi";
};
```

#### 3. Distro-Specific Package Lists

Create `<feature>.<distro>-packages.nix` for alien packages:

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

#### 4. Gutter Evaluation

The flake uses "gutter evaluation" to capture clean Home Manager outputs:

```nix
# Gutter Eval to capture clean HM bashrc/profile
gutterEval = home-manager.lib.homeManagerConfiguration {
  pkgs = pkgs';
  modules = baseModules;
  extraSpecialArgs = { inherit inputs pkgs' alien; };
};

# Then pass to main config
extraSpecialArgs = {
  bashrcDerivation = gutterEval.config.home.file.".bashrc".source;
  profileDerivation = gutterEval.config.home.file.".profile".source;
};
```

This allows Nixon to redirect bashrc without creating conflicts.

### Script Generation

Commands like `apply-dots` are generated in `modules/core/scripts.nix` using `pkgs.writeShellScriptBin`. They are:

1. Defined as Nix expressions (with proper escaping)
2. Installed via `home.packages`
3. Available immediately after `apply-dots` succeeds

## Common Tasks

### Adding a New Feature

1. Create `modules/features/<name>.nix`
2. Follow the pattern:
   ```nix
   { config, lib, pkgs, ... }:
   
   let cfg = config.features.<name>;
   in {
     options.features.<name> = {
       enable = lib.mkEnableOption "Description";
       # Add options...
     };
     
     config = lib.mkIf cfg.enable {
       home.packages = [ ... ];
       # Configuration...
     };
   }
   ```
3. Import in profile's `home.nix`

### Adding a New Suite

1. Create `modules/suites/<name>.nix`
2. Create `modules/suites/<name>.cachyos-packages.nix` (if needed)
3. Follow feature pattern but use `suites.<name>` namespace

### Adding Alien Package Support

1. Create `<feature>.<distro>-packages.nix` next to your feature
2. Use the feature name as the key
3. Define packages for relevant package managers:
   ```nix
   {
     myfeature = {
       feature = "myfeature";  # Must match
       packages = {
         pacman = [ "pkg1" "pkg2" ];
         paru = [ "aur-pkg" ];
         zypper = [ "pkg1" ];
         tdnf = [ "pkg1" ];
       };
     };
   }
   ```

### Adding a New Profile

To create a new profile (e.g., `work`):

1. Create directory structure:
   ```bash
   mkdir -p profiles/work/hosts
   touch profiles/work/home.nix
   ```

2. Follow the priv pattern in `home.nix`:
   ```nix
   { pkgs, lib, inputs, ... }:
   
   let
     local = inputs.dots-local;
     hostname = local.host or null;
     hostImport = if hostname != null 
       then ./hosts/${hostname}.nix
       else null;
   in {
     imports = lib.filter (x: x != null) [
       ../common/home.nix
       # Add profile-specific modules
       hostImport
     ];
     
     # Profile-specific configuration
   }
   ```

3. Add to `flake.nix` profile definitions:
   ```nix
   profileDefinitions = {
     priv = { /* ... */ };
     work = { tunePackages = {}; };
   };
   ```

### Adding a New Host

1. Determine hostname from `dots-local/flake.nix`:
   ```nix
   host = "myhostname";
   ```

2. Create host file:
   ```bash
   touch profiles/<profile>/hosts/<hostname>.nix
   # Example: profiles/priv/hosts/myhostname.nix
   ```

3. Host file template:
   ```nix
   # <hostname> Machine Configuration
   { config, pkgs, lib, ... }:
   
   {
     imports = [
       ../../../modules/features/sd-switch.nix
     ];
     
     home.packages = with pkgs; [ 
       bluez
       localsend
     ];
     
     home.sessionVariables = {
       SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent.socket";
     };
     
     programs.ssh = {
       matchBlocks."*".identityFile = "~/.ssh/id_github_${hostname}";
     };
   }
   ```

4. Apply: `apply-dots`

### Updating Documentation

When modifying features:
1. Update the feature table in README.md
2. Add examples if usage changed
3. Update OVERVIEW.md if architecture changed

## Testing Changes

### Test Evaluation

```bash
nix eval .#homeConfigurations.priv --override-input dots-local git+file://$HOME/dots-local
```

### Test Build (without activation)

```bash
nh home build . -c priv -- --override-input dots-local git+file://$HOME/dots-local
```

### Test Activation

```bash
apply-dots priv -- --dry  # Dry run
apply-dots priv -- -b backup  # With backup
```

## Important Notes

### File Locations

- **Commands**: Defined in `modules/core/scripts.nix`, NOT in `bin/`
- **Sync config**: `profiles/<profile>/sync.json` (global ignores)
- **Host configs**: `profiles/<profile>/hosts/<hostname>.nix`
- **Settings storage**: `settings/<hostname>/home/**` and `settings/<hostname>/root/**`

### Nix Evaluation

- `dots-local` is passed as `path:../dots-local` in flake.nix but overridden at runtime
- During `apply-dots`, it's overridden with `git+file://$DOTS_LOCAL_DIR`
- This allows uncommitted changes in dots-local to be picked up

### Error Handling

- Build failures are captured to temp logs (`/tmp/apply-dots-*.log`)
- Activation failures show the log path and common fixes
- Use `-- -b backup` to handle file collisions

## Related Documentation

- README.md - User-facing quick start and feature reference
- OVERVIEW.md - Detailed architecture and tuning system
- SYNC.md - Config sync system documentation
- This file - Development and agent guidance
