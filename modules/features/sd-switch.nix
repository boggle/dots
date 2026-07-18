{ config, lib, pkgs, ... }:

let
  cfg = config.features.sd-switch;
in {
  # Previously this module had no `enable` option at all (broke the
  # convention used everywhere else in the repo - every host that imported
  # it got it unconditionally, with no way to opt out). Default is `true` to
  # preserve current always-on behavior for existing hosts.
  options.features.sd-switch.enable =
    lib.mkEnableOption "aggressive systemd --user service restarts via sd-switch on activation"
    // { default = true; };

  config = lib.mkIf cfg.enable {
    # This only applies to the user-level systemd
    systemd.user.enable = true;

    # This makes Home Manager more aggressive about
    # starting services after a 'switch'
    systemd.user.startServices = "sd-switch";
  };
}
