# Reusable named "syncables" - shared sync-pattern bundles, so
# dots-local's `sync.enable = [ "name" ... ];` can activate a known
# pattern/type/on_new/ignore block by name instead of every machine's
# dots-local having to copy-paste the same definition from scratch.
#
# Deliberately a plain, self-contained data file - no `lib`/flake inputs
# needed - so sync.sh (a bare `nix eval --json --file` call, no flake
# machinery involved) can read it exactly the same way a Home Manager
# module would. See SYNC.md for the full picture, and
# modules/features/niri-noctalia.nix for an example of a feature
# asserting that a syncable it depends on is actually enabled (a required
# syncable is NOT auto-enabled just because the feature is - see that
# assertion's message for why).
{
  noctalia = {
    pattern = ".config/noctalia/**";
    type = "home";
    on_new = "prompt";
    ignore = [
      "**/preview.png"
      "**/manifest.json"
      "**/i18n/**"
      "**/shaders/**"
      "**/Assets/**"
      "**/components/**"
      "**/Components/**"
      "**/LICENSES/**"
      "**/REUSE.toml"
      "!**/settings.json"
      "!**/colors.json"
    ];
  };

  dms = {
    pattern = ".config/dms/**";
    type = "home";
    on_new = "prompt";
    ignore = [
      "**/cache/**"
      "**/*.tmp"
      "**/build/**"
    ];
  };
}
