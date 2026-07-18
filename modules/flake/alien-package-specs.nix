{ lib, dotsLocal }:

let
  discovery = import ./alien-discovery.nix { inherit lib; };
  alienSpecs = discovery.collectAlienSpecs {
    dir = ../../modules;
    distro = dotsLocal.distro;
  };
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
