{
  gh = {
    feature = "cloud-tools";
    packages = {
      tdnf = [ "gh" ];
    };
  };

  azure-cli = {
    feature = "cloud-tools";
    packages = {
      tdnf = [ "azure-cli" ];
    };
  };
}
