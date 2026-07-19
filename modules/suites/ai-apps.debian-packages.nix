# See network-tools.debian-packages.nix for the conservative-scope
# rationale (official-repos-only, verified against packages.debian.org
# for Debian 12/bookworm specifically).
#
# `opencode`, `github-copilot-cli`, and `graphify` deliberately left
# out - none found in Debian's official archive (all recent/niche
# tools typically installed via their own install scripts or a
# language-specific package manager, not distro packages). `grabcontext`
# has no alien spec on any distro (see ai-apps.cachyos-packages.nix -
# its own `packages = {};` is intentionally empty).
{
  "appimages-fuse" = {
    packages = {
      # apt's FUSE2 compat library is named libfuse2, unlike pacman's
      # "fuse2" - same alien-spec key ("appimages-fuse", matching the
      # pkgName ai-apps.nix's mkAppSet call uses), different actual
      # per-manager package name, exactly what the packages.<manager>
      # structure is for.
      apt = [ "libfuse2" ];
    };
  };
}
