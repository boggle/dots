# Phase 2 Host Migration Notes: laputa & triomino

Status: **action required by the user on these two machines**

`profiles/priv/hosts/{chromaden,laputa,triomino}.nix` were all retired in
Phase 2 (see `plan.md`) - `dots` no longer contains per-host files at all.
Chromaden's equivalent config was fully migrated into the real
`~/dots-local` on this machine (this checkout has access to it) and
live-validated. **laputa and triomino have their own separate, private
`dots-local` repos on those machines, which this session has no access
to** - so this file documents exactly what needs to be added there. Until
this is done, applying the updated `dots` on those machines will fall back
to schema defaults (no compositor, no display config, no ssh identity,
etc.) - it will still evaluate/apply successfully, just without that
machine's specific behavior restored.

Everything below was verified via `nix eval`/`nix build` against synthetic
`dots-local` copies mimicking this exact shape (not live-tested on the
actual laputa/triomino hardware, since this session can't reach them).

## laputa

Add to `dots-local/flake.nix` (alongside the existing identity fields):

```nix
gpu = "intel";
compositor = "niri";

machine = {
  sshIdentityFile = "~/.ssh/id_github_laputa";
  # terminal/renderDrmDevice: leave at schema defaults (ghostty / null -
  # laputa's integrated Intel graphics never needed a renderDrmDevice
  # override, same as before)
  display = {
    output = "eDP-1";
    ecoMode = { resolution = "1920x1200"; refreshRate = "60.000"; brightness = "30%"; };
    perfMode = { resolution = "1920x1200"; refreshRate = "120.000"; };
  };
};

extraModules = [ ./host-laputa.nix ];
```

Create `dots-local/host-laputa.nix`:

```nix
{ config, pkgs, lib, ... }:
{
  home.packages = with pkgs; [ bluez localsend ];

  home.sessionVariables = {
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent.socket";
    GDK_SCALE = "1";
  };

  xdg.configFile."xdg-desktop-portal/portals.conf".text = ''
    [preferred]
    default=gnome;gtk;
  '';

  suites.scanning = {
    enable = true;
    simple-scan = true;
    gscan2pdf = true;
    tesseract = true;
  };
}
```

AppImages: laputa's existing `dots-local/appimages.nix` (steam, betterbird,
buttercup, discord, tuta with `enable = true`) needs no changes - it's
already read directly via `dotsLocal.appimages` (schema-typed now, but
backward-compatible with the existing shape).

## triomino

Add to `dots-local/flake.nix`:

```nix
isWsl = true;
graphicalBackend = "wsl";  # must be "wsl" specifically - features.opener/
                           # clipboard read this directly regardless of isWsl

machine = {
  sshIdentityFile = "~/.ssh/id_github_triomino";
};

extraModules = [ ./host-triomino.nix ];
```

Create `dots-local/host-triomino.nix`:

```nix
{ config, pkgs, lib, ... }:
{
  home.packages = with pkgs; [ bluez localsend ];

  suites.tui-apps = {
    enable = true;
    aerc = false;
    deltachat = false;
    pandoc = false;
    typst = false;
  };

  suites.ai-apps = {
    enable = true;
    opencode = true;
    grabcontext = true;
    pi = true;
    # NOTE: do NOT re-list piPackages here - it's inherited from
    # modules/contexts/priv.nix's default list now. The old
    # profiles/priv/hosts/triomino.nix duplicated that 13-entry list
    # verbatim; this was flagged as a bug during the original inventory
    # and is naturally fixed by not overriding it.
  };
}
```

**Already handled automatically, no action needed:**
- The VSCode Remote-SSH + WSL shell-integration workaround (starship
  PROMPT_COMMAND cleanup, sourcing VS Code's shellIntegration-bash.sh,
  zoxide/direnv manual re-init) - generalized into
  `modules/features/wsl-shell-integration.nix`, auto-enabled by
  `composition-rules.nix` whenever `isWsl = true`.
- `WAYLAND_DISPLAY`/`DIRENV_LOG_FORMAT` session variables - now set by the
  same `isWsl` composition rule.
- `sd-switch` - now universally imported/enabled (previously required an
  explicit per-host import).

**Dropped, was already dead/commented-out code in the old host file:**
the colorized `direnv/direnvrc` `log_status` override, and the
commented-out `suites.gui-apps`/`suites.scanning`/`features.appimages`
blocks. If you actually want the direnv color override, it's small enough
to add directly to `host-triomino.nix`'s `xdg.configFile."direnv/direnvrc"`
if desired - not carried forward since it was a minor personal touch, not
core functionality.

## Verification checklist for whoever applies these

- [ ] `apply-dots` succeeds on laputa with the above additions
- [ ] `apply-dots` succeeds on triomino with the above additions
- [ ] laputa: niri-noctalia session starts, power-toggle.sh works (eco/perf
      modes), all 5 AppImages launch, scanning tools present
- [ ] triomino: WSL shell integration still works in VS Code's terminal,
      opener/clipboard use `wslview`/`clip.exe` correctly, `pi` extension
      list matches what was there before (now inherited rather than
      duplicated - should be identical)
- [ ] Once verified, this file can be deleted (or archived) - it's a
      one-time migration record, not ongoing documentation
