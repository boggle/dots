# See network-tools.azurelinux4-packages.nix for the rationale/conservatism note.
{
  gh = {
    packages = {
      dnf5 = [ "gh" ];
    };
  };

  azure-cli = {
    packages = {
      dnf5 = [ "azure-cli" ];
    };
  };
}
