# Execution Plan

Status: **Phase 0 complete and committed** (`4c39074`; `9ae4fb8` follow-up).
**Phase 1 (`dots-local` schema) complete and committed** (`5fb54cb`).
**Phase 2 (composition layer) complete, committed, and LIVE-CHECKPOINTED**
(`ce481c7` in `dots`, `fded4bb` in `dots-local`) - chromaden's generation
312 (current) confirmed byte-identical to the build validated during this
phase. One bootstrapping snag hit and resolved: the previously-installed
`apply-dots` was still the old profile-based version until the first
switch to the renamed `default` output regenerated it (expected, one-time,
due to the rename - fixed by running `nh home switch ... -c default`
directly once). laputa/triomino need manual follow-up on their own
machines - see `host-migration-phase2.md`. **Phase 3 (alien package
unification + Debian support) complete and committed** (`b0e9c90`) -
eval/build-validated (no Debian hardware to live-test). Phase 4
(`mkAppSet` helper, migrate all suites) not yet started.

Note: a one-line typo fix (`dektopName` -> `desktopName`) was also made in
the *private* `~/dots-local/appimages.nix` repo as part of Phase 1 - that's
a separate git repo and is left **uncommitted** there for the user to
review/commit themselves.

Legend: `[ ]` not started · `[~]` in progress · `[x]` done · `(live)` = needs a
live `apply-dots` checkpoint on chromaden, not just `nix eval`/`nix build`.

Each phase = one or more small, eval-validated commits. Do not start a phase
until the previous one evaluates cleanly (`nix eval .#homeConfigurations.<x>`
at minimum; live-switch only at flagged checkpoints, per user preference).

**Standing operating procedure (see learnings.md 2026-07-18 "CRITICAL"
entry): `git add` any brand-new file immediately after creating it, before
treating any `nix eval`/`nix build` against it as real validation.** Local
flake evaluation only sees git-tracked/staged files - a new untracked file
is silently invisible, with no error. This will recur in every phase that
adds new files (Phase 1's schema.nix/template.nix, Phase 2's
composition.nix/composition-rules.nix, Phase 8's externalized scripts,
etc).

---

## Phase 0 — Memory bank + AGENTS.md + trivial bugfixes `(live)`
- [x] Create `memory-bank/` (this file and siblings)
- [x] Revise `AGENTS.md` to hook in the memory bank
- [x] Fix laputa.nix: `features.scanning` -> `suites.scanning`
- [x] **Bigger than expected**: laputa.nix's config had never successfully
      evaluated at all. Beyond the typo, fixed: (a) missing
      `suites.ai-apps.nix` import at the profile level — `priv/home.nix`
      unconditionally configures `suites.ai-apps.*` but the module was only
      imported per-host (chromaden/triomino), not at the profile level; now
      imported once in `profiles/priv/home.nix`, removed the now-redundant
      per-host imports; (b) laputa had no `programs.ssh` block at all, which
      a Home Manager assertion requires once `network.nix` sets
      `programs.ssh.extraConfig` — added one
      (`~/.ssh/id_github_laputa`, matching the established convention).
      Verified via `nix eval` against a temp `dots-local` copy with
      `host = "laputa"`/`"triomino"` — see `learnings.md` for the technique
      and full trail. All three hosts (chromaden/laputa/triomino) now
      confirmed to evaluate cleanly.
- [x] Fix header comments: chromaden.nix / triomino.nix said "Laputa Machine
      Configuration" (copy-paste artifact)
- [x] Migrate deprecated `programs.ssh.matchBlocks` -> `programs.ssh.settings`
      on chromaden.nix + triomino.nix while fixing laputa's missing block
      (PascalCase keys: `IdentityFile`/`AddKeysToAgent`)
- [x] Fix missing `gcc15`/`gcc15-libs` alien spec: relocated
      `cuda-llama`/`vulkan-llama`/`aocl-gcc`/`aocl-utils` out of
      `ai-apps.cachyos-packages.nix` into a properly-named
      `modules/features/llama-cpp.cachyos-packages.nix` (fixes the
      feature/suite location mismatch too), and added the missing
      `gcc15`/`gcc15-libs` entries as `pacman` packages (verified via web
      search: both are official Arch `extra` repo packages, not AUR, as of
      2026-06 — not `paru` as first guessed)
