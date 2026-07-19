{
  # Scanning - CachyOS native packages
  simple-scan = {
    packages = {
      pacman = [ "simple-scan" ];
    };
  };
  
  gscan2pdf = {
    packages = {
      pacman = [ "gscan2pdf" ];
    };
  };
  
  tesseract = {
    packages = {
      pacman = [ "tesseract" "tesseract-data-eng" ];
    };
  };
}
