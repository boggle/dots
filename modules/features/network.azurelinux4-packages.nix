# Azure Linux 4.0 (Phase 3+ of the re-architecture - see
# memory-bank/architecture.md section 4, memory-bank/decisions.md
# 2026-07-18 "Azure Linux 4 alien specs").
#
# Mirrors network.azurelinux3-packages.nix's exact package set (same
# conservative confidence level - Azure Linux is an intentionally lean,
# cloud/container-focused distro, not a general-purpose one, so this
# deliberately does NOT extend further the way debian's specs did).
# Uses the `dnf5` manager key (Azure Linux 4 replaced tdnf with dnf5 - see
# modules/core/alien-packages.nix). Structurally ready, runtime-unverified.
{
  nmap = {
    feature = "network";
    packages = {
      dnf5 = [ "nmap" ];
    };
  };
}
