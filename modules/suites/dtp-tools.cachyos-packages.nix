# Moved from tui-apps.cachyos-packages.nix (DTP section) now that these
# packages live in suites.dtp-tools.
{
  imagemagick = {
    packages = {
      pacman = [ "imagemagick" ];
    };
  };

  graphviz = {
    packages = {
      pacman = [ "graphviz" ];
    };
  };

  pandoc = {
    packages = {
      pacman = [ "pandoc" ];
    };
  };

  typst = {
    packages = {
      pacman = [ "typst" ];
    };
  };
}
