# Shared alien-package spec discovery. Used by both
# modules/flake/alien-package-specs.nix (flake-level, builds the early
# `alien` specialArg) and modules/core/alien-packages.nix (home-manager-
# level, generates the update-alien-packages script), so the recursive
# directory-walk logic lives in one place.
{ lib }:

{
  # Recursively finds every `*.<distro>-packages.nix` file under `dir` and
  # merges them into one attrset (later files win on key collision).
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
    in
      lib.foldl' (acc: p: acc // (import p)) { } specFiles;
}
