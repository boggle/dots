{ config, lib, pkgs, alien, dotsLocal, ... }:

let
  cfg = config.features.network;
  coreLib = import ../core/lib.nix { inherit lib; };
  appSet = coreLib.mkAppSet {
    inherit alien;
    apps = {
      nmap = { enable = cfg.nmap; pkg = pkgs.nmap; };
      rclone = { enable = cfg.rclone; pkg = pkgs.rclone; };
      doggo = { enable = cfg.doggo; pkg = pkgs.doggo; };
      xh = { enable = cfg.xh; pkg = pkgs.xh; };
    };
  };
in
{
  options.features.network = {
    enable = lib.mkEnableOption "Enable network services";

    # Network tools
    nmap = lib.mkEnableOption "nmap (network scanner)";
    rclone = lib.mkEnableOption "rclone (cloud sync)";
    doggo = lib.mkEnableOption "doggo (DNS client)";
    xh = lib.mkEnableOption "xh (modern HTTP client)";

    # SSH
    sshAgent = lib.mkEnableOption "SSH agent";
    
    # GPG
    gpgAgent = lib.mkEnableOption "GPG agent";
    gpgSsh = lib.mkEnableOption "GPG SSH support (use GPG keys for SSH)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = appSet.packages;

    alienPackages.enabledPackages = appSet.alienEnabled;

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      extraConfig = ''
        # VS Code setting to point at this file: remote.SSH.configFile
        Include ~/.ssh/config.local
        Include ~/.ssh/config.vscode
      '';
      # Per-machine default identity file. Null (the default) means no
      # host-specific identity block is added here.
      settings."*" = lib.mkIf (dotsLocal.machine.sshIdentityFile != null) {
        IdentityFile = dotsLocal.machine.sshIdentityFile;
        AddKeysToAgent = "yes";
      };
    };

    home.activation.ensureSshIncludeFiles = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p "$HOME/.ssh"
      if [ ! -f "$HOME/.ssh/config.local" ]; then
        : > "$HOME/.ssh/config.local"
      fi
      if [ ! -f "$HOME/.ssh/config.vscode" ]; then
        : > "$HOME/.ssh/config.vscode"
      fi
      chmod 600 "$HOME/.ssh/config.local" "$HOME/.ssh/config.vscode" || true
    '';
    
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
