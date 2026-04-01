{
  nmap = {
    feature = "network";
    packages = {
      pacman = [ "nmap" ];
    };
  };

  rclone = {
    feature = "network";
    packages = {
      pacman = [ "rclone" ];
    };
  };

  doggo = {
    feature = "network";
    packages = {
      pacman = [ "doggo" ];
    };
  };

  xh = {
    feature = "network";
    packages = {
      pacman = [ "xh" ];
    };
  };
}
