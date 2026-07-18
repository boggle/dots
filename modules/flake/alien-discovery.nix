# Shared alien-package spec discovery, extracted from what used to be two
# independently-implemented, near-identical copies of the same recursive
# directory walk: modules/flake/alien-package-specs.nix (flake-level, used
# to build the early `alien` specialArg) and modules/core/alien-packages.nix
# (home-manager-level, used to generate the update-alien-packages script).
# Both now import this one function instead of each maintaining their own
# copy (Phase 3 of the re-architecture - see memory-bank/architecture.md
# section 4 and memory-bank/plan.md Phase 3).
{ lib }:

{
  # Recursively finds every `*.<distro>-packages.nix` file under `dir` and
  # merges them into one attrset (later files win on key collision, same
  # behavior as before). `distro` is typically `dotsLocal.distro`.
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
    in
      lib.foldl' (acc: p: acc // (import p)) { } specFiles;
}
