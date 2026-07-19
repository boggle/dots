{ config, lib, pkgs, dotsLocal, ... }:

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
      extraConfig = ''
        # VS Code setting to point at this file: remote.SSH.configFile
        Include ~/.ssh/config.local
        Include ~/.ssh/config.vscode
      '';
      # Per-machine default identity file. Null (the default) means no
      # IdentityFile override is added. NOTE: `settings."*"` must always be
      # declared (even as `{}`) rather than conditionally omitted via
      # `lib.mkIf` - Home Manager's own programs.ssh module asserts that
      # `settings."*"` is declared whenever `enableDefaultConfig = false`
      # and `extraConfig` is set, regardless of whether it ends up empty.
      settings."*" =
        if dotsLocal.machine.sshIdentityFile != null then {
          IdentityFile = dotsLocal.machine.sshIdentityFile;
          AddKeysToAgent = "yes";
        } else {};
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
