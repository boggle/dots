# Shared helper reducing the enable-flag -> home.packages (via
# alien.mkEntry) -> alienPackages.enabledPackages boilerplate repeated by
# hand in every suite/feature file (gui-apps.nix alone did this 26 times).
# Phase 4 of the re-architecture - see memory-bank/architecture.md
# section 5, memory-bank/plan.md Phase 4.
{ lib }:

{
  # `apps`: attrset of `<name> = { enable = bool; pkg = derivation;
  #          alienName ? name; };` - `alienName` lets the alien-spec key
  #          differ from the option/attr name (e.g. gui-apps.nix's
  #          `newsfeed` toggle maps to the "newsflash" alien spec, or
  #          `libreoffice` maps to "libreoffice-fresh").
  #
  # Returns `{ packages = [...]; alienEnabled = [...]; }`:
  #   - `packages`: assign to (part of) `home.packages` - each entry is
  #     either the Nix package (if not alien-managed) or omitted entirely
  #     (if alien-managed or disabled), via `alien.mkEntry`.
  #   - `alienEnabled`: assign to (part of) `alienPackages.enabledPackages`
  #     - the alien spec names of every currently-enabled app.
  mkAppSet = { alien, apps }:
    let
      names = builtins.attrNames apps;
    in {
      packages = builtins.filter (p: p != null) (map (name:
        let a = apps.${name}; in
        alien.mkEntry a.enable (a.alienName or name) a.pkg
      ) names);

      alienEnabled = map (name: apps.${name}.alienName or name)
        (builtins.filter (name: apps.${name}.enable) names);
    };
}
