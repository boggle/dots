{ config, lib, pkgs, dotsLocal, ... }:

let
  cfg = config.features.butterfish;

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
    enable = lib.mkEnableOption "butterfish shell with local LLM";

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
      type = lib.types.str;
      default = "bash";
      description = "Shell to wrap (bash or zsh)";
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
      bf = "butterfish shell -u '${cfg.baseUrl}' -m '${cfg.model}' -b ${pkgs.bash}/bin/bash";
    };
  };
}
