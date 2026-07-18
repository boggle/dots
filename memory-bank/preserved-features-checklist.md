# Preserved-Features Checklist

Every one of these must keep working (or work strictly better) by the end of
the re-architecture. Check off once verified post-refactor (not just
"ported the code" — actually confirmed via eval and/or live test).

- [ ] Alien (native) package management — pacman/paru (cachyos), zypper
      (opensuse), tdnf (azurelinux3), **+ new apt (debian) support**
- [ ] AppImages — host-local (runtime dir) mode
- [ ] AppImages — shared (Nix store) mode
- [ ] Package tuning — global scope (overlay)
- [ ] Package tuning — local scope (PATH shadowing)
- [ ] Package tuning — wrapped scope (suffix binaries)
- [ ] Settings sync system (`sync.sh`, `settings/<host>/{home,root}/**`)
- [ ] niri-noctalia desktop (compositor, bar, keybindings, window rules,
      scratchpad/terminal-in-column helper scripts)
- [ ] llama-cpp CUDA/Zen5-tuned build (chromaden)
- [ ] butterfish AI shell integration
- [ ] ai-apps suite: grabcontext, opencode, github-copilot-cli, pi, graphify
- [ ] gui-apps suite (all currently-enabled apps per host)
- [ ] tui-apps suite
- [ ] pim-apps suite
- [ ] scanning suite
- [ ] sixel-tools suite (sixel-patched mpv, chafa/catimg/lsix, yt-dlp)
- [ ] cloud-tools suite (currently dormant — must become reachable, not just
      preserved as dead code)
- [ ] dev-tools feature (nixd, rust, python, haskell, entr, mkcert/caddy,
      quarto/typst/pandoc, etc.)
- [ ] git feature (delta, lazygit, gh/gh-dash, jj)
- [ ] clipboard (`clipin`/`clipout`/`clipfile`/`teeclip`) — Linux Wayland,
      Linux X11, WSL2, macOS
- [ ] opener (`o`) — Linux Wayland, Linux X11, WSL2, macOS
- [ ] viewer (`v`) — all file-type dispatch behaviors
- [ ] fonts feature
- [ ] sd-switch (systemd user + aggressive service restart on activation)
- [ ] nixon shell-bootstrap toggle (`NIXON=1/0`), now via
      `.bashrc-nix`/`.profile-nix` + loader stub
- [ ] Per-host settings sync data (chromaden, laputa — triomino has none yet)
- [ ] Host-specific hardware bits: chromaden's RTX 5080 CUDA flags, laputa's
      Intel-GPU display, triomino's WSL2/VSCode-Remote shell-integration
      workaround — all preserved, now parametrized via `dotsLocal` instead of
      hardcoded
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
