# Preserved-Features Checklist

Used during the re-architecture (Phases 0-9) to make sure nothing
regressed while `dots` was being rewritten - every item below was
actually verified via `nix eval`/`nix build` and/or a live test, not just
"ported the code." All confirmed intact by Phase 9's close-out; kept here
as a compact historical record rather than the original verbose,
per-item write-up (see `decisions.md`/`plan.md` for anything that turned
up a real bug along the way - `ghostty` orphan detection, the SSH-
assertion bug, `sixel-tools.nix`'s `FONTCONFIG_FILE`, etc.).

- Alien (native) package management - pacman/paru (cachyos), zypper
  (opensuse), tdnf (azurelinux3), apt (debian), dnf5 (azurelinux4).
  Debian/Azure Linux 4 were structurally-ready-but-runtime-unverified at
  Phase 9's close; Debian now has real hardware and extended coverage
  (post-Phase-9 round 15).
- AppImages - both host-local (runtime dir) and shared (Nix store) modes.
- Package tuning - all 3 scopes (global/overlay, local/PATH-shadowing,
  wrapped/suffix-binary).
- Settings sync system (`sync.sh`, `settings/<host>/{home,root}/**`).
- niri-noctalia desktop, llama-cpp (CUDA/Zen5-tuned build), butterfish,
  ai-apps/gui-apps/tui-apps/pim-apps/scanning/sixel-tools/cloud-tools/
  dev-tools/git-tools suites, clipboard/opener/viewer, fonts (wiring
  correct, `enable` deliberately still off), sd-switch, the nixon
  shell-bootstrap toggle.
- Per-host settings sync data, the two GitHub remotes - confirmed
  genuinely out of scope, not this project's concern.
- Flake inputs/overlays and `noctalia.homeModules.default` - all
  reconfirmed present and resolving correctly. **Update 2026-07-19**:
  `nur`/`nixgl` later confirmed to have zero consumers anywhere and were
  commented out (not deleted) per explicit user decision - a deliberate,
  authorized exception to this checklist's original "must survive
  unchanged" scope, not a regression. See `decisions.md`.
- New `dots-local` shell vars/init (`dotsLocal.shell.*`).
- Host-specific hardware bits: chromaden's CUDA flags fully migrated and
  live-validated; laputa/triomino structurally migrated via synthetic
  `dots-local` copies (real machines out of reach this session - see
  `host-migration-phase2.md`, still the user's own follow-up).
