# See network-tools.debian-packages.nix for the conservative-scope
# rationale (official-repos-only, verified against packages.debian.org
# for Debian 12/bookworm specifically).
#
# `marksman` deliberately left out - not found in Debian's official
# archive (only available via Snapcraft or direct GitHub releases per
# upstream's own install docs). `mkcert` also left out - could not
# confirm official-archive presence for bookworm specifically.
{
  caddy = {
    packages = {
      apt = [ "caddy" ];
    };
  };
}
