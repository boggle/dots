{ ... }:

{
  imports = [
    ../features/viewer.nix
    ../features/network.nix
    ../features/appimages.nix

    ../suites/network-tools.nix
    ../suites/git-tools.nix
    ../suites/dev-tools.nix
    ../suites/tui-apps.nix
    ../suites/gui-apps.nix
    ../suites/sixel-tools.nix
  ];
}
