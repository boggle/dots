# Formal schema for `dots-local`'s flake output, evaluated via
# `lib.evalModules` in flake.nix (see flake.nix's `dotsLocal` binding).
#
# Every option here has a description and (where sensible) a default, so
# `dots-local/flake.nix` only needs to override what's actually specific to
# that machine/identity - anything left unset falls back to a documented,
# safe default instead of the ~30 scattered `local.X or default` reads that
# used to be spread across individual modules.
#
# DESIGN NOTE (see memory-bank/decisions.md, 2026-07-18 "dots-local schema:
# additive/backward-compatible"): existing fields deliberately keep their
# current flat names/shape (host, distro, march, realname, ...) rather than
# being restructured into the fully-nested identity.*/machine.*/system.*
# design originally sketched in memory-bank/architecture.md - that would
# have required rewriting the live dots-local/flake.nix as part of this
# phase, which is unnecessary risk for a schema-formalization step. New
# axis fields (gpu, isWsl, location, tags, shell.*, extraModules,
# extraOverlays) are added inertly - not yet consumed by anything, reserved
# for the Phase 2 composition-rules system and beyond.

{ lib, ... }:

let
  inherit (lib) mkOption types;
in {
  options = {
    # --- Core identity (required - no generic default makes sense) ---
    username = mkOption {
      type = types.str;
      description = ''
        Unix username on this machine. Required - used for
        `home.username` (flake.nix) and hardcoded paths in a few features
        (e.g. dev-tools.nix's .nixd.json).
      '';
    };

    homeDirectory = mkOption {
      type = types.str;
      description = ''
        Absolute path to the user's home directory. Required - used for
        `home.homeDirectory` (flake.nix).
      '';
    };

    realname = mkOption {
      type = types.str;
      description = "Real name for git commits (programs.git.settings.user.name). Required.";
    };

    realmail = mkOption {
      type = types.str;
      description = "Email for git commits (programs.git.settings.user.email). Required.";
    };

    # --- Machine / system axes ---
    system = mkOption {
      type = types.str;
      default = "x86_64-linux";
      description = "Nix system string (target platform triple).";
    };

    host = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Hostname, used to select `profiles/<profile>/hosts/<host>.nix` if
        it exists. Leave null for a host with no machine-specific file.
      '';
    };

    profile = mkOption {
      type = types.str;
      default = "priv";
      description = ''Which dots profile to use (e.g. "priv", "work").'';
    };

    distro = mkOption {
      type = types.str;
      default = "unknown";
      description = ''
        Linux distro identifier, selects the alien-package backend
        (`*.<distro>-packages.nix` spec suffix). Known values: cachyos,
        opensuse, azurelinux3, debian.
      '';
    };

    isWsl = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether this machine is running under WSL. Orthogonal to `distro`
        (e.g. a Debian distro running inside WSL is `distro = "debian";
        isWsl = true;`). Not yet consumed by anything - reserved for
        Phase 2/3.
      '';
    };

    uid = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Unix UID. Currently unused by dots itself (kept for potential
        future use / dots-local's own convenience) - see
        memory-bank/open-questions.md.
      '';
    };

    gid = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Unix GID. Currently unused by dots itself, same status as `uid`
        above.
      '';
    };

    march = mkOption {
      type = types.str;
      default = "native";
      description = ''
        CPU microarchitecture (e.g. "znver5", "skylake", "alderlake") used
        by the tuning system's default flag tables. NOTE: the `-opt`
        profile builds currently hardcode "znver5" directly in flake.nix
        rather than reading this value - see memory-bank/open-questions.md.
      '';
    };

    barch = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Baseline microarchitecture level (e.g. "x86_64-v3"). NOTE: not
        currently consumed anywhere in dots (see march's note above about
        the -opt profile). Kept for forward-compat.
      '';
    };

    gpu = mkOption {
      type = types.nullOr (types.enum [ "nvidia" "amd" "intel" ]);
      default = null;
      description = ''
        GPU vendor present on this machine, if any. Not yet consumed by any
        module - reserved for the Phase 2 composition-rules system (e.g.
        "if gpu == nvidia, pull in the AI/llama-cpp suite by default").
      '';
    };

    # --- Desktop / GUI ---
    enableGuiDefaults = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable GUI-related suites/features by default
        (gui-apps, pim-apps superproductivity, etc). Replaces the old
        undocumented `graphical` legacy alias some host files used to fall
        back to - only `enableGuiDefaults` is read now.
      '';
    };

    graphicalBackend = mkOption {
      type = types.enum [ "wayland" "x11" "wsl" "macos" ];
      default = "wayland";
      description = ''
        Desktop/platform backend, used by features.opener/
        features.clipboard and (in future) other platform-aware features.
        Now enum-typed, so an invalid value is rejected at eval time with a
        clear error - the manual assertion previously in
        profiles/priv/home.nix for this is no longer needed.
      '';
    };

    nixonDefault = mkOption {
      type = types.bool;
      default = false;
      description = "Default value of $NIXON (1=nix-managed shell, 0=native host shell) on a fresh login.";
    };

    # --- Location / freeform tags (new axes, inert for now) ---
    location = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Freeform physical/network "situation" tag (e.g. "home", "parents",
        "travel", "office"). Not yet consumed by any module - reserved for
        future location-aware features (VPN/proxy/DNS, etc).
      '';
    };

    tags = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Open-ended list of capability/context tags for anything not yet
        modeled as a first-class option here.
      '';
    };

    # --- Butterfish / local LLM endpoint ---
    butterfishEndpoint = mkOption {
      type = types.str;
      default = "http://127.0.0.1:5001/v1";
      description = "Butterfish's OpenAI-compatible endpoint URL (e.g. a local llama.cpp server).";
    };

    butterfishApiKey = mkOption {
      type = types.str;
      default = "talk-to-me";
      description = "API key sent to the butterfish endpoint (often meaningless for local servers).";
    };

    butterfishModel = mkOption {
      type = types.str;
      default = "default";
      description = "Model name to request from the butterfish endpoint.";
    };

    # --- AppImages ---
    appimagesDir = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Directory to look for host-local AppImages in. If null,
        features.appimages falls back to
        "''${config.home.homeDirectory}/Applications/AppImages".
      '';
    };

    appimages = mkOption {
      type = types.attrsOf (types.submodule {
        # freeformType keeps this lenient - dots-local's own appimages.nix
        # may have extra/misspelled keys (e.g. a stray `dektopName` typo
        # exists there today); we validate the known fields without
        # rejecting the whole entry over an unrecognized one.
        freeformType = types.attrsOf types.anything;
        options = {
          file = mkOption {
            type = types.str;
            description = "Glob pattern matching exactly one AppImage file.";
          };
          command = mkOption {
            type = types.str;
            description = "Wrapper command name to install on PATH.";
          };
          desktopName = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Display name for the .desktop entry.";
          };
          categories = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "XDG desktop categories.";
          };
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to install this AppImage wrapper.";
          };
        };
      });
      default = { };
      description = "Host-local AppImage manifest - see OVERVIEW.md's AppImages section.";
    };

    # --- Tuning ---
    tune = mkOption {
      default = { };
      description = "Per-language/mode compiler flag overrides for the package-tuning system.";
      type = types.submodule {
        options.flags = mkOption {
          type = types.attrsOf (types.attrsOf types.str);
          default = { };
          description = ''
            Override table: flags.<lang>.<mode> = "compiler flags string".
            Anything left unset falls back to the built-in defaults
            (currently duplicated across tune-support.nix/package-tuning.nix/
            setup.sh - see architecture.md section 6, unification not yet
            done as of Phase 1).
          '';
        };
      };
    };

    # --- Sync ---
    sync = mkOption {
      default = { };
      description = "Settings-sync configuration (see SYNC.md).";
      type = types.submodule {
        options.tracked = mkOption {
          default = [ ];
          description = "List of tracked file patterns to sync between the system and dots/settings/<host>/.";
          type = types.listOf (types.submodule {
            options = {
              pattern = mkOption {
                type = types.str;
                description = "Glob pattern for files to track.";
              };
              type = mkOption {
                type = types.enum [ "home" "root" ];
                default = "home";
                description = "Whether pattern is relative to ~ (home) or / (root).";
              };
              on_new = mkOption {
                type = types.enum [ "prompt" "auto" "ignore" ];
                default = "prompt";
                description = "How to handle newly-discovered files matching this pattern.";
              };
              ignore = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Additional ignore sub-patterns (supports ! negation).";
              };
            };
          });
        };
      };
    };

    # --- Easy shell customization (new - low-ceremony path, see
    # architecture.md section 1a) ---
    shell = mkOption {
      default = { };
      description = "Easy shell customization from dots-local, merged into programs.bash.*";
      type = types.submodule {
        options = {
          sessionVariables = mkOption {
            type = types.attrsOf types.str;
            default = { };
            description = "Extra environment variables, merged into programs.bash.sessionVariables.";
          };
          shellAliases = mkOption {
            type = types.attrsOf types.str;
            default = { };
            description = "Extra shell aliases, merged into programs.bash.shellAliases.";
          };
          initExtra = mkOption {
            type = types.lines;
            default = "";
            description = "Extra bash snippet, appended to programs.bash.initExtra.";
          };
        };
      };
    };

    # --- Escape hatches for highly-specialized/bespoke needs (new, see
    # architecture.md section 1b) ---
    extraModules = mkOption {
      type = types.listOf types.path;
      default = [ ];
      description = ''
        Extra Home Manager module files supplied by dots-local itself, for
        machine-specific needs too bespoke to generalize into a shared dots
        feature (keeps `dots` itself free of one-off host state).
      '';
    };

    extraOverlays = mkOption {
      type = types.listOf types.anything;
      default = [ ];
      description = ''
        Extra nixpkgs overlays supplied by dots-local itself, for
        machine-specific packages/overrides too bespoke to generalize.
        Each entry should be an overlay function (`final: prev: { ... }`).
      '';
    };
  };
}
