# Host-local AppImages: enable/override entries only.
#
# App definitions (file pattern, command, desktopName, categories) live
# in dots's shared catalog (dots/contexts/<context>/appimages/manifest.nix)
# instead of being copy-pasted into every machine's dots-local. This file
# only needs to:
#   - enable a cataloged app: `{ steam.enable = true; }`
#   - override a specific field for this machine only, while keeping
#     everything else from the catalog (merged per-field, not a whole
#     replace - see dots/modules/features/appimages.nix):
#     `{ steam.file = "Steam-Different-Build-*.AppImage"; }`
#   - define a genuinely new app not worth adding to the shared catalog
#     (needs file + command at minimum, same shape as the catalog):
#     `{ myapp = { file = "MyApp-*.AppImage"; command = "myapp"; enable = true; }; }`
#
# See dots/contexts/priv/appimages/manifest.nix for what's already
# cataloged there.
{
  # steam.enable = true;
}
