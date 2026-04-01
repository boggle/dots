{ config, lib, pkgs, ... }:

let
  cfg = config.features.nix;
in
{
  options.features.nix = {
    enable = lib.mkEnableOption "Enable Nix tooling";

    # Core tools
    nh = lib.mkEnableOption "nh (Nix flakes helper)";
    nvd = lib.mkEnableOption "nvd (Nix version diff)";
    nixDiff = lib.mkEnableOption "nix-diff";
    nixTree = lib.mkEnableOption "nix-tree";
    nixLocate = lib.mkEnableOption "nix-locate";
    deadnix = lib.mkEnableOption "deadnix (lint)";
    statix = lib.mkEnableOption "statix (lint)";
    manix = lib.mkEnableOption "manix (search NixOS options)";
    envfs = lib.mkEnableOption "envfs";
    nixIndex = lib.mkEnableOption "nix-index";
    cachix = lib.mkEnableOption "cachix";
    comma = lib.mkEnableOption "comma";
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
