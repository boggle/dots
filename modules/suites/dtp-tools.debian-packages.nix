# Moved from tui-apps.debian-packages.nix now that these packages live in
# suites.dtp-tools. See network-tools.debian-packages.nix for the
# conservative-scope rationale (official-repos-only).
{
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
}
