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
unification + Debian support, + Azure Linux 4/dnf5 addendum) complete and
committed** (`b0e9c90`, `04a1bdd`) - eval/build-validated (no Debian/Azure
Linux hardware to live-test). **Phase 4 (`mkAppSet` helper, migrate all
suites) complete and committed** (`157a691`) - eval/build-validated,
byte-identical package-list regression check passed. **Phase 5 (tuning
defaults unification) complete and committed** (`b80b2c3`) -
byte-identical resolved flags + identical derivation hash confirmed.
**Phase 6 (shell bootstrap retarget) complete, committed, and
LIVE-CHECKPOINTED** (`01f8568`, fix in `8b0cabc`) - first live attempt hit
a real bug (HM's built-in `programs.bash` module reclaiming `.bashrc`/
`.profile` once `nixon.nix`'s override was removed rather than disabled),
found and fixed, retry succeeded - generation 316 confirmed matching the
validated build exactly. **Phase 7 (script consolidation + shared bash
lib) complete and LIVE-CHECKPOINTED** - `setup-llama-cpp`/`setup-pi`/
`setup-graphify` all live-tested on the real system (safe decline-path
tests + a real idempotent `setup-graphify install` run). **Phase 8 (externalize large embedded scripts)
complete** - `grabcontext` (Python), `viewer.nix`'s `v` script,
`clipboard.nix`, and all 4 niri-noctalia helper scripts done,
byte-identical/functionally-equivalent output verified for all of them,
plus a `shellcheck` pass over every extracted file.

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

### Phase 3 addendum — Azure Linux 4 (`dnf5`) support
- [x] Added `dnf5` as a new alien-package manager backend (Azure Linux 4.0
      replaced `tdnf` with `dnf5` - confirmed via Microsoft's own "what's
      new" docs; kept as a genuinely separate manager rather than reusing
      `tdnf`, even though Azure Linux ships compatibility symlinks, per
      Microsoft's own migration guidance)
- [x] Added `azurelinux4` distro value + `*.azurelinux4-packages.nix` specs
      mirroring `azurelinux3`'s exact existing package set (marksman, nmap,
      gh, azure-cli, graphviz) - same conservative confidence level,
      deliberately not extended further like Debian's specs (Azure Linux 4
      is an intentionally lean/curated cloud distro, not general-purpose)
- [x] **Found and fixed a real, pre-existing Phase 2 gap** while testing
      with `profile = "work"` for the first time: `composition-rules.nix`
      references `features.opener`/`features.clipboard` (via the `isWsl`
      rule) and `suites.ai-apps` (via the `gpu == "nvidia"` rule), but
      those modules were only imported by `contexts/priv.nix`, not
      universally - `lib.mkIf false` still requires the option to be
      *declared* somewhere. Moved `opener.nix`/`clipboard.nix`/`ai-apps.nix`
      to `composition.nix`'s universal imports (matching the existing
      niri-noctalia/llama-cpp/cloud-tools pattern); their enable/config
      assignments stay in `contexts/priv.nix`. Re-verified chromaden's
      resolved config unaffected (spot-checked ai-apps.pi/opencode,
      opener/clipboard enable+backend - all identical).
- Validation: synthetic `distro = "azurelinux4"`, `profile = "work"`,
  `isWsl = false` dots-local copy - full `nix build` succeeds; confirmed
  `required/dnf5.txt` resolves to exactly `azure-cli`/`gh`/`nmap` once
  those toggles are explicitly enabled (empty otherwise, correctly -
  `cloud-tools.enable` only makes the suite reachable, doesn't turn on
  individual tools). Re-validated chromaden (real) and laputa (synthetic)
  still build correctly after the opener/clipboard/ai-apps import move.

## Phase 4 — `mkAppSet` helper, migrate all suites `[x] DONE`
- [x] Implemented `modules/core/lib.nix`'s `mkAppSet { alien; apps; }`
      helper - takes `apps.<name> = { enable; pkg; alienName ? name; }`,
      returns `{ packages; alienEnabled; }`. `alienName` handles the cases
      where the alien-spec key differs from the toggle name (e.g.
      gui-apps.nix's `newsfeed` -> "newsflash", `libreoffice` ->
      "libreoffice-fresh"; cloud-tools.nix's `github`/`azure` -> "gh"/
      "azure-cli")
