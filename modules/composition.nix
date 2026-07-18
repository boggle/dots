# The composition entry point - replaces the old
# profiles/<profile>/home.nix + profiles/<profile>/hosts/<hostname>.nix
# directory-inheritance chain (Phase 2 of the re-architecture, see
# memory-bank/architecture.md section 2 and memory-bank/plan.md Phase 2).
#
# Always imports the common baseline + core, then:
#   1. Imports exactly one modules/contexts/<dotsLocal.profile>.nix bundle
#      (the bulk, hand-authored per-context config - what used to be
#      profiles/<profile>/home.nix).
#   2. Folds composition-rules.nix's declarative axis-based rules on top,
#      as *defaults* (an explicit setting anywhere else always wins).
#   3. Imports dotsLocal.extraModules (already appended at the flake.nix
#      level too, for anything not folded through here - see flake.nix).
#
# No profiles/<profile>/hosts/<hostname>.nix file is required to exist for
# any machine anymore - host-specific config is expressed via dotsLocal
# fields (machine.*, gpu, compositor, ...) consumed generically by feature
# modules (features/power-toggle.nix, features/network.nix's
# sshIdentityFile, composition-rules.nix, ...), or, for truly bespoke needs
# too specific to generalize, via dotsLocal.extraModules (kept in the
# private dots-local repo, never in this shared one).
{ config, lib, dotsLocal, ... }:

let
  rules = import ./composition-rules.nix { inherit lib dotsLocal; };

  contextFile = ./contexts + "/${dotsLocal.profile}.nix";
  contextExists = builtins.pathExists contextFile;

  # Recursively wraps every LEAF value of a nested attrset in
  # `lib.mkDefault`, so composition-rules.nix's `set` attrsets behave as
  # defaults at every option path they touch - not as one single
  # low-priority definition for an entire nested tree (which is not how
  # the module system's per-leaf priority resolution works). Skips
  # attrsets that are already a module-system "override" value (e.g. if a
  # rule author already wrapped a leaf explicitly with mkForce) so we don't
  # double-wrap or corrupt an existing priority annotation.
  deepMkDefault = x:
    if builtins.isAttrs x && !(x ? _type) then lib.mapAttrs (_: deepMkDefault) x
    else lib.mkDefault x;
in {
  imports = [
    ./core
    ./core/dots-local.nix
    ./core/dots-local-shell.nix
    ./core/nix-tools.nix
    ./core/scripts.nix
    ./core/alien-packages.nix
    ./core/tune-support.nix
    ./contexts/common.nix

    # Universally imported (previously required a per-host
    # profiles/priv/hosts/<hostname>.nix file to import at all) - each
    # module's own `enable` option, defaulting to false/off, controls
    # whether anything actually happens. Enabled either by a
    # composition-rules.nix rule (e.g. compositor == "niri" ->
    # niri-noctalia) or directly by dotsLocal.extraModules for anything
    # more bespoke.
    ./features/power-toggle.nix
    ./features/niri-noctalia.nix
    ./features/llama-cpp.nix
    ./features/butterfish.nix
    ./features/sd-switch.nix
    ./features/wsl-shell-integration.nix
    ./suites/scanning.nix
    ./suites/cloud-tools.nix
  ] ++ lib.optional contextExists contextFile;

  config = lib.mkMerge ([
    {
      assertions = [
        {
          assertion = contextExists;
          message = ''
            dotsLocal.profile = "${dotsLocal.profile}" has no matching
            modules/contexts/${dotsLocal.profile}.nix file. Known contexts:
            ${lib.concatStringsSep ", " (builtins.attrNames (lib.filterAttrs
              (n: _: lib.hasSuffix ".nix" n) (builtins.readDir ./contexts)))}.
            Add one (see modules/contexts/work.nix for a minimal starting
            point) or fix dotsLocal.profile in your dots-local/flake.nix.
          '';
        }
      ];
    }
  ] ++ (map
    (rule: lib.mkIf (rule.when dotsLocal) (deepMkDefault (rule.set dotsLocal)))
    rules));
}
