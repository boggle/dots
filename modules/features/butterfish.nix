{ config, lib, pkgs, dotsLocal, ... }:

let
  coreLib = import ../core/lib.nix { inherit lib; };
  cfg = config.features.butterfish;

  # Resolves cfg.shell ("bash" or "zsh") to the actual binary path used
  # by the `bf` alias below - this was previously a declared-but-
  # unwired option (the alias always hardcoded bash regardless of this
  # setting). Only the shell *butterfish itself wraps/spawns* is
  # affected here - the rest of `dots` remains bash-only (nixon.nix,
  # the whole shell-bootstrap hybrid, etc. have no zsh support), so
  # setting `shell = "zsh"` gets you a zsh subshell under `bf` without
  # changing anything about your actual login/interactive shell setup.
  shellPkg = if cfg.shell == "zsh" then pkgs.zsh else pkgs.bash;

  # Butterfish shell wrapper for local LLMs
  # https://butterfi.sh - OpenAI-compatible CLI shell
  butterfish-pkg = pkgs.buildGoModule rec {
    pname = "butterfish";
    version = "0.4.3";

    src = pkgs.fetchFromGitHub {
      owner = "bakks";
      repo = "butterfish";
      rev = "v${version}";
      sha256 = "0gn3pyrc2n9xpls8hlvndi3ziijwq81xxls805xy40plkak14cw5";
    };

    vendorHash = "sha256-b3clnCSWgf1Ro4qWUUmOjwpWEMzeff2O0zZV21efLdg=";

    # Skip tests - they try to download tiktoken encodings from the internet
    doCheck = false;

    meta = with lib; {
      description = "Shell with AI superpowers";
      homepage = "https://butterfi.sh";
      license = licenses.mit;
    };
  };
in {
  options.features.butterfish = {
    enable = coreLib.mkDefaultDisabledOption "butterfish shell with local LLM";

    baseUrl = lib.mkOption {
      type = lib.types.str;
      default = dotsLocal.butterfishEndpoint;
      description = "OpenAI-compatible API base URL";
    };

    apiKey = lib.mkOption {
      type = lib.types.str;
      default = dotsLocal.butterfishApiKey;
      description = "API key for the endpoint";
    };

    model = lib.mkOption {
      type = lib.types.str;
      default = dotsLocal.butterfishModel;
      description = "Model name to use (should match the model loaded in llama.cpp)";
    };

    shell = lib.mkOption {
      type = lib.types.enum [ "bash" "zsh" ];
      default = "bash";
      description = ''
        Shell for butterfish itself to wrap/spawn when running `bf`
        (`butterfish shell -b <shell>`) - does not affect your actual
        login/interactive shell setup, which stays bash-only regardless
        (see modules/core/nixon.nix).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ butterfish-pkg ];

    # Butterfish config directory and env file
    home.file.".config/butterfish/butterfish.env" = {
      text = ''
        OPENAI_TOKEN=${cfg.apiKey}
      '';
    };

    # Alias for easy invocation
    programs.bash.shellAliases = {
      bf = "butterfish shell -u '${cfg.baseUrl}' -m '${cfg.model}' -b ${shellPkg}/bin/${cfg.shell}";
    };
  };
}
