# Moved from tui-apps.azurelinux4-packages.nix now that this package lives
# in suites.dtp-tools. See network-tools.azurelinux4-packages.nix for the
# rationale/conservatism note.
{
  graphviz = {
    packages = {
      dnf5 = [ "graphviz" ];
    };
  };
}
