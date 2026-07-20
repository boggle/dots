# Shared helper reducing the enable-flag -> home.packages (via
# alien.mkEntry) -> alienPackages.enabledPackages boilerplate that would
# otherwise be repeated by hand in every suite/feature file.
{ lib }:

{
  # Shorthand for the extremely common "enable option, but on by default"
  # pattern - previously written by hand everywhere as
  # `lib.mkEnableOption "desc" // { default = true; }` (32 occurrences
  # across 10 files before this helper existed). Equivalent to that exact
  # expression - just named so the intent ("on by default") is visible at
  # the call site instead of needing the `// { default = true; }` merge
  # to be spotted/understood every time.
  #
  # NOT a replacement for plain `lib.mkEnableOption` (still used, as-is,
  # for the many genuinely opt-in-only options) - only for options that
  # should default to enabled.
  # Companion to mkDefaultEnabledOption above, for symmetry/consistency:
  # an explicit way to say "an enable option, off by default" - the exact
  # same thing as plain `lib.mkEnableOption "desc"` (mkEnableOption's own
  # default is already `false`), just named so both states ("on by
  # default" / "off by default") are equally visible/explicit at every
  # call site, rather than one being an obviously-named helper call and
  # the other being "whatever mkEnableOption happens to default to".
  mkDefaultDisabledOption = description:
    lib.mkEnableOption description;

  mkDefaultEnabledOption = description:
    lib.mkEnableOption description // { default = true; };

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
