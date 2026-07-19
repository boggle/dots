{
  marksman = {
    feature = "dev-tools";
    packages = {
      pacman = [ "marksman" ];
    };
  };

  # mkcert - locally-trusted development certificates
  mkcert = {
    feature = "dev-tools";
    packages = {
      pacman = [ "mkcert" ];
    };
  };

  # caddy - modern web server with automatic HTTPS
  caddy = {
    feature = "dev-tools";
    packages = {
      pacman = [ "caddy" ];
    };
  };
}
