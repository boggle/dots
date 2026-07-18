# See network.debian-packages.nix for the conservative-scope rationale.
# `lazygit` confirmed present in Debian's official archive (trixie/stable,
# 2026) via packages.debian.org - unlike zellij/yazi, which are only
# reliably available through unofficial third-party repos
# (e.g. deb.griffo.io), not dots's official-repos-only convention.
{
  btop = {
    feature = "tui-apps";
    packages = {
      apt = [ "btop" ];
    };
  };

  lazygit = {
    feature = "tui-apps";
    packages = {
      apt = [ "lazygit" ];
    };
  };

  imagemagick = {
    feature = "tui-apps";
    packages = {
      apt = [ "imagemagick" ];
    };
  };

  graphviz = {
    feature = "tui-apps";
    packages = {
      apt = [ "graphviz" ];
    };
  };

  pandoc = {
    feature = "tui-apps";
    packages = {
      apt = [ "pandoc" ];
    };
  };

  pass = {
    feature = "tui-apps";
    packages = {
      apt = [ "pass" ];
    };
  };

  hledger = {
    feature = "tui-apps";
    packages = {
      apt = [ "hledger" ];
    };
  };
}
