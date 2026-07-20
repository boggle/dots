{ config, lib, pkgs, dotsLocal, ... }:

let
  coreLib = import ../core/lib.nix { inherit lib; };
  cfg = config.features.network;
in
{
  options.features.network = {
    enable = coreLib.mkDefaultEnabledOption "Enable network services";

    # SSH
    sshAgent = coreLib.mkDefaultEnabledOption "SSH agent";
    
    # GPG
    gpgAgent = coreLib.mkDefaultEnabledOption "GPG agent";
    gpgSsh = coreLib.mkDefaultDisabledOption "GPG SSH support (use GPG keys for SSH)";
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
          AddKeysToAgent = dotsLocal.machine.sshAddKeysToAgent;
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

    # GPG_TTY is needed for gpg-agent's pinentry to prompt correctly in a
    # terminal - only relevant when gpg-agent is actually enabled.
    programs.bash.initExtra = lib.mkIf cfg.gpgAgent ''
      export GPG_TTY=$(tty 2>/dev/null || echo /dev/tty)
    '';
  };
}