- [x] Migrated all 9 target files: gui-apps.nix (26 -> the biggest win,
      eliminated ~70 lines of repeated triples), tui-apps.nix (18),
      pim-apps.nix (6), scanning.nix (3), sixel-tools.nix (4, `mpv`
      deliberately excluded - handled separately via `programs.mpv` with a
      custom sixel-enabled build, never alien-managed), cloud-tools.nix
      (3), network.nix (4), dev-tools.nix (3 of its ~20 packages - only
      marksman/mkcert/caddy are alien-managed, the rest are plain
      always-Nix entries left untouched), ai-apps.nix (3: grabcontext/
      opencode/copilot - left the ~800-line embedded Python script and the
      pi/graphify imperative installers alone, that's Phase 8's job)
- Validation: comprehensive before/after diff of the FULL resolved
  `config.home.packages` (all ~120 packages across every suite/feature,
  not just the 9 touched) and `config.alienPackages.enabledPackages`
  (captured via `git stash`/`git stash pop` around a single `nix eval` each
  side) - **byte-for-byte identical** both times. Also: full `nix build
  .../activationPackage` for chromaden (real) and a re-check of the
  laputa/work+azurelinux4 synthetic configs from Phase 2/3/addendum - all
  still resolve correctly after the ai-apps.nix/network.nix/etc changes.

## Phase 5 — Tuning defaults unification `[x] DONE`
- [x] Created `modules/core/tune-defaults.nix` (pure `{ march }: {...}`
      function) as the single source of truth - kept the fuller
      (tune-support.nix) table as canonical, since it already had
      go/haskell/zig and `-ffast-math` in c/c++ fast mode, which
      package-tuning.nix's copy was missing
- [x] Both `tune-support.nix` and `package-tuning.nix` now import it;
      also unified `package-tuning.nix`'s `detectLang` to match
      tune-support.nix's fuller version (was only checking `cargoDeps`,
      now also `goPackagePath`/`isHaskellPackage`)
- [x] `setup.sh` no longer embeds a full copy of the tuning table in the
      generated `dots-local/flake.nix` template - just a commented
      override example, with a note that defaults already come from
      `dots` itself
