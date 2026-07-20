{
  nmap = {
    packages = {
      pacman = [ "nmap" ];
    };
  };

  doggo = {
    packages = {
      pacman = [ "doggo" ];
    };
  };

  xh = {
    packages = {
      pacman = [ "xh" ];
    };
  };

  # Moved from tui-apps.cachyos-packages.nix - both now live in
  # suites.network-tools.
  bandwhich = {
    packages = {
      pacman = [ "bandwhich" ];
    };
  };

  gping = {
    packages = {
      pacman = [ "gping" ];
    };
  };
}
