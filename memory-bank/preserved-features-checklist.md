# Preserved-Features Checklist

Every one of these must keep working (or work strictly better) by the end of
the re-architecture. Check off once verified post-refactor (not just
"ported the code" — actually confirmed via eval and/or live test).

- [x] Alien (native) package management — pacman/paru (cachyos), zypper
      (opensuse), tdnf (azurelinux3), apt (debian, Phase 3), dnf5
      (azurelinux4, Phase 3 addendum). All structurally verified via
      synthetic distro eval/build (Phase 3); pacman/paru live-verified on
      chromaden throughout every phase (`update-alien-packages` run for
      real repeatedly, incl. the Phase 0 orphan-detection bugfixes).
      Debian/Azure Linux 4 remain structurally-ready-but-runtime-
      unverified (no real hardware available) - logged in
      `open-questions.md`, not a gap introduced by this re-architecture.
- [x] AppImages — host-local (runtime dir) mode (eval/build-verified for
      chromaden real + laputa synthetic, all 5 laputa wrappers resolve)
- [x] AppImages — shared (Nix store) mode (Phase 9: temporarily created a
      real `profiles/priv/appimages/manifest.nix` + fake `.AppImage` file,
      confirmed `loadSharedManifests` discovers it, the resulting
      `testapp-wrapped` package builds successfully, the wrapper script
      executes correctly, and the generated `.desktop` entry has the
      right `Name`/`Exec`/`Categories`/`Comment` fields - then removed
      the test files, confirmed `git status` clean again. Mechanism is
      real and working, just genuinely unused today (no manifest.nix
      currently exists in the repo) - same as before this whole
      re-architecture, not a regression.
- [x] Package tuning — global scope (overlay) (chromaden's
      ripgrep/fd/noctalia-qs/ghostty/tesseract still resolve via
      `tunePackagesByContext.priv` in flake.nix)
- [x] Package tuning — local scope (PATH shadowing) (mechanism untouched by
      Phase 2, still imported via contexts/priv.nix -> core -> tune-support.nix)
- [x] Package tuning — wrapped scope (suffix binaries) (same as above)
- [x] Settings sync system (`sync.sh`, `settings/<host>/{home,root}/**`) -
      untouched by Phase 2 (profiles/*/sync.json deliberately left alone).
      Phase 9: live-ran `dots-sync -n` (dry run, non-destructive) for
      real on chromaden - correctly resolved the priv profile, loaded 252
      global ignore patterns + 2 tracked patterns, and correctly reported
      unchanged/changed files for every real tracked noctalia config path.
- [x] niri-noctalia desktop (chromaden: enable/terminal/renderDrmDevice all
      confirmed resolving identically via composition-rules.nix; full
      in-session behavior not live-tested, only config resolution).
      Phase 8: all 4 embedded helper scripts (terminal-in-current-column,
      terminal-scratchpad-toggle, start-xwayland-satellite, wait-for-x11)
      externalized to `modules/features/niri-noctalia/*.sh`; re-verified
      via before/after derivation diff (byte-identical modulo whitespace
      and the expected inlined-path-vs-shell-variable substitutions) and
      a functional smoke test of wait-for-x11 (correctly waits for a real
      unix socket, sets DISPLAY, execs the passed command)
- [x] llama-cpp CUDA/Zen5-tuned build (chromaden - cmakeFlags override via
      dots-local/host-chromaden.nix confirmed identical to the original)
- [x] butterfish AI shell integration (chromaden: features.butterfish.enable
      confirmed true via host-chromaden.nix)
- [x] ai-apps suite: grabcontext, opencode, github-copilot-cli, pi, graphify
      (chromaden + triomino-synthetic both confirmed resolving correctly,
      including triomino's piPackages now inheriting rather than duplicating)
- [x] gui-apps suite (chromaden's extras - chromium/libreoffice/gimp/
      inkscape/vlc/flameshot - confirmed via host-chromaden.nix)
- [x] tui-apps suite (triomino-synthetic's aerc/deltachat/pandoc/typst=false
      override confirmed resolving in Phase 2; migrated to `mkAppSet` in
      Phase 4 with a comprehensive byte-identical `config.home.packages`
      before/after diff; Phase 9 spot-check confirms
      `config.suites.tui-apps` still resolves correctly on chromaden)
- [x] pim-apps suite (Phase 4's `mkAppSet` migration covered by the same
      full-config byte-identical diff; Phase 9 spot-check confirms
      `config.suites.pim-apps` resolves correctly on chromaden - superproductivity=true)
- [x] scanning suite (chromaden real + laputa synthetic both confirmed
      `enable = true` with all 3 sub-tools)
- [x] sixel-tools suite (Phase 4's `mkAppSet` migration - `mpv` deliberately
      excluded, handled separately via `programs.mpv`'s custom sixel build
      - covered by the full-config byte-identical diff; Phase 9 spot-check
      confirms `config.suites.sixel-tools` resolves correctly on chromaden)
- [x] cloud-tools suite — now imported universally in composition.nix and
      axis-defaulted on for `profile == "work"` (no longer dormant/unreachable)
- [x] dev-tools feature (Phase 1's homeDirectory fix; Phase 4's partial
      `mkAppSet` migration - marksman/mkcert/caddy only - covered by the
      full-config byte-identical diff; Phase 9 spot-check confirms
      `config.features.dev-tools` resolves correctly on chromaden, all
      18 sub-toggles present with expected values)
- [x] git feature (untouched throughout; Phase 9 spot-check confirms
      `config.features.git` resolves correctly on chromaden, all 6
      sub-toggles present with expected values)
- [x] clipboard (`clipin`/`clipout`/`clipfile`/`teeclip`) — wsl backend
      confirmed auto-selected via the `isWsl` composition rule for
      triomino-synthetic; wayland/x11/macos paths untouched, unaffected.
      Phase 8: bash logic externalized to
      `modules/features/clipboard/clipboard.sh`; re-verified all 4
      backends' resolved copy/paste commands (correct argv boundaries,
      including the tricky wsl embedded-quote case) plus a full
      functional test harness (trim/ANSI-strip/clipfile) - all correct.
- [x] opener (`o`) — same as clipboard above (untouched by Phase 8)
- [x] viewer (`v`) — Phase 8: bash logic externalized to
      `modules/features/viewer/v.sh`; re-verified via before/after
      derivation diff (byte-identical modulo the expected inlined-path-
      vs-shell-variable substitution) and functional smoke tests
      (`--help`, JSON/CSV formatting paths)
- [x] fonts feature — Phase 9: moved to `composition.nix`'s universal
      imports (was priv-only) so `niri-noctalia.nix` (universal) can
      contribute to `features.fonts.required`; `pkgs.inter` now actually
      flows through. **Important caveat, not a regression**:
      `features.fonts.enable` has never been `true` anywhere (confirmed
      via git history predating this whole re-architecture) - the module
      itself remains dormant pending an explicit user decision, logged in
      `open-questions.md`. What Phase 9 fixed is the *wiring*
      (`fonts.required` now gets contributed to, resolving to
      `[ inter-4.1 ]` when niri-noctalia is enabled), not the dormant
      `enable` flag itself.
- [x] sd-switch (now universally imported/enabled by default=true, was
      previously per-host-import-only; confirmed still active)
- [x] nixon shell-bootstrap toggle (`NIXON=1/0`) — Phase 6 retargeted
      `.bashrc-dots`/`.profile-dots` and live-checkpointed successfully
      (generation 316); the gatekeeper logic reading `$NIXON` to decide
      whether to source `.bashrc-nix` is unchanged since before Phase 6,
      confirmed present in the current `modules/core/nixon.nix`.
- [x] Per-host settings sync data (chromaden, laputa — triomino has none
      yet) — untouched by Phase 2, this is genuine pre-existing per-host
      state asymmetry (not something to "fix"), unaffected by anything in
      this re-architecture; confirmed `settings/` directory structure
      itself is untouched (only `profiles/*/sync.json` and dots-local's
      `sync.tracked` config were ever in scope for any phase)
- [x] Host-specific hardware bits: chromaden's RTX 5080 CUDA flags fully
      migrated + live-eval-validated; laputa's Intel-GPU display +
      triomino's WSL2/VSCode-Remote shell-integration workaround
      structurally migrated + synthetic-eval-validated (real machines not
      directly reachable this session - see
      `memory-bank/host-migration-phase2.md` for required follow-up)
- [x] Two GitHub remotes (`origin`/`other`) — confirmed not our concern
      throughout; no phase touched git remote configuration, nothing in
      `dots`/`dots-local` reads or depends on remote names/URLs
- [x] All flake inputs unchanged: `nixpkgs`, `nixpkgs-quarto-pin`,
      `home-manager`, `nur`, `nixgl`, `niri`, `noctalia` (+ its
      `noctalia-qs` follows override — keep despite the eval warning),
      `noctalia-qs`, `snippets-ls`, `bookokrat`. Phase 9: re-confirmed via
      direct grep of `flake.nix`'s `inputs` block - all 10 inputs present,
      unchanged, in their original form.
- [x] All overlays unchanged in effect: `nur.overlays.default`,
      `niri.overlays.niri`, `noctalia-qs.overlays.default`,
      `externalOverlay` (snippets-ls/bookokrat/quarkdown/quarto+pandoc pin),
      conditional `tuneOverlay`. Phase 9: spot-checked package resolution
      directly - `pkgs.quarto` -> `"quarto"` (from the `nixpkgs-quarto-pin`
      override), `pkgs.pandoc` -> `"pandoc-cli"` (same pin),
      `pkgs.external.bookokrat` -> `"bookokrat"`,
      `pkgs.external.quarkdown` -> `"quarkdown"` - all resolve correctly
      on chromaden's real config.
- [x] `noctalia.homeModules.default` still imported in `baseModules`.
      Phase 9: re-confirmed via direct grep -
      `modules/features/niri-noctalia.nix:36` still imports both
      `inputs.niri.homeModules.niri` and
      `inputs.noctalia.homeModules.default` unconditionally.
- [x] New `dots-local` shell vars/init (`dotsLocal.shell.*`) — easy,
      low-ceremony path for session vars/aliases/initExtra, added in
      Phase 1 (`modules/core/dots-local-shell.nix`), flows through the
      existing gutter-eval pipeline to `.bashrc-nix` unchanged since then;
      not touched again in any later phase.
