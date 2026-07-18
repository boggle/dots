# Learnings

Running log of gotchas, Nix quirks, and things discovered while executing.
Append as you go — newest at the bottom.

---

### 2026-07-18 — Initial inventory findings
- `psutils` (in `modules/core/default.nix`) is **PostScript document
  utilities** (psnup/psselect), not process utilities — confirmed via
  `nix eval .#homeConfigurations.priv.pkgs.psutils.meta.description`. The
  inline comment ("psutils # psutils") is unhelpful and likely reflects a
  misunderstanding at the time it was added.
- `t3` is actually **"next generation tee with colorized output streams and
  precise time stamping"** — confirmed via the same technique. The inline
  comment ("Tree-like utility") is simply wrong; it has nothing to do with
  `tree`.
- General technique: `nix eval .#homeConfigurations.<profile>.pkgs.<name>.meta.description
  --override-input dots-local git+file://$HOME/dots-local` is a quick way to
  check what a package actually is without a full build.
- `chromaden.nix`'s `programs.ssh.matchBlocks` usage triggers a Home Manager
  deprecation warning (`Use programs.ssh.settings`) during `nix eval` — a
  live, currently-harmless warning worth fixing opportunistically in
  Phase 0.
- Two independently-implemented alien-package discovery engines already
  exist (`modules/flake/alien-package-specs.nix` vs
  `modules/core/alien-packages.nix`) — confirmed both scan
  `modules/**/*.<distro>-packages.nix` with near-identical code, a real
  duplication (not just superficially similar).
- Confirmed via `git branch -a`/`git remote -v` in `dots`: two remotes exist
  today (`origin` = `boggle/dots`, `other` = `spmsft/dots`), single shared
  `main` branch, with history showing an explicit merge-conflict resolution
  between them (`ai-apps.cachyos-packages.nix`) — concrete evidence of the
  pain point motivating this whole project.
- `dots-local` (private repo) is a separate git repo (not a branch of
  `dots`), currently on `master`, no extra remotes configured locally.

### 2026-07-18 — Actual current shell-bootstrap mechanics (corrected)
Initially assumed `nixon.nix` directly force-writes the real
`~/.bashrc`/`~/.profile` with no separation from the pure Nix output. Wrong
— investigating the live system (`ls -la ~/.bashrc*`, reading `nixon.nix` in
full) showed the real current state:
- `~/.bashrc-nix` / `~/.profile-nix` — pure gutter-eval HM output
  (`home.file.".bashrc-nix".source = bashrcDerivation;` etc.) — **already**
  a separate, correctly-named file. This is why the user already has a
  `.bashrc-nix` and a new phase-6 suffix had to avoid colliding with it.
