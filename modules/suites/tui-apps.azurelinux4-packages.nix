# See network-tools.azurelinux4-packages.nix for the rationale/conservatism note.
{
  graphviz = {
    packages = {
      dnf5 = [ "graphviz" ];
    };
  };
}
