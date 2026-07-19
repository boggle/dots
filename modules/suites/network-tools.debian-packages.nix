# Debian alien-package specs.
#
# Intentionally conservative, matching the azurelinux3 precedent: only
# packages confirmed (or very high confidence) to exist in Debian's
# OFFICIAL repositories are listed here. `doggo` and `xh` (newer Rust-
# ecosystem CLI tools) were deliberately left out - not confirmed to be in
# Debian's official archive as of this writing (unlike lazygit, which IS
# officially packaged - see tui-apps.debian-packages.nix). Structurally
# ready but runtime-unverified (no Debian machine available to test
# against) - see memory-bank/open-questions.md.
{
  nmap = {
    feature = "network-tools";
    packages = {
      apt = [ "nmap" ];
    };
  };

  rclone = {
    feature = "network-tools";
    packages = {
      apt = [ "rclone" ];
    };
  };
}