- [x] Clean up dead `niriPkg = if useAlienNiri then pkgs.niri else pkgs.niri`
      conditional in niri-noctalia.nix (was only ever referenced in the
      non-alien branch anyway; simplified to `niriPkg = pkgs.niri;`)
- [x] Fix `dots-local.nix` reading `$HOME/dots/sync-config.json` (dead path;
      real file is `$DOTS_LOCAL_DIR/sync-config.json`) - also fixed a second
      dead path in the same file (`$HOME/dots/modules/hosts/$host.nix` ->
      real location `profiles/<profile>/hosts/<host>.nix`)
- [x] De-duplicate the double `sync.sh` invocation per `apply-dots` run -
      removed the redundant explicit call from `scripts.nix`'s `apply-dots`
      (the `home.activation.syncUserConfigs` hook in `dots-local.nix`
      already runs sync.sh on every activation, including the one `nh home
      switch` triggers inside `apply-dots` itself)
- [x] Fix `~/.bashrc_core` (underscore) -> `~/.bashrc-core` (hyphen) typo in
      `nixon.nix`'s gatekeeper script (real file uses a hyphen; GTK/QT theme
      env vars were silently never sourced)
- [x] `pim-apps.nix`: `mkOption` -> `mkEnableOption` for consistency
- [x] `sd-switch.nix`: added a proper `enable` option (default `true`,
      preserving current always-on behavior for existing hosts; previously
      had no enable option at all, breaking module convention)
- [x] gui-apps.nix: removed dead `programs.librewolf` config block (kept
      native alien librewolf-bin, deleted the ~25-line unreachable HM config
      that was permanently disabled via a hardcoded `enable = false;`)