- [x] **Found and fixed a real, unrelated bug while touching setup.sh**:
      the bootstrap `nix run home-manager -- switch --flake .#"${PROFILE}"`
      line still referenced the old profile-named flake output (broken
      since Phase 2's rename to `default`/`default-opt`) - fixed to
      `--flake .#default`, kept `${PROFILE}` for what it's actually still
      used for (dots-local's `profile` field / context selection, git
      commit message)
- Validation: **empirically discovered** that chromaden's real
  `dots-local` already sets an explicit `tune.flags.c.fast` override
  (`-Ofast ... -ffast-math`), which fully determines the value regardless
  of either module's built-in default table - meaning the specific
  table drift (c/c++ fast mode `-ffast-math`, go/haskell entirely) never
  actually affected chromaden's live config either before or after this
  phase. Verified via before/after `nix eval` diff of resolved
  `RUSTFLAGS`/`NIX_CFLAGS_COMPILE` for every currently-tuned package
  (ripgrep, fd, ghostty, tesseract, noctalia-qs) - byte-identical. Full
  `nix build .../activationPackage` produced the **exact same store path**
  as Phase 4's build, confirming zero derivation-level change.

## Phase 6 — Shell bootstrap: retarget hybrid file only (gutter-eval KEPT) `(live)` `[x] DONE, LIVE-CHECKPOINTED`
- [x] `nixon.nix` keeps writing `.bashrc-nix`/`.profile-nix` unchanged (pure
      HM output, already correctly separated — untouched)
- [x] `nixon.nix` now writes the NIXON-gatekeeper hybrid script to
      `.bashrc-dots`/`.profile-dots` instead of `lib.mkForce`-ing the real
      `.bashrc`/`.profile`
- [x] Idempotent, additive-only `home.activation.ensureDotsShellHook` step
      ensures real `~/.bashrc`/`~/.profile` source `.bashrc-dots`/
      `.profile-dots` (append-if-missing via a sentinel comment; never
      overwrites/removes existing user content) - creates the file fresh
      if it doesn't exist yet (first-run bootstrap)
- [x] Fixed `~/.bashrc_core` -> `~/.bashrc-core` typo - done earlier in
      Phase 0
- [x] Removed the hardcoded duplicate `bf` alias in the gatekeeper script -
      it's already set correctly by `butterfish.nix`'s
      `programs.bash.shellAliases.bf` (option-driven, respects
      dots-local's endpoint/model), which flows through `.bashrc-nix` via
      the gutter eval
- [x] Did NOT touch the `noctalia-qs` input override - confirmed
      intentional, untouched
- Validation: full `nix eval`/`nix build` for chromaden; **isolated
  sandbox testing of the activation-hook bash logic itself** (not the
  full activation script) against a fake `$HOME` - verified: (a) existing
  `.bashrc`/`.profile` content is fully preserved, source line correctly
  appended; (b) running it 3x more produces zero duplication (properly
  idempotent via the sentinel-comment grep check); (c) a from-scratch
  (no pre-existing file) `$HOME` gets the file created fresh. **What
  could NOT be verified without a real switch**: whether Home Manager
  cleanly unlinks the *old*, previously-force-owned `.bashrc`/`.profile`
  symlinks during the actual generation transition from a pre-Phase-6
  generation - this is standard HM behavior for any removed `home.file`
  declaration, but the isolated bash-logic tests above can't simulate an
  actual old-generation-to-new-generation transition. **Live checkpoint
  still required and explicitly flagged to the user before running
  `apply-dots`** - recommend opening a fresh terminal after switching to
  confirm shell startup still works before relying on it, given
  `home-manager generations` rollback remains available as a safety net
  if something goes wrong (would hit HM's normal file-collision handling,
  not silent data loss, since the target would no longer be a bare
  symlink after this change).

### First live attempt FAILED - root cause found and fixed
User ran `apply-dots`; activation failed with:
`/home/pc0w/.bashrc: line 429: Permission denied`. Root cause: removing
`nixon.nix`'s `home.file.".bashrc"`/`".profile"` declarations (rather than
disabling them) let Home Manager's OWN **built-in** `programs.bash` module
(enabled via `programs.bash.enable = true` in flake.nix, independent of
nixon.nix) reclaim those two paths and try to symlink them into the
read-only Nix store again - so by the time `ensureDotsShellHook`'s
`>> $HOME/.bashrc` ran, `.bashrc` was (again) a symlink into
`/nix/store`, and appending to a symlinked read-only target failed with
EACCES. The isolated sandbox tests from before couldn't have caught this
because they never had `programs.bash`'s own competing declaration in
scope at all - they tested the hook's logic in isolation, not the
interaction with HM's bash module.

**Fix**: explicitly `home.file.".bashrc".enable = lib.mkForce false;` /
`.profile` likewise, instead of just omitting the declaration - tells HM
to skip materializing these paths entirely, regardless of what
`programs.bash`'s own module logic wants to write there. Verified by
building the actual `home-manager-files` derivation and confirming
`.bashrc`/`.profile` are genuinely absent from its output (only
`.bashrc-dots`/`.bashrc-nix`/`.profile-dots`/`.profile-nix` remain), and
that the only remaining references to these two paths anywhere in the
generated `activate` script are the hook's own lines.

**Live system status after the failed attempt**: NOT broken - activation
failed at the hook step, after HM's own file-linking had already
succeeded, so `~/.bashrc`/`~/.profile` still resolved to valid (HM's
plain, non-nixon) content the whole time. Confirmed via `readlink -f`
before applying the fix.

### Retry LIVE-CHECKPOINTED SUCCESSFULLY (`8b0cabc`)
User re-ran `apply-dots` with the fix - succeeded. Generation 316 (current)
confirmed to match byte-for-byte the store path built and validated before
the retry. `~/.bashrc` is now a genuine real file (not a symlink)
containing exactly the expected sentinel comment + `.bashrc-dots` source
line; `~/.bashrc-dots` correctly symlinked into the new generation's
`home-manager-files`. **Phase 6 fully complete.**

## Phase 7 — Script consolidation (`setup-*`) + shared bash lib `(live)` `[x] DONE, LIVE-CHECKPOINTED`
- [x] Created `modules/core/scripts/common.sh` - a real, standalone,
      shellcheck-able bash file (not a Nix string) with the shared colors/
      `print_header`/`print_section`/`print_error`/`log_*`/gum-detection
      boilerplate that was previously copy-pasted independently across 5
      places: `apply-dots`, `update-dots`, `appimage-update` (all 3 in
      `scripts.nix`), `dots-local.nix`'s activation script, and
      `alien-packages.nix`'s `update-alien-packages`. Each now does
      `source` with a Nix path interpolation (embeds the file's store
      path at build time) instead of redefining it. Minor cosmetic
      side effect: 2 scripts had slightly different color codes for the
      same concept (e.g. `print_header` border-foreground 62 vs 69,
      `print_section` foreground 51 vs 99) - now unified to one look,
      not a functional change.
- [x] Consolidated `install-llama-cpp`/`uninstall-llama-cpp` ->
      `setup-llama-cpp {install|remove|update}` (`update` = force
      rebuild without the exists-already prompt, matching the old
      `install -f` behavior)
- [x] Consolidated `install-pi`/`uninstall-pi` -> `setup-pi
      {install|remove|update}` (`update` identical to `install` - the
      original always did a clean reinstall anyway, no separate "lighter"
      update path existed to preserve)
- [x] Consolidated `install-graphify`/`uninstall-graphify` ->
      `setup-graphify {install|remove|update}` (`update` = force git pull
      + venv reinstall)
- Validation: full `nix eval`/`nix build`; ran `--help` and an
  unknown-action error path for all 3 new `setup-*` scripts (correct
  usage text + exit 1); **live-tested all 3 on the real system**: `setup-
  llama-cpp remove`/`setup-pi remove`/`setup-graphify remove` each
  correctly prompted and did nothing when declined (existing installs
  fully intact after), and `setup-graphify install` was run for real
  (idempotent - only clones/creates venv if missing) confirming end-to-end
  correctness without touching the expensive llama.cpp/pi builds. Also
  ran `apply-dots -- --dry` and `update-alien-packages --dry-run` for
  real, confirming the shared common.sh sourcing works correctly at
  runtime (colors/headers render correctly) for the already-Phase-7-
  touched scripts too. Comprehensive before/after package-list diff
  (same `git stash`/`pop` technique as Phase 4) confirms the *only*
  change across the whole config is the 6 old scripts -> 3 new ones -
  nothing else shifted.

## Phase 8 — Externalize large embedded scripts `[x] DONE`
- [x] `grabcontext` (~800-line embedded Python in ai-apps.nix) -> real file
      `modules/suites/ai-apps/grabcontext.py`, read via `builtins.readFile`.
      Straight extraction (no Nix interpolations in the body) - verified
      byte-identical output, same derivation hash as before extraction.
- [x] `viewer.nix`'s `v` script (~290-line embedded bash) -> real file
      `modules/features/viewer/v.sh`. Unlike grabcontext, this script DOES
      reference genuine Nix-evaluated values (`${pkgs.bat}/bin/bat`,
      `${imageViewer}`, `${pdfViewer}`, `${videoViewer}`, etc. - the latter
      three themselves being conditional expressions, not just package
      paths). Handled with a small Nix-level preamble (10 lines: resolves
      each into a plain shell variable, e.g. `BAT_BIN="${pkgs.bat}/bin/bat"`)
      prepended via string concatenation to `builtins.readFile ./viewer/v.sh`
      - the static file itself references only the shell variables
      (`$BAT_BIN`, `$IMAGE_VIEWER`, etc.), no Nix syntax at all. Also found
      and fixed one incidental issue while extracting: a `''${file##*.}`
      Nix-string escape (needed inside the old embedded Nix string to
      prevent Nix from parsing the bash parameter expansion as
      interpolation) had to be unescaped to plain `${file##*.}` now that
      it lives in a real standalone bash file.
      Validated: `bash -n` syntax check; built both old (pre-extraction,
      via `git stash`) and new derivations directly via their `.drv` paths
      and diffed `bin/v` - the only differences are the expected
      inlined-store-path vs. shell-variable substitutions, with matching
      resolved store paths on both sides (e.g. same `bat-0.26.1`,
      `chafa-1.18.2-bin`, `mpv-with-scripts-0.41.0` hashes appear in both).
      Ran the new script for real: `--help`, and functional smoke tests of
      the JSON (`jq`) and CSV (`column`) code paths - both produced correct
      output. Full `nix build .../activationPackage` for chromaden (real
      dots-local) also passes cleanly after this change.
- [x] `clipboard.nix` bash (~130 lines) -> real file
      `modules/features/clipboard/clipboard.sh`. Also has real Nix
      interpolations (`${sed}`/`${pkgs.perl}`/`${backend}`, plus the
      backend-selected `copyCmdBase`/`pasteCmdBase` commands). The wsl
      paste command is the interesting case: `powershell.exe -NoProfile
      -Command "Get-Clipboard -Raw"` has an embedded, internally-quoted
      argument - naively storing it as a single shell-variable string and
      unquoted-expanding it would incorrectly word-split "Get-Clipboard"
      and "-Raw" into two separate argv entries (the quotes become inert
      data once already inside a variable's value - bash doesn't re-parse
      them). Fixed by using real bash ARRAYS instead of strings
      (`COPY_CMD=(...)`, generated from Nix as
      `copyCmdArray`/`pasteCmdArray` - Nix-level lists of individually
      double-quoted array-literal elements), referenced as
      `"${COPY_CMD[@]}"` - preserves argument boundaries exactly, more
      robust than the original approach (which only worked because Nix
      string interpolation happens before bash ever parses the script,
      equivalent to an implicit one-time `eval`).
      Validated: eval'd the resolved array text for all 4 backends
      directly (wayland/x11/wsl/macos) - correct argv boundaries in every
      case, including the tricky wsl one; built the real `.bashrc-nix`
      derivation before/after via `git stash` and diffed - only
      differences are the expected inlined-path-vs-variable substitutions
      (matching store paths on both sides) plus cosmetic indentation from
      the string-concatenation join point; ran a full functional test
      harness (fake COPY_CMD/PASTE_CMD receivers) confirming argv
      splitting is correct for the wsl case, default single-trailing-
      newline trim behavior, `--strip` ANSI stripping, and `clipfile`
      against a real file - all produced correct output. Full `nix build
      .../activationPackage` for chromaden (real dots-local, `wayland`
      backend) also passes cleanly.
- [x] niri-noctalia's 4 embedded helper scripts (terminal-in-current-column,
      terminal-scratchpad-toggle, start-xwayland-satellite, wait-for-x11)
      -> real files under `modules/features/niri-noctalia/`.
      terminal-in-current-column/terminal-scratchpad-toggle needed no
      variable renaming at all - their existing top-of-script local var
      assignments (`term=`, `appid=`, `py=`, `zellij=`, etc) were already
      exactly the natural preamble/body split point, so the preamble is
      just those assignment lines moved into the Nix wrapper unchanged and
      the extracted file is 100% identical to the original body.
      start-xwayland-satellite/wait-for-x11 needed real substitution
      (`${pkgs.xwayland-satellite}/bin/...` -> `$XWAYLAND_SATELLITE_BIN`,
      `${pkgs.xlsclients}/bin/...` -> `$XLSCLIENTS_BIN`) since those
      packages are invoked mid-script, not just assigned at the top.
      Validated: built all 4 old (pre-extraction, via `git stash`) and new
      derivations directly via `.drv` paths and diffed - whitespace-
      normalized diffs are byte-identical for the first two, and show only
      the expected variable substitutions (matching store paths) for the
      latter two; `bash -n` syntax-checked all 4; functional smoke test of
      `wait-for-x11` against a real unix socket (correctly waits, sets
      DISPLAY, execs the passed command).
