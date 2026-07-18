# See network.azurelinux4-packages.nix for the rationale/conservatism note.
{
  graphviz = {
    feature = "tui-apps";
    packages = {
      dnf5 = [ "graphviz" ];
    };
  };
}
