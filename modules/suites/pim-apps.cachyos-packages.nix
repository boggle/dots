{
  khal = {
    feature = "pim-apps";
    option = "khal";
    packages = {
      pacman = [ "khal" ];
      paru = [ ];
    };
  };
  
  todoman = {
    feature = "pim-apps";
    option = "todoman";
    packages = {
      pacman = [ "todoman" ];
      paru = [ ];
    };
  };
  
  pimsync = {
    feature = "pim-apps";
    option = "pimsync";
    packages = {
      pacman = [ "pimsync" ];
      paru = [ ];
    };
  };
  
  khard = {
    feature = "pim-apps";
    option = "khard";
    packages = {
      pacman = [ "khard" ];
      paru = [ ];
    };
  };
  
  taskwarrior = {
    feature = "pim-apps";
    option = "taskwarrior";
    packages = {
      pacman = [ "taskwarrior" ];
      paru = [ ];
    };
  };
  
  superproductivity = {
    feature = "pim-apps";
    option = "superproductivity";
    packages = {
      pacman = [];
      paru = [ "superproductivity" ];
    };
  };
}
