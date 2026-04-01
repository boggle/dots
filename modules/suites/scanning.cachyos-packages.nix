{
  # Scanning - CachyOS native packages
  simple-scan = {
    feature = "scanning";
    packages = {
      pacman = [ "simple-scan" ];
    };
  };
  
  gscan2pdf = {
    feature = "scanning";
    packages = {
      pacman = [ "gscan2pdf" ];
    };
  };
  
  tesseract = {
    feature = "scanning";
    packages = {
      pacman = [ "tesseract" "tesseract-data-eng" ];
    };
  };
}
