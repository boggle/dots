{
  # Cloud Tools - CachyOS native packages
  gh = {
    packages = {
      pacman = [ "github-cli" ];
    };
  };
  
  azure-cli = {
    packages = {
      pacman = [ "azure-cli" ];
    };
  };
  
  lazydocker = {
    packages = {
      pacman = [ "lazydocker" ];
    };
  };

  # Moved from network-tools.cachyos-packages.nix - now lives in
  # suites.cloud-tools.
  rclone = {
    packages = {
      pacman = [ "rclone" ];
    };
  };
}
