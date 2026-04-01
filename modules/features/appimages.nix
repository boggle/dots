{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.features.appimages;
  local = inputs.dots-local;

  # Load shared manifests (profiles/common, profiles/<profile>)
  loadSharedManifests = { profile }: 
    let
      commonPath = ../../profiles/common/appimages/manifest.nix;
      profilePath = ../../profiles/${profile}/appimages/manifest.nix;
      
      commonExists = builtins.pathExists commonPath;
      profileExists = builtins.pathExists profilePath;
      
      commonApps = if commonExists then import commonPath else {};
      profileApps = if profileExists then import profilePath else {};
      
      merged = commonApps // profileApps;
    in
      merged;

  # Load host-local appimages from dots-local flake output
  hostLocalApps = local.appimages or {};

  # Check if app should be enabled
  isEnabled = name: app:
    let
      manifestEnabled = app.enable or true;
      moduleOverride = cfg.apps.${name}.enable or null;
    in
      if moduleOverride != null then moduleOverride
      else manifestEnabled;

  # Create wrapper for shared (store-backed) AppImage
  mkSharedWrapper = name: app:
    let
      command = app.command or name;
      desktopName = app.desktopName or name;
      categories = app.categories or [ "Utility" ];
      icon = app.icon or (lib.toLower command);
      
      wrapper = pkgs.writeShellScriptBin command ''
        exec ${app.src} "$@"
      '';
      
      desktopEntry = pkgs.makeDesktopItem {
        name = command;
        inherit desktopName icon;
        genericName = desktopName;
        exec = "${command} %U";
        inherit categories;
        comment = "${desktopName} (AppImage)";
      };
    in
      pkgs.symlinkJoin {
        name = "${command}-wrapped";
        paths = [ wrapper desktopEntry ];
      };

  # Create wrapper for host-local (runtime) AppImage
  mkHostLocalWrapper = name: app:
    let
      command = app.command or name;
      desktopName = app.desktopName or name;
      categories = app.categories or [ "Utility" ];
      icon = app.icon or (lib.toLower command);
      filePattern = app.file;  # e.g., "Steam-*.AppImage" or "Steam.AppImage"
      
      wrapper = pkgs.writeShellScriptBin command ''
        APPDIR="${cfg.localDir}"
        
        # Find all files matching the pattern and count them
        MATCHING_FILES=$(find "$APPDIR" -maxdepth 1 -name "${filePattern}" -type f 2>/dev/null)
        FILE_COUNT=$(echo "$MATCHING_FILES" | grep -c '^' || echo "0")
        
        if [[ "$FILE_COUNT" -eq 0 ]]; then
          echo "ERROR: No AppImage found matching '${filePattern}' in $APPDIR" >&2
          echo "Place the AppImage file there and ensure it matches the pattern" >&2
          exit 1
        fi
        
        if [[ "$FILE_COUNT" -gt 1 ]]; then
          echo "ERROR: Multiple AppImages found matching '${filePattern}' in $APPDIR" >&2
          echo "Please keep only one version. Found:" >&2
          echo "$MATCHING_FILES" | sed 's/^/  /' >&2
          exit 1
        fi
        
        # Exactly one match - use it
        TARGET=$(echo "$MATCHING_FILES" | head -1)
        
        if [[ ! -x "$TARGET" ]]; then
          echo "ERROR: AppImage is not executable: $TARGET" >&2
          echo "Run: chmod +x '$TARGET'" >&2
          exit 1
        fi
        
        exec "$TARGET" "$@"
      '';
      
      desktopEntry = pkgs.makeDesktopItem {
        name = command;
        inherit desktopName icon;
        genericName = desktopName;
        exec = "${command} %U";
        inherit categories;
        comment = "${desktopName} (AppImage)";
      };
    in
      pkgs.symlinkJoin {
        name = "${command}-wrapped";
        paths = [ wrapper desktopEntry ];
      };

  # Determine which wrapper to use based on app definition
  mkWrappedApp = name: app:
    if app ? file then mkHostLocalWrapper name app
    else if app ? src then mkSharedWrapper name app
    else null;

  # Load and merge all apps
  sharedApps = loadSharedManifests { profile = local.profile or "priv"; };
  allApps = sharedApps // hostLocalApps;
  
  # Filter enabled and create packages
  enabledApps = lib.filterAttrs isEnabled allApps;
  wrappedPackages = lib.filter (x: x != null) (lib.mapAttrsToList mkWrappedApp enabledApps);
in
{
  options.features.appimages = {
    enable = lib.mkEnableOption "AppImage support via simple wrapper scripts";
    
    localDir = lib.mkOption {
      type = lib.types.str;
      default = local.appimagesDir or "${config.home.homeDirectory}/Applications/AppImages";
      description = ''
        Directory where host-local AppImages are stored at runtime.
        These AppImages are not imported into the Nix store.
      '';
    };
    
    apps = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          enable = lib.mkOption {
            type = lib.types.nullOr lib.types.bool;
            default = null;
            description = ''
              Whether to enable this AppImage. 
              null = use manifest default (usually enabled)
              true/false = override manifest setting
            '';
          };
        };
      });
      default = {};
      description = ''
        Per-AppImage enable overrides. Set appname.enable = false to disable 
        a specific AppImage from the manifest without removing it.
      '';
      example = lib.literalExpression ''
        {
          steam.enable = false;  # Disable steam even if in manifest
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      appimage-run
      appimageupdate
    ] ++ wrappedPackages;
  };
}
