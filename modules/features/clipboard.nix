{ config, lib, pkgs, ... }:

let
  cfg = config.features.clipboard;
  backend = cfg.backend;
  sed = "${pkgs.gnused}/bin/sed";

  # Bash array literals (each element individually double-quoted) so the
  # generated shell script can build real bash arrays out of them below -
  # this preserves argument boundaries exactly (notably the wsl paste
  # command, whose "-Command" argument itself contains an embedded space:
  # "Get-Clipboard -Raw" must stay as ONE array element).
  copyCmdArray = {
    wayland = ''"${pkgs.wl-clipboard}/bin/wl-copy"'';
    x11     = ''"${pkgs.xclip}/bin/xclip" "-selection" "clipboard"'';
    wsl     = ''"clip.exe"'';
    macos   = ''"pbcopy"'';
  }.${backend};

  pasteCmdArray = {
    wayland = ''"${pkgs.wl-clipboard}/bin/wl-paste"'';
    x11     = ''"${pkgs.xclip}/bin/xclip" "-selection" "clipboard" "-o"'';
    wsl     = ''"powershell.exe" "-NoProfile" "-Command" "Get-Clipboard -Raw"'';
    macos   = ''"pbpaste"'';
  }.${backend};

in
{
  options.features.clipboard = {
    enable = lib.mkEnableOption "Cross-platform clipboard feature";
    backend = lib.mkOption {
      type = lib.types.enum [ "wayland" "x11" "wsl" "macos" ];
      description = "Clipboard backend to use.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ gnused ]
      ++ lib.optionals (backend == "wayland") [ wl-clipboard ]
      ++ lib.optionals (backend == "x11") [ xclip ];

    # The bulk of this logic lives in a real, static, shellcheck-able file.
    # This small preamble resolves the Nix-level package paths /
    # backend-selected commands into plain shell variables (and, for the
    # copy/paste commands, real bash arrays - see the copyCmdArray/
    # pasteCmdArray comment above for why arrays rather than plain
    # strings) that the static script references.
    programs.bash.initExtra = ''
      SED_BIN="${sed}"
      PERL_BIN="${pkgs.perl}/bin/perl"
      BACKEND="${backend}"
      COPY_CMD=(${copyCmdArray})
      PASTE_CMD=(${pasteCmdArray})
    '' + builtins.readFile ./clipboard/clipboard.sh;
  };
}