# See network-tools.azurelinux4-packages.nix for the rationale/conservatism note.
{
  marksman = {
    feature = "dev-tools";
    packages = {
      dnf5 = [ "marksman" ];
    };
  };
}
