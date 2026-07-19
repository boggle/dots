# "work" context bundle.
#
# A genuinely minimal, conservative starter: common's baseline plus
# slightly fuller git/dev-tools defaults typical of a work machine, with
# GUI/AI/TUI suites left off by default (composition-rules.nix enables
# suites.cloud-tools by default for this context; everything else is
# opt-in via dotsLocal.extraModules or by editing this file directly).
#
# Customize this file for your actual work needs - this is intentionally a
# starting point, not a fully-specified profile like priv.nix.
{ pkgs, lib, dotsLocal, ... }:

{
  features.git = {
    enable = lib.mkDefault true;
    git = lib.mkDefault true;
    delta = lib.mkDefault true;
    lazygit = lib.mkDefault true;
    gh = lib.mkDefault true;
  };

  features.dev-tools = {
    enable = lib.mkDefault true;
    rust = lib.mkDefault false;
    python = lib.mkDefault false;
    json = lib.mkDefault true;
  };

  features.network = {
    enable = lib.mkDefault true;
    sshAgent = lib.mkDefault true;
    gpgAgent = lib.mkDefault true;
  };
}
