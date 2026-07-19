{
  # Both niri and noctalia are enabled together when features.niri-noctalia.enable = true
  niri = {
    packages = {
      pacman = [
        "cachyos-niri-noctalia"  
        "niri"
      ];
    };
  };
  
  noctalia-shell = {
    packages = {
      pacman = [ 
        "noctalia-shell"
        "noctalia-qs"
        "cliphist" 
      ];
    };
  };
}
