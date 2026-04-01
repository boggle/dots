{
  # TUI Apps - CachyOS native packages
  btop = {
    feature = "tui-apps";
    packages = {
      pacman = [ "btop" ];
    };
  };

  zellij = {
    feature = "tui-apps";
    packages = {
      pacman = [ "zellij" ];
    };
  };

  lazygit = {
    feature = "tui-apps";
    packages = {
      pacman = [ "lazygit" ];
    };
  };

  yazi = {
    feature = "tui-apps";
    packages = {
      pacman = [ "yazi" ];
    };
  };
  
  bandwhich = {
    feature = "tui-apps";
    packages = {
      pacman = [ "bandwhich" ];
    };
  };
  
  vhs = {
    feature = "tui-apps";
    packages = {
      pacman = [ "vhs" ];
    };
  };
  
  "fresh-editor" = {
    feature = "tui-apps";
    packages = {
      pacman = [ "fresh-editor" ];
    };
  };

  # Email
  aerc = {
    feature = "tui-apps";
    packages = {
      pacman = [ "aerc" ];
    };
  };
  
  deltachat-desktop = {
    feature = "tui-apps";
    packages = {
      pacman = [ "deltachat-desktop" ];
    };
  };
  
  # DTP
  imagemagick = {
    feature = "tui-apps";
    packages = {
      pacman = [ "imagemagick" ];
    };
  };
  
  graphviz = {
    feature = "tui-apps";
    packages = {
      pacman = [ "graphviz" ];
    };
  };
  
  pandoc = {
    feature = "tui-apps";
    packages = {
      pacman = [ "pandoc" ];
    };
  };
  
  typst = {
    feature = "tui-apps";
    packages = {
      pacman = [ "typst" ];
    };
  };
  
  # Network/Utils
  gping = {
    feature = "tui-apps";
    packages = {
      pacman = [ "gping" ];
    };
  };

  # Social/Utils
  posting = {
    feature = "tui-apps";
    packages = {
      paru = [ "posting-git" ];
    };
  };

  frogmouth = {
    feature = "tui-apps";
    packages = {
      paru = [ "frogmouth" ];
    };
  };
  
  hledger = {
    feature = "tui-apps";
    packages = {
      pacman = [ "hledger" ];
    };
  };
}
