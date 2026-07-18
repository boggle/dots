# See network.azurelinux4-packages.nix for the rationale/conservatism note.
{
  gh = {
    feature = "cloud-tools";
    packages = {
      dnf5 = [ "gh" ];
    };
  };

  azure-cli = {
    feature = "cloud-tools";
    packages = {
      dnf5 = [ "azure-cli" ];
    };
  };
}