- [x] Ran a `shellcheck -s bash` pass over every Phase 8 extracted file
      (`v.sh`, `clipboard.sh`, all 4 niri-noctalia scripts) - only
      pre-existing, minor style nits surfaced (unquoted `$size` in a couple
      of `numfmt` calls, `read` without `-r`, `local x=$(cmd)` masking
      return values, and expected `SC2154`/"referenced but not assigned"
      false positives for the niri-noctalia files since shellcheck can't
      see the Nix-side preamble that assigns those variables when checking
      the fragment in isolation) - none introduced by the extraction
      itself, left as-is (out of scope for Phase 8; Phase 8 is about
      externalizing scripts unchanged in behavior, not a general lint
      cleanup pass).
- Updated `memory-bank/preserved-features-checklist.md`'s clipboard/opener/
  viewer/niri-noctalia entries to reflect Phase 8 re-verification.
- Validation: `nix eval` + full `nix build .../activationPackage` for
  chromaden (`default` profile) after each extraction; direct `.drv`-path
  builds of every specific changed package/file (old vs. new) diffed
  byte-for-byte (or whitespace-normalized) where feasible; functional smoke
  tests of the resulting scripts/binaries (including a fake-receiver
  harness for clipboard.nix's array-based commands, and a real-socket test
  for wait-for-x11); a final `shellcheck` pass over all extracted files.
  **Phase 8 fully complete.**

