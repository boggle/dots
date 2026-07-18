# Preserved-Features Checklist

Every one of these must keep working (or work strictly better) by the end of
the re-architecture. Check off once verified post-refactor (not just
"ported the code" — actually confirmed via eval and/or live test).

- [ ] Alien (native) package management — pacman/paru (cachyos), zypper
      (opensuse), tdnf (azurelinux3), **+ new apt (debian) support**
      (Phase 3, not yet done)
- [x] AppImages — host-local (runtime dir) mode (eval/build-verified for
      chromaden real + laputa synthetic, all 5 laputa wrappers resolve)
- [ ] AppImages — shared (Nix store) mode (still no manifest.nix anywhere,
      unchanged from before - untested either way, same as pre-refactor)
- [x] Package tuning — global scope (overlay) (chromaden's
      ripgrep/fd/noctalia-qs/ghostty/tesseract still resolve via
      `tunePackagesByContext.priv` in flake.nix)
- [x] Package tuning — local scope (PATH shadowing) (mechanism untouched by
      Phase 2, still imported via contexts/priv.nix -> core -> tune-support.nix)
- [x] Package tuning — wrapped scope (suffix binaries) (same as above)
- [ ] Settings sync system (`sync.sh`, `settings/<host>/{home,root}/**`) -
      untouched by Phase 2 (profiles/*/sync.json deliberately left alone),
      not independently re-verified this phase
- [x] niri-noctalia desktop (chromaden: enable/terminal/renderDrmDevice all
      confirmed resolving identically via composition-rules.nix; full
      in-session behavior not live-tested, only config resolution)
- [x] llama-cpp CUDA/Zen5-tuned build (chromaden - cmakeFlags override via
      dots-local/host-chromaden.nix confirmed identical to the original)
- [x] butterfish AI shell integration (chromaden: features.butterfish.enable
      confirmed true via host-chromaden.nix)
- [x] ai-apps suite: grabcontext, opencode, github-copilot-cli, pi, graphify
      (chromaden + triomino-synthetic both confirmed resolving correctly,
      including triomino's piPackages now inheriting rather than duplicating)
- [x] gui-apps suite (chromaden's extras - chromium/libreoffice/gimp/
      inkscape/vlc/flameshot - confirmed via host-chromaden.nix)
- [ ] tui-apps suite (triomino-synthetic's aerc/deltachat/pandoc/typst=false
      override confirmed resolving; not otherwise re-verified)
- [ ] pim-apps suite (untouched by Phase 2, not independently re-verified)
- [x] scanning suite (chromaden real + laputa synthetic both confirmed
      `enable = true` with all 3 sub-tools)
- [ ] sixel-tools suite (untouched by Phase 2, not independently re-verified)
- [x] cloud-tools suite — now imported universally in composition.nix and
      axis-defaulted on for `profile == "work"` (no longer dormant/unreachable)
- [ ] dev-tools feature (untouched by Phase 2 beyond the Phase 1
      homeDirectory fix, not independently re-verified this phase)
- [ ] git feature (untouched by Phase 2, not independently re-verified)
- [x] clipboard (`clipin`/`clipout`/`clipfile`/`teeclip`) — wsl backend
      confirmed auto-selected via the `isWsl` composition rule for
      triomino-synthetic; wayland/x11/macos paths untouched, unaffected
- [x] opener (`o`) — same as clipboard above
- [ ] viewer (`v`) — untouched by Phase 2, not independently re-verified
- [ ] fonts feature (untouched by Phase 2, not independently re-verified)
- [x] sd-switch (now universally imported/enabled by default=true, was
      previously per-host-import-only; confirmed still active)
- [ ] nixon shell-bootstrap toggle (`NIXON=1/0`) — untouched by Phase 2,
      still pending its own dedicated phase (6)
- [ ] Per-host settings sync data (chromaden, laputa — triomino has none yet)
      — untouched by Phase 2
- [x] Host-specific hardware bits: chromaden's RTX 5080 CUDA flags fully
      migrated + live-eval-validated; laputa's Intel-GPU display +
      triomino's WSL2/VSCode-Remote shell-integration workaround
      structurally migrated + synthetic-eval-validated (real machines not
      directly reachable this session - see
      `memory-bank/host-migration-phase2.md` for required follow-up)
- [ ] Two GitHub remotes (`origin`/`other`) — not our concern to reconcile,
      just don't accidentally break assumptions either remote relies on
- [ ] All flake inputs unchanged: `nixpkgs`, `nixpkgs-quarto-pin`,
      `home-manager`, `nur`, `nixgl`, `niri`, `noctalia` (+ its
      `noctalia-qs` follows override — keep despite the eval warning),
      `noctalia-qs`, `snippets-ls`, `bookokrat`
- [ ] All overlays unchanged in effect: `nur.overlays.default`,
      `niri.overlays.niri`, `noctalia-qs.overlays.default`,
      `externalOverlay` (snippets-ls/bookokrat/quarkdown/quarto+pandoc pin),
      conditional `tuneOverlay` — verify via spot-check package resolution
      (`quarto`, `pandoc`, `bookokrat`, `external.quarkdown`) before/after
      Phase 1/2
- [ ] `noctalia.homeModules.default` still imported in `baseModules`
- [ ] New `dots-local` shell vars/init (`dotsLocal.shell.*`) — easy,
      low-ceremony path for session vars/aliases/initExtra, verified to
      actually reach `.bashrc-nix` via the existing gutter-eval pipeline
