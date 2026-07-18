# Execution Plan

Status: **Phase 0 complete and committed** (`4c39074`, "Phase 0: memory bank
+ re-architecture bugfixes"; `9ae4fb8` follow-up). **Phase 1 (`dots-local`
schema) complete and committed** (`5fb54cb`, "Phase 1: formal dots-local
schema (lib.evalModules)"). Not yet live-checkpointed with `apply-dots`.
Phase 2 (composition layer) not yet started.

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

## Phase 2 — Composition layer (replaces profile hierarchy) `(live)`
- [ ] `modules/composition-rules.nix` (declarative, pure-data rule list)
- [ ] `modules/composition.nix` (engine: core always + rule folding via
      `lib.mkIf`/`lib.mkDefault`)
- [ ] Retire `profiles/common|priv|work/home.nix` and
      `profiles/*/hosts/*.nix`; port their logic into rules + dotsLocal data
- [ ] Parametrize currently-hardcoded host quirks (power-toggle display
      name/resolution, SSH identity file name, CUDA arch) into
      `dotsLocal.machine.*` fields
- [ ] Repurpose `modules/distros/*` as real per-distro metadata (feeds
      composition rules + alien-package layer) instead of dead registry
- [ ] Import `cloud-tools` universally (axis-defaulted) instead of leaving it
      dormant/unimported
- [ ] **Standing rule (see architecture.md 1c)**: for every host file
      retired (chromaden/laputa/triomino), document its `dots-local`
      equivalent (e.g. `docs/dots-local-guide.md` or expanded
      `modules/dots-local/template.nix` examples) in the same change that
      deletes the old file — covers power-toggle display config, SSH
      identity filenames, CUDA arch/cmake flags, per-host AppImage lists
- [ ] **Decision checkpoint**: flake output naming
      (`homeConfigurations.priv/work/*-opt` -> ?) — confirm with user before
      changing `apply-dots` muscle memory
- [ ] Collapse `flake.nix`'s `profileDefinitions` + `mkProfile{profileName}`
      accordingly
- Validation: `nix eval` against chromaden's (ported) dotsLocal, then live
  checkpoint

## Phase 3 — Alien package unification + Debian support
- [ ] Merge `alien-package-specs.nix` (flake-level) and `alien-packages.nix`
      (HM-level) discovery into one shared function
- [ ] Add `apt` backend to `update-alien-packages`
- [ ] Add `*.debian-packages.nix` convention; backfill CLI-relevant specs
      (git, network, dev-tools, clipboard/opener essentials, tui-apps CLI
      subset)
- [ ] Document Debian support as structurally-ready-but-runtime-unverified
- Validation: `nix eval` only (no Debian hardware available yet)

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
