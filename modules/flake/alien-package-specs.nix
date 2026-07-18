{ lib, dotsLocal }:

let
  distro = dotsLocal.distro;
  
  # Find all alien package spec files recursively
  collectAlienSpecsFiles = dir:
    let
      entries = builtins.readDir dir;
      names = builtins.attrNames entries;
      suffix = ".${distro}-packages.nix";
    in builtins.concatLists (map (name:
      let 
        ty = entries.${name}; 
        p = dir + "/${name}";
      in 
        if ty == "directory" then collectAlienSpecsFiles p
        else if ty == "regular" && lib.hasSuffix suffix name then [ p ]
        else [ ]
    ) names);
  
  # Load alien specs for current distro
  modulesDir = ../../modules;
  alienSpecFiles = collectAlienSpecsFiles modulesDir;
  alienSpecs = lib.foldl' (acc: p: acc // (import p)) {} alienSpecFiles;
  
in {
  # Helper function for features to check if alien package exists
  has = pkgName: alienSpecs ? ${pkgName};
  
  # Create an alien-aware package entry
  mkEntry = enabled: pkgName: nixPkg: 
    if !enabled then null
    else if alienSpecs ? ${pkgName} then null  # Alien package takes precedence
    else nixPkg;
  
  # Raw specs (for debugging)
  specs = alienSpecs;
}
