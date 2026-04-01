{
  # Cloud Tools - CachyOS native packages
  gh = {
    feature = "cloud-tools";
    packages = {
      pacman = [ "github-cli" ];
    };
  };
  
  azure-cli = {
    feature = "cloud-tools";
    packages = {
      pacman = [ "azure-cli" ];
    };
  };
  
  lazydocker = {
    feature = "cloud-tools";
    packages = {
      pacman = [ "lazydocker" ];
    };
  };
}
