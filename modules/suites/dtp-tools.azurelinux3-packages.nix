# Moved from tui-apps.azurelinux3-packages.nix now that this package lives
# in suites.dtp-tools.
{
  graphviz = {
    packages = {
      tdnf = [ "graphviz" ];
    };
  };
}