## Phase 9 — Wire up dead options, close out, final docs `[~] IN PROGRESS`
- [x] `viewer.nix`'s 5 dead options actually gate script behavior
      (enableVideo, enableDirectoryTree, enableArchives, enableDataFormats,
      enableFzfPicker). Each option now flows through as a shell variable
      (`ENABLE_VIDEO`/`ENABLE_DIRECTORY_TREE`/`ENABLE_ARCHIVES`/
      `ENABLE_DATA_FORMATS`/`ENABLE_FZF_PICKER`, via
      `lib.boolToString cfg.<opt>` in the Nix preamble) and gates the
      corresponding branch in `v.sh`: disabling `enableVideo` shows
      metadata instead of attempting mpv playback (matching the existing
      continuous-mode fallback, just always rather than conditionally);
      disabling `enableDirectoryTree` drops `lsd`'s `--tree` flag (flat
      listing instead); disabling `enableArchives` falls back to plain
      `bat` for zip/tar/7z/rar instead of listing contents; disabling
      `enableDataFormats` falls back to plain `bat` for csv/json/yaml
      instead of `column`/`jq`/forced-yaml-syntax; disabling
      `enableFzfPicker` skips straight to a clear error (rather than
      attempting fzf) when `v` is called with no arguments.
      Validated: full `nix build .../activationPackage` for chromaden
      (default/enabled config); built a second, all-disabled synthetic
      variant via direct Nix eval + `.drv` build and ran it against real
      test files for every gate (json/csv/yaml pretty-print off -> raw
      `bat` output confirmed; directory tree off -> flat listing
      confirmed; zip archive off -> raw bytes through `bat` confirmed;
      video off, both continuous AND single-file/pager mode -> metadata
      shown, playback never attempted, confirmed); fzf-picker-off with no
      args -> correct error message + exit 1, confirmed.
