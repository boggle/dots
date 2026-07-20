{ config, lib, pkgs, ... }:

let
  coreLib = import ./lib.nix { inherit lib; };
  cfg = config.features.nix;
in
{
  options.features.nix = {
    enable = coreLib.mkDefaultDisabledOption "Enable Nix tooling";

    # Core tools
    nh = coreLib.mkDefaultDisabledOption "nh (Nix flakes helper)";
    nvd = coreLib.mkDefaultDisabledOption "nvd (Nix version diff)";
    nixDiff = coreLib.mkDefaultDisabledOption "nix-diff";
    nixTree = coreLib.mkDefaultDisabledOption "nix-tree";
    nixLocate = coreLib.mkDefaultDisabledOption "nix-locate";
    deadnix = coreLib.mkDefaultDisabledOption "deadnix (lint)";
    statix = coreLib.mkDefaultDisabledOption "statix (lint)";
    manix = coreLib.mkDefaultDisabledOption "manix (search NixOS options)";
    envfs = coreLib.mkDefaultDisabledOption "envfs";
    nixIndex = coreLib.mkDefaultDisabledOption "nix-index";
    cachix = coreLib.mkDefaultDisabledOption "cachix";
    comma = coreLib.mkDefaultDisabledOption "comma";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; builtins.filter (p: p != null) [
      (lib.mkIf cfg.nh nh)
      (lib.mkIf cfg.nvd nvd)
      (lib.mkIf cfg.nixDiff nix-diff)
      (lib.mkIf cfg.nixTree nix-tree)
      (lib.mkIf cfg.nixLocate nix-locate)
      (lib.mkIf cfg.deadnix deadnix)
      (lib.mkIf cfg.statix statix)
      (lib.mkIf cfg.manix manix)
      (lib.mkIf cfg.envfs envfs)
      (lib.mkIf cfg.nixIndex nix-index)
      (lib.mkIf cfg.cachix cachix)
      (lib.mkIf cfg.comma comma)
    ];
  };
}
