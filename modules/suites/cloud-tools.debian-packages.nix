# See network-tools.debian-packages.nix for the conservative-scope
# rationale (official-repos-only, verified against packages.debian.org
# for Debian 12/bookworm specifically).
#
# `lazydocker` deliberately left out - confirmed NOT in Debian's
# official archive (only available via the unofficial deb.griffo.io
# third-party repo, per that project's own docs).
{
  gh = {
    packages = {
      apt = [ "gh" ];
    };
  };

  "azure-cli" = {
    packages = {
      apt = [ "azure-cli" ];
    };
  };

  # Moved from network-tools.debian-packages.nix - now lives in
  # suites.cloud-tools.
  rclone = {
    packages = {
      apt = [ "rclone" ];
    };
  };
}
