# Formal schema for `dots-local`'s flake output, evaluated via
# `lib.evalModules` in flake.nix (see flake.nix's `dotsLocal` binding).
#
# Every option here has a description and (where sensible) a default, so
# `dots-local/flake.nix` only needs to override what's actually specific to
# that machine/identity - anything left unset falls back to a documented,
# safe default.
#
# DESIGN NOTE: existing fields deliberately keep their flat names/shape
# (host, distro, march, realname, ...) rather than a fully-nested
# identity.*/machine.*/system.* design, to avoid requiring a rewrite of the
# live dots-local/flake.nix. Axis fields (gpu, isWsl, location, tags,
# shell.*, extraModules, extraOverlays) feed composition-rules.nix and
# beyond.

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
        Hostname. Informational/display use (e.g. shown by
        modules/core/dots-local.nix's activation info) - machine-specific
        behavior itself is driven by the other axis fields below
        (`machine.*`, `gpu`, `compositor`, ...), not by `host` directly.
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
        opensuse, azurelinux3, azurelinux4, debian.
      '';
    };

    isWsl = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether this machine is running under WSL. Orthogonal to `distro`
        (e.g. a Debian distro running inside WSL is `distro = "debian";
        isWsl = true;`). Consumed by composition-rules.nix's `isWsl` rule.
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
        GPU vendor present on this machine, if any. Consumed by
        composition-rules.nix: gpu == "nvidia" pulls in the llama-cpp
        feature and the ai-apps "pi" toggle by default.
      '';
    };

    compositor = mkOption {
      type = types.nullOr (types.enum [ "niri" ]);
      default = null;
      description = ''
        Which Wayland compositor/desktop this machine uses, if any.
        Consumed by composition-rules.nix to enable features.niri-noctalia
        and default its terminal/renderDrmDevice options from
        `machine.terminal`/`machine.renderDrmDevice`. Null means no
        compositor-managed desktop (e.g. a CLI-only or WSL machine).
      '';
    };

    machine = mkOption {
      default = { };
      description = ''
        Per-machine hardware/peripheral config, consumed by generic
        (not host-specific) feature modules. Anything NOT covered by a
        field here and too bespoke to generalize (e.g. exact
        CUDA/llama.cpp cmakeFlags for one particular GPU) belongs in
        `extraModules` instead.
      '';
      type = types.submodule {
        options = {
          sshIdentityFile = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              SSH identity file for this host's default `Host *` block
              (e.g. "~/.ssh/id_github_<host>"). Null skips setting one -
              consumed by features/network.nix.
            '';
          };

          terminal = mkOption {
            type = types.str;
            default = "ghostty";
            description = ''
              Terminal emulator command, used as the default for
              features.niri-noctalia.terminal (only meaningful when
              `compositor == "niri"`).
            '';
          };

          renderDrmDevice = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              DRM render node for niri (e.g. "/dev/dri/render_amd"). Null
              lets niri auto-detect. Only meaningful when
              `compositor == "niri"`.
            '';
          };

          display = mkOption {
            default = null;
            description = ''
              Display config for the power-toggle eco/perf script
              (features/power-toggle.nix). Null disables that feature
              entirely (no power-toggle.sh installed).
            '';
            type = types.nullOr (types.submodule {
              options = {
                output = mkOption {
                  type = types.str;
                  description = ''wlr-randr output name (e.g. "eDP-1").'';
                };
                ecoMode = mkOption {
                  description = "Display settings applied in eco mode.";
                  type = types.submodule {
                    options = {
                      resolution = mkOption { type = types.str; description = "e.g. \"1920x1200\"."; };
                      refreshRate = mkOption { type = types.str; default = "60.000"; description = "Refresh rate in Hz (as wlr-randr expects, e.g. \"60.000\")."; };
                      brightness = mkOption { type = types.str; default = "30%"; description = "brightnessctl set value."; };
                    };
                  };
                };
                perfMode = mkOption {
                  description = "Display settings applied in performance mode.";
                  type = types.submodule {
                    options = {
                      resolution = mkOption { type = types.str; description = "e.g. \"1920x1200\"."; };
                      refreshRate = mkOption { type = types.str; default = "120.000"; description = "Refresh rate in Hz."; };
                    };
                  };
                };
              };
            });
          };
        };
      };
    };

    # --- Desktop / GUI ---
    enableGuiDefaults = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable GUI-related suites/features by default
        (gui-apps, pim-apps superproductivity, etc).
      '';
    };

    graphicalBackend = mkOption {
      type = types.enum [ "wayland" "x11" "wsl" "macos" ];
      default = "wayland";
      description = ''
        Desktop/platform backend, used by features.opener/
        features.clipboard and (in future) other platform-aware features.
        Enum-typed, so an invalid value is rejected at eval time with a
        clear error.
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
            Anything left unset falls back to the built-in defaults in
            modules/core/tune-defaults.nix.
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
