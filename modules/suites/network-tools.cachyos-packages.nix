{
  nmap = {
    feature = "network-tools";
    packages = {
      pacman = [ "nmap" ];
    };
  };

  rclone = {
    feature = "network-tools";
    packages = {
      pacman = [ "rclone" ];
    };
  };

  doggo = {
    feature = "network-tools";
    packages = {
      pacman = [ "doggo" ];
    };
  };

  xh = {
    feature = "network-tools";
    packages = {
      pacman = [ "xh" ];
    };
  };
}
