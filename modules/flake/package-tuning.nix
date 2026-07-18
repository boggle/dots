{ lib, dotsLocal }:

let
  collectTuneSpecsFiles = dir:
    let
      entries = builtins.readDir dir;
      names = builtins.attrNames entries;
    in builtins.concatLists (map (name:
      let ty = entries.${name}; p = dir + "/${name}";
      in if ty == "directory" then collectTuneSpecsFiles p
         else if ty == "regular" && lib.hasSuffix ".tune-specs.nix" name then [ p ]
         else [ ]
    ) names);

  moduleDefaults = march: {
    c = { safe = "-O2 -pipe"; default = "-O3 -march=${march} -pipe"; fast = "-Ofast -march=${march} -pipe -flto=auto"; };
    "c++" = { safe = "-O2 -pipe"; default = "-O3 -march=${march} -pipe"; fast = "-Ofast -march=${march} -pipe -flto=auto"; };
    rust = { safe = "-C opt-level=2"; default = "-C target-cpu=${march} -C opt-level=3"; fast = "-C target-cpu=${march} -C opt-level=3 -C codegen-units=1"; };
    zig = { safe = "-Doptimize=ReleaseSafe"; default = "-Doptimize=ReleaseFast"; fast = "-Doptimize=ReleaseFast"; };
  };

in {
  mkTuneOverlay = tunePackages: rootDir:
    let
      tuneSpecsFiles = collectTuneSpecsFiles rootDir;
      tuneSpecs = lib.foldl' (acc: p: acc // (import p)) {} tuneSpecsFiles;
      enabled = lib.filterAttrs (_: v: (v.enable or false) == true) tunePackages;
      enabledWithSpecs = lib.mapAttrs (name: v: (tuneSpecs.${name} or {}) // (builtins.removeAttrs v [ "enable" ])) enabled;
      # NOTE: previously defaulted to "znver5" here specifically (vs.
      # tune-support.nix's "native" default for the same field) - an
      # inconsistency now resolved by both consumers reading
      # dotsLocal.march directly, which the schema defaults to "native".
      # dots-local machines that set march explicitly (e.g. chromaden's
      # "znver5") are unaffected; machines that don't now get the safer
      # "native" default instead of a specific-CPU string that would fail
      # to build on anything but that exact chip.
      march = dotsLocal.march;
      defaults = moduleDefaults march;
    in
    if enabledWithSpecs == {} then null
    else final: prev:
      lib.mapAttrs (name: opt:
        let
          pkg = prev.${name} or null;
          getFlags = lang: mode: (dotsLocal.tune.flags.${lang}.${mode} or defaults.${lang}.${mode});
          detectLang = p: if p ? cargoDeps then "rust" else "c";
          lang = opt.lang or (if pkg != null then detectLang pkg else "c");
          mode = opt.mode or "default";
          flagStr = if (opt.flags or null) != null then opt.flags else (getFlags lang mode);
        in
        if pkg == null || !lib.isDerivation pkg then pkg
        else pkg.overrideAttrs (old: if lang == "rust" then { RUSTFLAGS = flagStr; } else { NIX_CFLAGS_COMPILE = (old.NIX_CFLAGS_COMPILE or "") + " " + flagStr; })
      ) enabledWithSpecs;
}