- [x] `fonts.required` actually gets contributed to - `niri-noctalia.nix`
      now sets `features.fonts.required = [ pkgs.inter ];` (Noctalia's UI
      wants "Inter" per the existing but previously-dead `uiFont` binding;
      `terminalFont`/"IosevkaTerm NFM" needs no extra contribution since
      it's already covered by `features.fonts.base`'s default
      `nerd-fonts.iosevka-term`). Also moved `modules/features/fonts.nix`
      to `composition.nix`'s universal imports (same fix pattern as the
      Phase 3 opener/clipboard/ai-apps case - `niri-noctalia.nix` is
      itself universal, so `features.fonts.required` must be a declared
      option regardless of which context is active, not just in
      `contexts/priv.nix`).
      **Found a bigger, pre-existing (not a regression from any phase of
      this re-architecture) issue while doing this**: `features.fonts.enable`
      has never been set to `true` anywhere, on any host, confirmed via
      `git log -p` on the pre-Phase-2 `profiles/priv/home.nix` history -
      the entire fonts module has always been dormant. Chromaden's fonts
      "just work" today only by accident, via a native pacman package the
      user installed directly (`ttf-iosevkaterm-nerd`, `Install Reason:
      Explicitly installed`) plus `yazi`/`goverlay`'s own hard pacman
      dependency on some nerd font. Full details and the resulting user
      decision needed (leave off vs. turn on) logged in
      `open-questions.md` - **deliberately did NOT flip
      `features.fonts.enable` myself**, since that would be a new,
      visible, live-affecting default well beyond the literal "wire up
      required" scope of this phase.
      Validated: `nix eval` of `config.features.fonts.required` resolves
      to `[ inter-4.1 ]` on chromaden (real) and a synthetic
      `profile = "work"` + `compositor = "niri"` config, and correctly to
      `[]` on a synthetic config with niri-noctalia disabled; full
      `nix build .../activationPackage` passes for all three (chromaden,
      synthetic work+niri, synthetic no-compositor) - confirming the
      universal-import fix doesn't break any context.
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
