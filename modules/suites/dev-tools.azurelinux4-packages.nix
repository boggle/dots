# See network-tools.azurelinux4-packages.nix for the rationale/conservatism note.
{
  marksman = {
    packages = {
      dnf5 = [ "marksman" ];
    };
  };
}