- `~/.bashrc` / `~/.profile` — **also** `home.file`-managed
  (`lib.mkForce`'d), but contain a hand-authored "NIXON gatekeeper" hybrid
  script (toggle NIXON on/off via `nixon`/`nixoff` aliases, sources
  `.bashrc-nix` conditionally when `NIXON=1`, otherwise strips `/nix` from
  PATH for a "pure host" mode). This is the file that still needs to stop
  being force-owned by Nix per the original ask.
- `~/.bashrc-core` (hyphen) is a real, non-Nix-managed file on disk
  containing `QT_QPA_PLATFORMTHEME`/`GTK_THEME` exports — but `nixon.nix`'s
  gatekeeper script sources `~/.bashrc_core` (underscore!) — a naming
  mismatch bug, confirmed via `grep`, meaning this file is currently
  silently never loaded. `~/.profile-core` (hyphen) has no such bug (the
  profile hybrid correctly references it with a hyphen), it's just that no
  such file currently exists on disk.
- Lesson: always inspect the live filesystem state before proposing a
  rename/retarget scheme for dotfiles-adjacent mechanisms — the abstract
  code-reading-only inventory missed this nuance initially.

### 2026-07-18 — laputa.nix was completely broken, not "silently non-functional"
The original inventory guessed the `features.scanning` vs `suites.scanning`
typo was "likely silently broken" on laputa. Verified via an actual `nix
eval` (using a temp copy of `dots-local` with `host = "laputa"` swapped in,
`--override-input dots-local git+file://...`) that it was in fact a **hard
eval error** ("The option `features.scanning' does not exist"), meaning
`apply-dots`/`nix eval .#homeConfigurations.priv` has never succeeded for
laputa in this form. Fixing that one typo uncovered a second, worse bug:
`profiles/priv/home.nix` unconditionally sets `suites.ai-apps.*` for every
priv host, but `modules/suites/ai-apps.nix` was only imported by
`chromaden.nix` and `triomino.nix` individually, not at the profile level —
so laputa also failed with "The option `suites.ai-apps' does not exist"
right after the scanning fix. Fixed by importing `ai-apps.nix` at the
profile level (`profiles/priv/home.nix`) and removing the now-redundant
per-host imports from chromaden.nix/triomino.nix. A third bug surfaced
after that: `network.nix` sets `programs.ssh.extraConfig` +
`enableDefaultConfig = false`, which (in the current Home Manager version)
asserts that `programs.ssh.settings."*"` must be declared — chromaden and
triomino both declare an ssh identity block (via the now-deprecated
`matchBlocks."*"`) but laputa had no `programs.ssh` block at all. Added one
(`~/.ssh/id_github_laputa`, matching the established per-host convention)
using the modern `programs.ssh.settings."*"` key (PascalCase:
`IdentityFile`/`AddKeysToAgent`), and took the opportunity to migrate
chromaden.nix/triomino.nix off the deprecated `matchBlocks` to the same
`settings` form while fixing their copy-pasted "Laputa Machine
Configuration" header comments.
- **Technique note:** to test a specific host's config without touching the
  real `dots-local`, copy it to a scratch dir
  (`cp -r ~/dots-local /tmp/opencode/dots-local-<host>-test`), sed the
  `host = "...";` line, commit (it's a git flake input, needs a commit to be
  read), then `nix eval .#homeConfigurations.priv.config.home.username
  --override-input dots-local git+file:///tmp/opencode/dots-local-<host>-test`.
  Cheap and safe way to validate all three hosts without a live switch.
- **Implication for Phase 2 (composition redesign):** this whole class of
  bug (a host silently missing an import that another part of the config
  assumes is present) is exactly what the axis/rule-driven composition
  model is meant to eliminate — worth using as a concrete before/after
  example when documenting the migration.

### 2026-07-18 — CRITICAL: untracked new files are invisible to `nix eval`/flakes
When creating `modules/features/llama-cpp.cachyos-packages.nix` (a brand
new file, via the `write` tool), every `nix eval`/`nix build` I ran against
it appeared to succeed and "validate" the fix - but the file was **git
untracked** (`git status` showed `??`), and Nix flakes evaluated from a
local git working tree only see **git-tracked (or at least staged) files**.
Untracked files are silently invisible to the evaluation, with no
warning/error - the fold over discovered spec files just acts as if the new
file doesn't exist, and any package names that used to be defined in the
old location (which I'd already removed those entries from) simply
vanish from `rawAlienSpecs` entirely. Concretely this meant `cuda-llama`,
`vulkan-llama`, `gcc15`, `gcc15-libs` were **not being tracked as required
by anything** for a period - worse than the original bug (where at least
`cuda-llama`/`vulkan-llama` worked, just missing `gcc15`/`gcc15-libs`) -
despite every eval/build I ran claiming success, because none of those
checks would ever exercise the "does this file get discovered" path in a
way that surfaces the gap (a missing key just silently contributes zero
packages, no error).
- **Root cause confirmed** by writing a standalone probe script
  (`nix eval --file` against a plain filesystem path, bypassing flakes'
  git-tracking entirely) which DID find the file/keys correctly - proving
  the discovery logic itself was fine and the issue was purely
  flakes-vs-git-tracking.
- **Fix:** `git add` the new file. After staging, `nix eval
  '.#homeConfigurations.priv.config.home.file."...".text'` correctly showed
  `cuda`/`gcc15`/`gcc15-libs`/`vulkan-*` in the required set.
- **Standing operating procedure for the rest of this project:** run
  `git add <newfile>` **immediately** after creating any new file with the
  `write` tool, before considering any `nix eval`/`nix build` against it a
  real validation. This will come up repeatedly in later phases (schema.nix,
  composition.nix, composition-rules.nix, template.nix, externalized
  scripts in Phase 8, etc.) - each is a new file and each needs this same
  discipline. Consider running `git add -A` (or targeted `git add`) as a
  standard first step whenever a phase's work includes new files, before
  any validation step.
- Silver lining: this doesn't affect *modifications* to already-tracked
  files (only brand-new untracked files are invisible), so most of Phase
  0's other fixes were validated correctly.

### 2026-07-18 — Phase 1 (dots-local schema) implementation gotchas
Several real Nix/evalModules quirks surfaced while wiring up
`modules/dots-local/schema.nix` into `flake.nix`:

1. **A flake input can't be passed bare into `lib.evalModules`'s `modules`
   list.** `inputs.dots-local` isn't just the plain data attrset dots-local's
   `outputs` function returns - Nix attaches hidden introspection/metadata
   attributes to it (`_type = "flake"`, `inputs`, `outPath`, `outputs`,
   `rev`, `sourceInfo`, `lastModified`, ...). Passed directly, evalModules
   errors with "Expected a module, but found a value of type 'flake'."
   Fixed by wrapping as `{ config = dotsLocalData; }` (making the intent
   explicit) AND stripping the metadata attrs first via
   `builtins.removeAttrs` (otherwise each metadata attr fails independently
   as "The option `_type'/`outPath'/etc does not exist", since evalModules
   validates every config key against declared options).
2. **Dirty git state adds MORE metadata attrs.** When `dots-local` itself
   has uncommitted changes, Nix additionally attaches `dirtyRev` and
   `dirtyShortRev` - discovered when fixing an unrelated typo in the real
   `dots-local/appimages.nix` (`dektopName` -> `desktopName`) without
   committing it first, which immediately broke the eval with "The option
   `dirtyRev' does not exist." Both clean and dirty states needed handling
   since editing dots-local without committing is explicitly a supported,
   expected workflow (per AGENTS.md's Nix Evaluation section).
3. **`option or default` only helps for a *missing* attribute, not a
   *present-but-null* one - and schema-validated submodules make previously
   "missing" fields always-present.** `modules/features/appimages.nix`'s
   `mkSharedWrapper`/`mkHostLocalWrapper` used `app.desktopName or name` and
   `app.categories or [ "Utility" ]` to provide fallbacks. Once
   `dotsLocal.appimages` became a schema-typed submodule (with
   `desktopName` defaulting to `null` and `categories` defaulting to `[]`),
   those keys are now ALWAYS present on every entry - so `or` never
   triggers anymore, and a `null`/`[]` value flows straight through into
   `pkgs.makeDesktopItem`, causing "cannot coerce null to a string: null"
   deep inside the `home-manager-generation` derivation's build (NOT caught
   by a plain `nix eval .#homeConfigurations.priv.config.home.username` -
   only surfaced when building the full `activationPackage`, since that's
   what actually forces evaluation of the desktop-item derivations). Fixed
   with an explicit `if (app.field or null) != null then app.field else
   default` pattern, which correctly handles both origins (schema-typed
   host-local apps AND raw, non-schema-validated shared-manifest imports
   that might genuinely be missing the key).
   - **Process lesson**: `nix eval .#homeConfigurations.<x>.config.home.username`
     (or similar shallow attribute reads) is a fast sanity check but does
     NOT force evaluation of most derivations (packages, activation
     scripts, desktop items, etc.) - it only proves the *module system*
     resolves without error. A full `nix build
     .#homeConfigurations.<x>.config.home.activationPackage` (and/or
     `config.home.path`) is necessary to catch errors that only manifest
     when derivations are actually forced. Use both: cheap eval first for
     fast iteration, full build before considering a phase done.
4. **The exact same `dots-local.march` "znver5" vs "native" default
   inconsistency flagged during the original inventory was real and is now
   fixed** - see decisions.md. Also fixed a related, previously-undiscovered
   bug in the same area: the `-opt` profile build hardcoded
   `gcc.arch = "znver5"` directly in `flake.nix`, ignoring
   `dotsLocal.march` entirely (would have silently built for the wrong
   microarchitecture on any non-znver5 machine using `apply-dots <profile>-opt`).

### 2026-07-18 — `update-alien-packages` orphan false-positive: `ghostty`
User reported `update-alien-packages --action remove` wanted to remove
`ghostty`, which is actively needed/used. Investigated and found a genuine,
pre-existing bug (not user-specific config) in
`modules/core/alien-packages.nix`'s orphan-detection logic:
- `ghostty`'s alien spec is declared under `pacman` today
  (`gui-apps.cachyos-packages.nix`), and is genuinely installed as a native
  package (confirmed `pacman -Qi ghostty` -> `Installed From:
  cachyos-extra-znver4`, and `pacman -Qm` shows it's NOT a foreign/AUR
  package). But `~/.local/share/dots/packages/orphaned/paru.txt` still
  listed it - a stale leftover almost certainly from before ghostty was
  added to the official repos (when its spec was presumably
  `paru = [...]`).
- Root cause: orphan detection only ever cross-checked a package against
  *the same manager's* required list (`orphans = previously_installed(mgr)
  - required(mgr)`), never against the union of all managers. Since pacman
  and paru share the exact same underlying installed-package database
  (`paru` is just an AUR-aware `pacman` wrapper; `get_installed_packages`
  literally runs `pacman -Qq` for both), a package whose *spec* moves from
  one manager to another gets permanently stuck flagged as an orphan under
  the OLD manager, forever, even though it's still required (just via a
  different manager) and still genuinely installed. `sudo pacman -Rns`
  doesn't care which manager "owns" a package, so running the remove action
  would have genuinely uninstalled the working ghostty binary.
- Also found: `aocl-gcc`/`aocl-utils` were in the same orphan file, but
  these are NOT currently installed at all (`pacman -Qi` errors "not
  found") - genuinely orphaned tracking-wise, but harmless either way since
  there's nothing installed to actually remove.
- **Fix implemented:** added `get_all_required()` (union of all
  `required/*.txt` files) and used it everywhere orphan status is computed
  or filtered (both the fresh per-run orphan calculation and the cumulative
  orphan-file reconciliation), plus a defense-in-depth check directly in
  `remove_packages`'s prompt loop that skips (with a clear message) any
  package still required by ANY manager's current spec, even if the orphan
  file hasn't been refreshed yet.
- **Second bug found while testing the fix**: `get_all_required`'s first
  implementation used `cat "$PKG_DIR"/*.txt | sort -u` - but those files are
  Nix `home.file` text (`lib.concatStringsSep "\n" packages`), which does
  **not** end in a trailing newline. Plain `cat` then glues the last line of
  one file to the first line of the next (e.g. `zellij` + `frogmouth` ->
  `zellijfrogmouth`), silently dropping BOTH names from the computed set.
  Fixed by using `awk 1 "$PKG_DIR"/*.txt | sort -u` instead, which
  normalizes every line to be newline-terminated regardless of each file's
  own ending. Caught this by manually replicating the `comm` computation
  step-by-step against the real on-disk files rather than trusting the
  script's output at face value.
- **Third bug found while testing the fix (pre-existing, not introduced by
  this change)**: `remove_packages` used `((counter++))` under `set -e`
  (enabled at the top of the whole script). Bash arithmetic command
  `((expr))` returns the shell-truth value of the *result*; post-increment's
  result is the OLD value, so the very first increment from 0 evaluates to
  `((0))` = false = failure exit status, which `set -e` treats as reason to
  abort the entire script immediately, silently, no error message. Verified
  in isolation: `bash -c 'set -e; n=0; echo before; ((n++)); echo after'`
  prints only `before`. Concretely this meant: the first time a user
  skipped or successfully removed a package during
  `update-alien-packages --action remove`, the script would silently exit
  right there, leaving any remaining orphans in the file completely
  unprocessed (no error shown - looks like it just "finished early").
  Verified by testing the remove flow end-to-end with 3 orphan entries and
  observing only the first got prompted. Fixed by replacing all 5
  occurrences of `((var++))` with `var=$((var + 1))` (plain assignment,
  always succeeds regardless of the resulting value).
- **Verified end-to-end on the live system** (not just eval): ran the
  actual built `update-alien-packages` binary directly from its
  `/nix/store` path against real `~/.local/share/dots/packages/*` state -
  confirmed (a) dry-run now shows "All packages in order" for both
  managers, (b) the remove flow now correctly processes all 3 orphan
  entries in one pass (auto-skipping `ghostty` with a clear message,
  prompting normally for the two non-installed AOCL packages), and (c) a
  real (non-dry-run) `update` action self-healed the stale orphan file,
  removing the `ghostty` entry automatically with no manual file editing
  needed.
