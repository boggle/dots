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
  
  github-copilot-cli = {
    feature = "ai-apps";
    packages = {
      pacman = [ "github-copilot-cli" ];
    };
  };
}
