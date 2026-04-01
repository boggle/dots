{ config, lib, pkgs, ... }:

let
  cfg = config.features.network;
in
{
  options.features.network = {
    enable = lib.mkEnableOption "Enable network services";

    # SSH
    sshAgent = lib.mkEnableOption "SSH agent";
    
    # GPG
    gpgAgent = lib.mkEnableOption "GPG agent";
    gpgSsh = lib.mkEnableOption "GPG SSH support (use GPG keys for SSH)";
  };

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
    };
    
    services.ssh-agent = lib.mkIf cfg.sshAgent {
      enable = true;
    };

    services.gpg-agent = lib.mkIf cfg.gpgAgent {
      enable = true;
      enableSshSupport = cfg.gpgSsh;
      pinentry.package = pkgs.pinentry-tty;
      defaultCacheTtl = 86400;
      maxCacheTtl = 604800;
    };
  };
}
