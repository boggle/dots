# Azure Linux 4.0 alien-package specs.
#
# Mirrors network-tools.azurelinux3-packages.nix's exact package set (same
# conservative confidence level - Azure Linux is an intentionally lean,
# cloud/container-focused distro, not a general-purpose one, so this
# deliberately does not extend further the way debian's specs did).
# Uses the `dnf5` manager key (Azure Linux 4 replaced tdnf with dnf5 - see
# modules/core/alien-packages.nix). Structurally ready, runtime-unverified.
{
  nmap = {
    feature = "network-tools";
    packages = {
      dnf5 = [ "nmap" ];
    };
  };
}
