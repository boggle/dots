# Shared alien-package spec discovery. Used by both
# modules/flake/alien-package-specs.nix (flake-level, builds the early
# `alien` specialArg) and modules/core/alien-packages.nix (home-manager-
# level, generates the update-alien-packages script), so the recursive
# directory-walk logic lives in one place.
{ lib }:

{
  # Recursively finds every `*.<distro>-packages.nix` file under `dir` and
  # merges them into one attrset, keyed by package name. A package name
  # can only ever have ONE spec across the whole repo - it can still be
  # *consumed* by any number of suites/features (see e.g. `lazygit`,
  # defined once in tui-apps.cachyos-packages.nix but also used by
  # suites.git-tools.lazygit's own mkAppSet call), but there is
  # deliberately no "owning feature" concept here, just a flat package-
  # name -> spec registry. If two different spec files ever define the
  # SAME package name with DIFFERENT content, that's a real correctness
  # risk (whichever file happened to be walked last would silently win,
  # with zero indication anything was overridden) - `throw` a clear error
  # identifying every conflict rather than let that happen silently.
  # Identical-content duplicates across files are NOT flagged (harmless,
  # if slightly redundant) - only genuine disagreements about what a
  # package's alien spec should be.
  # `distro` is typically `dotsLocal.distro`.
  collectAlienSpecs = { dir, distro }:
    let
      suffix = ".${distro}-packages.nix";

      collectFiles = d:
        let
          entries = builtins.readDir d;
          names = builtins.attrNames entries;
        in builtins.concatLists (map (name:
          let
            ty = entries.${name};
            p = d + "/${name}";
          in
            if ty == "directory" then collectFiles p
            else if ty == "regular" && lib.hasSuffix suffix name then [ p ]
            else [ ]
        ) names);

      specFiles = collectFiles dir;

      # Each file's own spec attrset, paired with its path (for error
      # messages below) - loaded once, reused both for the merge and for
      # the conflict check (Nix memoizes `import p` per-path, so this
      # costs nothing extra over the old single-pass fold).
      fileSpecs = map (p: { path = p; specs = import p; }) specFiles;

      merged = lib.foldl' (acc: f: acc // f.specs) { } fileSpecs;

      allPkgNames = lib.unique (lib.concatMap (f: builtins.attrNames f.specs) fileSpecs);

      conflicts = lib.filter (c: c != null) (map (pkgName:
        let
          definers = lib.filter (f: f.specs ? ${pkgName}) fileSpecs;
          values = map (f: f.specs.${pkgName}) definers;
        in
          if lib.length definers > 1 && !(lib.all (v: v == lib.head values) values)
          then { inherit pkgName; files = map (f: toString f.path) definers; }
          else null
      ) allPkgNames);
    in
      if conflicts != [ ] then
        throw ''
          Alien package spec conflict(s) for distro "${distro}": the same
          package name is defined with DIFFERENT content by more than one
          *.${distro}-packages.nix file. Each package name must have
          exactly one spec across the whole repo (a package can still be
          consumed by multiple suites/features via mkAppSet - only the
          spec definition itself must be single-sourced). Pick one
          definition and delete the other(s), or reconcile the
          difference if it was intentional.

          ${lib.concatMapStringsSep "\n" (c: "  - \"${c.pkgName}\" defined differently in: ${lib.concatStringsSep ", " c.files}") conflicts}
        ''
      else
        merged;
}
