{
  # AI Apps - CachyOS native packages
  grabcontext = {
    feature = "ai-apps";
    packages = {
    };
  };

  opencode = {
    feature = "ai-apps";
    packages = {
      pacman = [ "opencode" ];
    };
  };

graphify = {
    feature = "ai-apps";
    packages = {
      paru = [ "graphifyy" ];
    };
  };
  
  github-copilot-cli = {
    feature = "ai-apps";
    packages = {
      pacman = [ "github-copilot-cli" ];
    };
  };

  # FUSE2 support for AppImages
  appimages-fuse = {
    feature = "ai-apps";
    packages = {
      pacman = [
        "fuse2"           # FUSE2 library required by AppImages
      ];
    };
  };

}
