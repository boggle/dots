{ config, lib, pkgs, alien, ... }:

let
  cfg = config.features.network;
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
    home.packages = builtins.filter (p: p != null) [
      (alien.mkEntry cfg.nmap "nmap" pkgs.nmap)
      (alien.mkEntry cfg.rclone "rclone" pkgs.rclone)
      (alien.mkEntry cfg.doggo "doggo" pkgs.doggo)
      (alien.mkEntry cfg.xh "xh" pkgs.xh)
    ];

    alienPackages.enabledPackages =
      (lib.optional cfg.nmap "nmap") ++
      (lib.optional cfg.rclone "rclone") ++
      (lib.optional cfg.doggo "doggo") ++
      (lib.optional cfg.xh "xh");

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      extraConfig = ''
        # VS Code setting to point at this file: remote.SSH.configFile
        Include ~/.ssh/config.local
        Include ~/.ssh/config.vscode
      '';
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
