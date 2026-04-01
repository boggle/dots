{
  # Both niri and noctalia are enabled together when features.niri-noctalia.enable = true
  niri = {
    feature = "niri-noctalia";
    packages = {
      pacman = [
        "cachyos-niri-noctalia"  
        "niri"
      ];
    };
  };
  
  noctalia-shell = {
    feature = "niri-noctalia";
    packages = {
      pacman = [ 
        "noctalia-shell"
        "noctalia-qs"
        "cliphist" 
      ];
    };
  };
}