- [x] Validated: `nix eval` for chromaden (real dots-local), laputa and
      triomino (via temp dots-local copies with `host` swapped), and
      `priv-opt`; full `nix build` of `config.home.path` and
      `config.home.activationPackage` for chromaden (validates all
      `writeShellScriptBin` scripts' bash syntax + HM activation script)
- [x] **Live checkpoint done**: user ran `apply-dots` on chromaden - applied
      successfully.
- [x] **Post-checkpoint bug found + fixed**: user reported
      `update-alien-packages --action remove` wanted to remove `ghostty`
      (actively needed). Root-caused to a genuine, pre-existing orphan-
      detection bug (not user-config-specific): orphan status was only ever
      checked against *the same manager's* required list, so a package
      whose spec moved from one manager to another (ghostty: paru -> pacman
      once it hit the official repos) gets permanently stuck flagged as an
      orphan under the old manager forever, even though still genuinely
      required and installed. Fixed with a `get_all_required()`
      cross-manager union check (used both in orphan computation/
      reconciliation and as a defense-in-depth skip inside the removal
      prompt loop itself). Full details + two more bugs found while
      validating the fix (an `awk`-vs-`cat` trailing-newline concatenation
      bug in the fix itself, and a pre-existing `set -e`+`((counter++))`
      bug that silently aborted the removal flow after the first
      prompt) in `learnings.md`.
      **Also caught and fixed a process bug of my own**: the new
      `modules/features/llama-cpp.cachyos-packages.nix` file (added earlier
      in this phase) was git-untracked, making it invisible to every
      `nix eval`/`nix build` I'd run - meaning the `gcc15`/`gcc15-libs` fix
      was silently inactive (worse: `cuda-llama`/`vulkan-llama` also
      stopped resolving) until `git add`ed. See learnings.md's "CRITICAL"
      entry - now a standing procedure noted at the top of this file.
      Verified end-to-end against the live system's real
      `~/.local/share/dots/packages/` state after staging: dry-run shows
      "All packages in order" for both managers, removal flow correctly
      processes all orphan entries in one pass, and a real `update` action
      self-healed the stale `ghostty` orphan entry with no manual editing.
- [x] **Follow-up**: user asked about a second orphan false-alarm - `fzf`,
      flagged for removal from `pacman`. Investigated: no custom-build/tune
      config for `fzf` exists anywhere (it's plain-Nix, unconditional, in
      `modules/core/default.nix`); the native pacman `fzf` is a genuine
      orphan from dots's perspective (no spec references it) but two
      *other* native packages the user has installed outside of dots
      (`downgrade`, `fontpreview`) list it as `Required By` - removing it
      would likely fail outright (pacman refuses on unmet reverse-deps
      since the script uses `-Rns` without `--cascade`) or break those
      tools if forced. Different class of issue than `ghostty` (not a bug,
      an inherent limitation - dots can't know about reverse-deps from
      packages it doesn't manage). Added a lightweight
      `alienPackages.protectedPackages` option (listOf str) - names listed
      here are unioned into `get_all_required()` so they're never flagged
      as orphans/never offered for removal, regardless of alien-spec
      status. Set `protectedPackages = [ "fzf" ]` on chromaden.nix with a
      comment explaining why. Validated via a fake-`$HOME` sandbox test
      (copied real orphan-tracking state into a scratch dir, ran the built
      binary with `HOME` overridden) - confirmed `fzf` is now auto-skipped
      with a clear message instead of being prompted for removal.
      **Note**: requires a real `apply-dots` to materialize
      `~/.local/share/dots/packages/protected.txt` before it takes effect
      live - not yet applied as of this note (next live checkpoint will
      cover it).

## Phase 1 — `dots-local` schema `[x] DONE (uncommitted)`
- [x] Design `modules/dots-local/schema.nix` (lib.evalModules) - kept
      additive/backward-compatible (existing fields stay flat) rather than
      the fully-nested design originally sketched; see decisions.md
      2026-07-18 "dots-local schema: additive/backward-compatible"
- [x] Wire into `flake.nix`: evaluate dots-local against schema (stripping
      flake-introspection metadata attrs first - see learnings.md), pass
      `dotsLocal` as specialArg to all HM modules + the gutter-eval; also
      wired `dotsLocal.extraModules`/`extraOverlays` escape hatches in
      (appended, empty by default, no behavior change)
- [x] Migrated every `inputs.dots-local`/`local.X or default` read site to
      `dotsLocal.X`: flake.nix, alien-package-specs.nix, package-tuning.nix,
      tune-support.nix, alien-packages.nix, dots-local.nix, nixon.nix,
      appimages.nix, dev-tools.nix, git.nix, butterfish.nix,
      chromaden.nix, priv/home.nix - confirmed via grep, zero
      `inputs.dots-local` references remain in modules/profiles
- [x] Added `modules/core/dots-local-shell.nix` - the new low-ceremony
      `dotsLocal.shell.{sessionVariables,shellAliases,initExtra}` path,
      flows through the existing gutter-eval automatically via HM's normal
      cross-module merging
- [x] Bonus fixes enabled by the schema: removed the dead `graphical`
      legacy-alias fallback; removed the manual `graphicalBackend`
      validBackend/assertions block (schema's enum type now does this);
      unified the `march` default to "native" (was inconsistently "znver5"
      in package-tuning.nix only) and fixed the `-opt` profile build
      hardcoding `gcc.arch = "znver5"` regardless of `dotsLocal.march`;
      fixed `dev-tools.nix`'s hardcoded `/home/${username}` path to use
      `config.home.homeDirectory` instead; fixed a real typo in the live
      `dots-local/appimages.nix` (`dektopName` -> `desktopName`, tolaria's
      desktop entry was silently getting the wrong display name)
- [x] Fixed a real bug surfaced by the schema itself: `appimages.nix`'s
      `app.desktopName or name`/`app.categories or [...]` fallbacks broke
      once `dotsLocal.appimages` became schema-typed (always-present
      null/[] rather than sometimes-missing) - only caught by a full
      `nix build .../activationPackage`, not by a shallow `nix eval`; see
      learnings.md for the full trail and the general lesson about eval
      vs. build validation depth
- [ ] ~~Create `modules/dots-local/template.nix`~~ - deferred to Phase 2
      (nothing lost its home in Phase 1; see open-questions.md)
- Validation: `nix eval` for chromaden (real dots-local, both clean and
  uncommitted-change git states), laputa + triomino (temp dots-local
  copies), priv-opt, and the (still expectedly-broken, unrelated) `work`
  profile; full `nix build` of `config.home.path` +
  `config.home.activationPackage` for chromaden and laputa. **Not yet
  live-checkpointed** - awaiting the next `apply-dots` per user's usual
  validation cadence.

## Phase 2 — Composition layer (replaces profile hierarchy) `(live)` `[x] DONE (uncommitted)`
- [x] **Decision checkpoint resolved**: flake output naming confirmed by
      user -> `homeConfigurations.{default,default-opt}` (replacing
      `{priv,work,priv-opt,work-opt}`). `apply-dots priv`/`apply-dots
      priv-opt` -> `apply-dots`/`apply-dots opt`. `apply-dots`'s argument
      parsing, symlink logic (removed - no more profile directories to
      point at), and the `appimage-update` script's flake-output query
      (hardcoded to `default`, since localDir doesn't differ between
      variants) all updated in `modules/core/scripts.nix`.
- [x] `modules/composition-rules.nix` - small, explicit rule list:
      `compositor == "niri"` -> niri-noctalia + its terminal/renderDrmDevice
      defaults; `gpu == "nvidia"` -> llama-cpp + ai-apps.pi; `profile ==
      "work"` -> cloud-tools; `isWsl` -> opener/clipboard wsl backend +
      wsl-shell-integration + WAYLAND_DISPLAY/DIRENV_LOG_FORMAT. Both
      `when` and `set` are functions of `dotsLocal` (not just `when` -
      caught via eval error when `set` needed to read `d.machine.terminal`)
- [x] `modules/composition.nix` - the engine: always imports core +
      `contexts/common.nix` + a `contexts/<dotsLocal.profile>.nix` bundle
      (asserted to exist, with a clear error naming the available contexts
      if not) + universally-available feature/suite modules that used to
      require a per-host import (niri-noctalia, llama-cpp, butterfish,
      sd-switch, scanning, cloud-tools, wsl-shell-integration, the new
      power-toggle). Folds composition-rules.nix on top via a
      `deepMkDefault` helper (recursively wraps every LEAF of a rule's
      `set` attrset in `lib.mkDefault` - a single outer `mkDefault` on a
      nested attrset does NOT give correct per-option priority semantics)
- [x] Retired `profiles/common/home.nix` -> `modules/contexts/common.nix`,
      `profiles/priv/home.nix` -> `modules/contexts/priv.nix` (content
      unchanged, minus the per-host import logic), created
      `modules/contexts/work.nix` (previously had zero real content - a
      genuinely minimal, conservative starter). Deleted
      `profiles/priv/hosts/{chromaden,laputa,triomino}.nix` entirely -
      `profiles/<profile>/{appimages,sync.json}` deliberately LEFT ALONE
      (unrelated to the Nix composition change, still correctly keyed by
      `dotsLocal.profile` for the sync system and shared-appimages
      extension point)
- [x] New schema fields added: `compositor` (nullOr enum ["niri"]),
      `machine` submodule (`sshIdentityFile`, `terminal`,
      `renderDrmDevice`, `display` with eco/perf mode settings) -
      parametrizing exactly the host quirks that used to require a
      per-host file: SSH identity (now read generically in
      `features/network.nix`), power-toggle script (new generic
      `features/power-toggle.nix`, gated on `machine.display != null`),
      niri terminal/renderDrmDevice defaults (via composition-rules.nix)
- [x] Generalized triomino's VSCode-Remote-SSH + WSL shell-integration
      workaround into a real, reusable feature
      (`modules/features/wsl-shell-integration.nix`), auto-enabled by the
      `isWsl` composition rule - this was never actually triomino-specific
- [x] `cloud-tools` now imported universally in composition.nix (was
      defined but never imported anywhere); axis-defaulted on for
      `profile == "work"`
- [x] **Fully migrated + live-eval-validated: chromaden** (the one host
      this session has direct dots-local access to) - added
      `gpu`/`compositor`/`machine.*`/`extraModules` to the real
      `~/dots-local/flake.nix`, created `~/dots-local/host-chromaden.nix`
      for the genuinely bespoke bits (CUDA/llama.cpp cmakeFlags, SAXON_DIR/
      XEP_HOME, xdg portal preference, bluez/localsend, fzf protection).
      Every resolved config value spot-checked against the original
      chromaden.nix's intent and found identical (llama-cpp.enable,
      niri-noctalia terminal/renderDrmDevice, ai-apps.pi/opencode,
      gui-apps.chromium, scanning.enable, ssh IdentityFile, and the
      power-toggle.sh script's *exact byte-for-byte* generated content).
- [x] **laputa + triomino: structurally migrated and eval/build-validated
      via synthetic dots-local copies** (this session has no access to
      their real, separate dots-local repos) - see
      `memory-bank/host-migration-phase2.md` for the exact fields/files the
      user needs to add to each machine's own dots-local. Deferred rather
      than skipped, per the standing rule (architecture.md 1c) - this
      constitutes the "document what needs to go into dots-local" delivery
      for these two hosts, since they can't be migrated directly from here.
- [ ] ~~Repurpose `modules/distros/*`~~ - **rescoped to Phase 3** (it
      naturally belongs with the alien-package unification work, which
      already touches per-distro spec discovery; doing it here would be
      duplicated effort). Left as-is (still vestigial) for now.
- [x] Updated README.md (Quick Start, Architecture, Navigation Tips, Adding
      a New Host sections) and `.gitignore` (removed the now-dead
      convenience-symlink ignore patterns) to match; removed the stale
      `current-profile`/`host.nix`/`distro.nix` symlinks left over from the
      last real `apply-dots` run.
- Validation: `nix eval` + full `nix build .../activationPackage` for
  chromaden (real dots-local, both `default` and `default-opt` outputs)
  AND for laputa/triomino (synthetic dots-local copies matching the
  migration notes) - all pass, all spot-checked resolved values match
  original intent exactly. **Not yet live-checkpointed with a real
  `apply-dots` run** - flagged explicitly to the user given the command
  syntax change, awaiting confirmation before/alongside that live check.

## Phase 3 — Alien package unification + Debian support `[x] DONE`
- [x] Merged `alien-package-specs.nix` (flake-level) and `alien-packages.nix`
      (HM-level) discovery into one shared `modules/flake/alien-discovery.nix`
      function - both now call `collectAlienSpecs { dir; distro; }` instead
      of each independently implementing the same recursive directory walk
- [x] Added `apt` backend to `update-alien-packages` (all three call sites:
      `get_installed_packages` via `apt-mark showinstall`, the removal
      case statement via `apt-get remove -y`, the install case statement
      via `apt-get install -y`) - preserves the existing
      `get_all_required()` cross-manager orphan-safety fix from Phase 0
      automatically, since that logic doesn't hardcode manager names
- [x] Added `*.debian-packages.nix` convention; backfilled **conservatively**
      (matching the existing azurelinux3 precedent of official-repos-only):
      `network.debian-packages.nix` (nmap, rclone - deliberately excluded
      doggo/xh, not confirmed in Debian's official archive),
      `tui-apps.debian-packages.nix` (btop, lazygit - confirmed via
      packages.debian.org, imagemagick, graphviz, pandoc, pass, hledger -
      deliberately excluded zellij/yazi, confirmed via web search to only
      be reliably available through unofficial third-party repos like
      deb.griffo.io, not Debian's own archive)
- [x] Updated README.md/OVERVIEW.md's distro-backend tables to mention
      `debian -> apt`
- Validation: `nix eval` + full `nix build .../activationPackage` against
  a synthetic `distro = "debian"` dots-local copy (no real Debian hardware
  available) - confirmed the resolved `required/apt.txt` contains exactly
  the packages for currently-enabled toggles (btop/graphviz/imagemagick/
  lazygit/rclone), correctly excluding disabled ones. **Documented as
  structurally-ready-but-runtime-unverified** - flagged in
  `memory-bank/open-questions.md`, to be revisited once real Debian
  hardware exists. `modules/distros/*` repurposing (deferred from Phase 2)
  still not done - remains vestigial; low priority, revisit if it becomes
  actually useful rather than doing it preemptively.

## Phase 4 — `mkAppSet` helper, migrate all suites
- [ ] Implement `modules/core/lib.nix` helper
- [ ] Migrate gui-apps, tui-apps, pim-apps, scanning, sixel-tools,
      cloud-tools, network, dev-tools, ai-apps
- Validation: `nix eval` + diff `home.packages`/`alienPackages.enabledPackages`
  before/after per suite (must be identical)

## Phase 5 — Tuning defaults unification
- [ ] Single source of truth file (`modules/core/tune-defaults.nix`)
- [ ] `tune-support.nix` + `package-tuning.nix` both consume it
- [ ] `setup.sh` stops embedding a full copy
- Validation: `nix eval` + diff resolved flags per package before/after

## Phase 6 — Shell bootstrap: retarget hybrid file only (gutter-eval KEPT) `(live)`
- [ ] `nixon.nix` keeps writing `.bashrc-nix`/`.profile-nix` unchanged (pure
      HM output, already correctly separated — do not touch)
- [ ] `nixon.nix` writes the NIXON-gatekeeper hybrid script to
      `.bashrc-dots`/`.profile-dots` instead of `lib.mkForce`-ing the real
      `.bashrc`/`.profile`
- [ ] Idempotent, additive-only activation step (or `setup.sh` step) ensures
      real `~/.bashrc`/`~/.profile` source `.bashrc-dots`/`.profile-dots`
      (append-if-missing via sentinel comment; never overwrite/remove
      existing user content)
- [ ] Fix `~/.bashrc_core` (underscore) -> `~/.bashrc-core` (hyphen) typo so
      the GTK/QT theme env vars actually get sourced (can land in Phase 0
      too, independent bug)
- [ ] Remove hardcoded duplicate `bf` alias in the gatekeeper script (let it
      come from `butterfish.nix`'s real config instead)
- [ ] Do NOT touch the `noctalia-qs` input override in `flake.nix` — confirmed
      intentional despite the "non-existent input" eval warning
- Validation: **live checkpoint required** (shell bootstrap correctness is
  hard to verify via `nix eval` alone)

## Phase 7 — Script consolidation (`setup-*`) + shared bash lib `(live)`
- [ ] Rename install-llama-cpp/uninstall-llama-cpp -> `setup-llama-cpp
      {install|remove|update}`; same for pi, graphify
- [ ] Extract shared bash boilerplate (colors/header/gum-detection) into one
      file sourced by all scripts
- Validation: `--help`/dry-run per script; live install/remove test for at
  least llama-cpp (actively used)

## Phase 8 — Externalize large embedded scripts
- [ ] Move grabcontext (~800-line embedded Python in ai-apps.nix), viewer.nix
      bash (~360 lines), clipboard.nix bash (~140 lines), niri-noctalia
      helper scripts to real files, read via `builtins.readFile`
- Validation: `nix eval` + shellcheck/pyflakes where applicable + functional
  smoke test of `v`, `clipin`/`clipout`, `grabcontext`

## Phase 9 — Wire up dead options, close out, final docs
- [ ] `viewer.nix`'s 5 dead options actually gate script behavior
      (enableVideo, enableDirectoryTree, enableArchives, enableDataFormats,
      enableFzfPicker)
- [ ] `fonts.required` actually gets contributed to (e.g. by niri-noctalia)
- [ ] Update README.md/OVERVIEW.md/SYNC.md to match new architecture
- [ ] Finalize `preserved-features-checklist.md`, mark everything verified
- Validation: `(live)` final checkpoint

---

## Cross-cutting, not yet scheduled to a phase
- Shared platform/OS detection (`modules/core/platform.nix`) consolidating
  clipboard.nix + opener.nix's duplicated `backend` enum — natural fit
  inside Phase 2 (composition) since it's axis-driven, or as its own small
  slice right after. **Needs explicit slot** — add during Phase 2 planning.
- `psutils`/`t3` mislabeled-package flags from core tool review — pending
  user confirmation before any removal (see `open-questions.md`).

## Notes
- Phases 1->2 are the architectural core; do these right after Phase 0.
- Phases 3-9 are more independent/reorderable if priorities shift.
- `sync.sh`/`setup.sh` deeper improvements are explicitly deferred, except
  where a phase directly requires a small touch (e.g. Phase 1's template
  generation, Phase 5's tuning-table removal from the bootstrap template).
