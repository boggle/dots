{
  marksman = {
    packages = {
      pacman = [ "marksman" ];
    };
  };

  # mkcert - locally-trusted development certificates
  mkcert = {
    packages = {
      pacman = [ "mkcert" ];
    };
  };

  # caddy - modern web server with automatic HTTPS
  caddy = {
    packages = {
      pacman = [ "caddy" ];
    };
  };
}
