# Shared desktop/platform backend detection.
#
# Previously, features.clipboard and features.opener each independently
# declared their own `backend` option (identical `enum [ "wayland" "x11"
# "wsl" "macos" ]` type, no default - required to be set by whoever
# enabled the feature), and modules/rules.nix set BOTH of them, in
# lockstep, to the exact same value, in two separate rules. That
# duplication was harmless in practice (nothing ever set the two
# differently) but meant every future platform-aware feature (see the
# still-open "network.nix ssh-agent socket path" / "viewer.nix image
# viewer choice" follow-up candidates) would need its own `backend`
# option plus its own rules.nix wiring, repeating the same pattern by
# hand each time.
#
# This module computes the value ONCE, from dotsLocal's own axes, and
# exposes it as a single, read-only, shared option - features.clipboard/
# features.opener (and any future platform-aware feature) just read
# `config.core.platformBackend` directly instead of declaring/needing
# their own independently-set `backend` option.
{ config, lib, dotsLocal, ... }:

{
  options.core.platformBackend = lib.mkOption {
    type = lib.types.nullOr (lib.types.enum [ "wayland" "x11" "wsl" "macos" ]);
    readOnly = true;
    default =
      if dotsLocal.isWsl then "wsl"
      else if dotsLocal.compositor != null then dotsLocal.graphicalBackend
      else null;
    description = ''
      Derived desktop/platform backend for the current machine - computed
      once from dotsLocal.isWsl/compositor/graphicalBackend. `null` means
      no graphical backend is available (a CLI-only host) - features that
      need a real backend to do anything useful (features.clipboard,
      features.opener, ...) should stay disabled in that case (see
      modules/rules.nix, which only enables them when this would be
      non-null).

      Read-only: this is a derived value, not meant to be set directly by
      any module - if a machine genuinely needs something other than
      what dotsLocal's own axes imply, override `dotsLocal.graphicalBackend`/
      `isWsl`/`compositor` themselves instead.
    '';
  };

  options.core.enableGuiDefaults = lib.mkOption {
    type = lib.types.bool;
    readOnly = true;
    default = dotsLocal.enableGuiDefaults && dotsLocal.graphicalBackend != "none";
    description = ''
      Whether GUI-app defaults (suites.gui-apps, suites.pim-apps's
      superproductivity, ...) should actually be enabled - derived from
      `dotsLocal.enableGuiDefaults` AND `dotsLocal.graphicalBackend != "none"`.
      A machine with no graphical backend configured shouldn't get GUI
      apps installed regardless of `enableGuiDefaults`'s own value (a
      brand-new CLI-only machine that never set `graphicalBackend` would
      otherwise silently get a GUI-app baseline it can't even use - see
      `memory-bank/decisions.md`). Consumed by modules/contexts/priv.nix
      instead of reading `dotsLocal.enableGuiDefaults` directly, mirroring
      `core.platformBackend`'s "compute the derived axis value once,
      here" convention rather than re-deriving it ad hoc at each call
      site.

      Read-only: override `dotsLocal.enableGuiDefaults`/`graphicalBackend`
      themselves if a machine's actual intent differs.
    '';
  };
}
