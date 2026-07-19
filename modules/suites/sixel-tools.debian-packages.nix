# See network-tools.debian-packages.nix for the conservative-scope
# rationale (official-repos-only, verified against packages.debian.org
# for Debian 12/bookworm specifically).
#
# `lsix` deliberately left out - not found in Debian's official archive
# (it's a small shell script tool, apparently never packaged for
# Debian).
{
  chafa = {
    packages = {
      apt = [ "chafa" ];
    };
  };

  catimg = {
    packages = {
      apt = [ "catimg" ];
    };
  };

  "yt-dlp" = {
    packages = {
      apt = [ "yt-dlp" ];
    };
  };
}
