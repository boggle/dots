# See network-tools.debian-packages.nix for the conservative-scope rationale.
# `lazygit` confirmed present in Debian's official archive (trixie/stable,
# 2026) via packages.debian.org - unlike zellij/yazi, which are only
# reliably available through unofficial third-party repos
# (e.g. deb.griffo.io), not dots's official-repos-only convention.
{
  btop = {
    packages = {
      apt = [ "btop" ];
    };
  };

  lazygit = {
    packages = {
      apt = [ "lazygit" ];
    };
  };

  imagemagick = {
    packages = {
      apt = [ "imagemagick" ];
    };
  };

  graphviz = {
    packages = {
      apt = [ "graphviz" ];
    };
  };

  pandoc = {
    packages = {
      apt = [ "pandoc" ];
    };
  };

  pass = {
    packages = {
      apt = [ "pass" ];
    };
  };

  hledger = {
    packages = {
      apt = [ "hledger" ];
    };
  };
}
