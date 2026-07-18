# Debian alien-package specs (Phase 3 of the re-architecture - see
# memory-bank/architecture.md section 4, memory-bank/plan.md Phase 3).
#
# Intentionally conservative, matching the existing azurelinux3 precedent:
# only packages confirmed (or very high confidence) to exist in Debian's
# OFFICIAL repositories are listed here. `doggo` and `xh` (newer Rust-
# ecosystem CLI tools) were deliberately left out - not confirmed to be in
# Debian's official archive as of this writing (unlike lazygit, which IS
# officially packaged - see tui-apps.debian-packages.nix). This is
# structurally ready but runtime-unverified (no Debian machine available
# to test against) - see memory-bank/open-questions.md.
{
  nmap = {
    feature = "network";
    packages = {
      apt = [ "nmap" ];
    };
  };

  rclone = {
    feature = "network";
    packages = {
      apt = [ "rclone" ];
    };
  };
}
