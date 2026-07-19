# Execution Plan

**Status: all 9 phases complete, live-checkpointed on chromaden, plus ~20
post-Phase-9 rounds of user-requested follow-up work (also complete).**
This file is now a compact chronological index. Full rationale/evidence
for every entry below lives in `decisions.md` (dated entries); gotchas
worth remembering live in `learnings.md`.

**Standard validation approach used throughout** (not repeated per entry
below): `nix eval` for fast iteration; a full
`nix build .../activationPackage` before considering anything done (eval
alone doesn't force derivation builds - see `learnings.md`); before/after
`config.home.packages`/`config.alienPackages.enabledPackages` diffs
(`git stash`/`pop` for single-commit spans, `git worktree` for
multi-commit spans) to confirm behavior-preservation; synthetic
`dots-local` copies under `/tmp` for testing host/axis combinations
without touching the real system; live `apply-dots` checkpoints only at
explicitly flagged milestones (shell-bootstrap and script-consolidation
phases, plus whenever the user directly ran it).

**Standing procedure**: `git add` any brand-new file immediately - local
flake evaluation is blind to untracked files, with no error (see
`learnings.md`'s 2026-07-18 "CRITICAL" entry). Hit this repeatedly early
on; now routine.

---

## Phase 0 — Memory bank + trivial bugfixes `[x] DONE, LIVE-CHECKPOINTED`
Fixed laputa's `features.scanning`→`suites.scanning` typo, which
uncovered laputa had never evaluated successfully at all (also missing
an `ai-apps` import and a required `programs.ssh` block). Fixed
copy-pasted header comments, migrated deprecated `matchBlocks`→
`settings`, missing `gcc15`/`gcc15-libs` alien spec, dead `niriPkg`
conditional, dead `sync-config.json` path references, a duplicated
`sync.sh` invocation, a `.bashrc_core` typo, `pim-apps`'s
`mkOption`→`mkEnableOption`, missing `sd-switch` enable option, dead
`librewolf` HM config block. Live-checkpointed; found and fixed a real
cross-manager orphan-detection bug live (`ghostty` false-positive
removal risk) plus a follow-up `protectedPackages` allowlist for `fzf`.

## Phase 1 — `dots-local` schema `[x] DONE`
`modules/local/schema.nix` (`lib.evalModules`) - additive/backward-
compatible (existing fields stay flat), not the fully-nested design
originally sketched (see `decisions.md`). Migrated every ad-hoc
`inputs.dots-local` read site to `dotsLocal`. Added
`dots-local-shell.nix` (low-ceremony `shell.*` fields). Fixed the
`march` default inconsistency and a real `appimages.nix` null-vs-missing
bug (only caught by a full `activationPackage` build, not a shallow eval
- see `learnings.md`).

## Phase 2 — Composition layer `[x] DONE, LIVE-CHECKPOINTED`
Flake output renamed `priv`/`work`/`*-opt`→`default`/`default-opt`
(confirmed by user). New `modules/rules.nix` (declarative axis rules) +
`modules/composition.nix` (folds rules via a `deepMkDefault` helper).
Retired `profiles/*/home.nix`/`hosts/*.nix`; new `machine`/`compositor`/
`display` schema fields. Generalized triomino's WSL-shell-integration
workaround into a real feature. Chromaden fully migrated and
live-validated; laputa/triomino structurally migrated via synthetic
`dots-local` copies (real machines out of this session's reach - see
`host-migration-phase2.md`, still the user's own follow-up). One
bootstrapping snag (stale installed `apply-dots` still referencing the
old flake-output name) fixed with one manual `nh` invocation.

## Phase 3 — Alien package unification + Debian/Azure Linux 4 `[x] DONE`
Merged the two independent alien-spec discovery engines into one shared
`alien-discovery.nix`. Added `apt` (Debian) and `dnf5` (Azure Linux 4)
backends, conservative official-repos-only specs. `modules/distros/*`
deferred here, later deleted entirely (confirmed fully dead, never
repurposed - see `decisions.md`). Found and fixed a real Phase 2 gap:
`opener`/`clipboard`/`ai-apps` needed universal imports for `rules.nix`
to reference them at all (a `lib.mkIf false` still requires the option
to be *declared* somewhere). Debian/Azure Linux 4 support was
structurally-ready-but-runtime-unverified at this point (no real
hardware yet) - since resolved for Debian, see the post-Phase-9 rounds
below.

## Phase 4 — `mkAppSet` helper `[x] DONE`
`modules/core/lib.nix`'s `mkAppSet` replaced repeated enable/package/
alien-entry triples across 9 suite/feature files (`gui-apps`'s 26 the
biggest win). Comprehensive before/after full-config diff - byte-
identical.

## Phase 5 — Tuning defaults unification `[x] DONE`
`modules/core/tune-defaults.nix` as the single source of truth for
`tune-support.nix` + `package-tuning.nix` (previously drifted copies).
`setup.sh` stopped embedding a full copy of the tuning table. Chromaden's
real `dots-local` already had an override masking any drift either way -
zero live impact.

## Phase 6 — Shell bootstrap retarget `[x] DONE, LIVE-CHECKPOINTED`
`nixon.nix`'s NIXON-gatekeeper hybrid moved from `lib.mkForce`-owning the
real `.bashrc`/`.profile` to writing `.bashrc-dots`/`.profile-dots`, with
a small idempotent activation hook sourcing them. **First live attempt
failed** ("Permission denied") - Home Manager's own built-in
`programs.bash` module reclaimed `.bashrc`/`.profile` once the override
was merely *removed* rather than *disabled*; fixed with explicit
`home.file.".bashrc".enable = lib.mkForce false;`. Retry succeeded;
generation confirmed byte-identical to the pre-validated build. See
`learnings.md` for the full "removing vs. disabling a `home.file`
declaration" gotcha.

## Phase 7 — Script consolidation `[x] DONE, LIVE-CHECKPOINTED`
`modules/core/scripts/common.sh` - shared bash boilerplate previously
copy-pasted 5x. `install-<x>`/`uninstall-<x>` pairs (llama-cpp, pi,
graphify) consolidated into `setup-<x> {install|remove|update}`.
Live-tested all 3 new commands on the real system.

## Phase 8 — Externalize large embedded scripts `[x] DONE`
`grabcontext.py`, `viewer.nix`'s `v.sh`, `clipboard.nix`'s
`clipboard.sh`, niri-noctalia's 4 helper scripts all moved to real
files. Pattern: a small Nix-string preamble resolves package paths/
conditionals into shell variables; the real file references only those
variables (see `learnings.md` for the bash-array-vs-string quoting
gotcha hit while extracting `clipboard.sh`'s WSL paste command).
`shellcheck` pass over every extracted file.

## Phase 9 — Wire up dead options, close out, final docs `[x] DONE`
`viewer.nix`'s 5 dead options actually gate `v.sh` behavior now.
`fonts.required` actually gets contributed to (`niri-noctalia`→
`pkgs.inter`) - `features.fonts.enable` itself deliberately left off
(user's own call, see `decisions.md`). README/OVERVIEW/SYNC.md brought
up to date (a large pre-existing staleness backlog found and fixed).
`preserved-features-checklist.md` finalized with real evidence per item.

**All 9 phases live-checkpointed as of here.**

---

## Post-Phase-9 rounds (chronological; full rationale + validation evidence in `decisions.md`, all dated 2026-07-19)

1. Removed stale "Phase N"/historical-narrative comments repo-wide;
   `AGENTS.md` fully rewritten (had drifted to describe the entire
   pre-Phase-2 system).
2. Renames: `composition-rules.nix`→`rules.nix`,
   `modules/dots-local/`→`modules/local/`; `modules/distros/*` deleted
   (confirmed fully dead).
3. Suites/features reclassification: `features.git`→`suites/git-tools`,
   `features.dev-tools`→`suites/dev-tools`; `features.network` split into
   `features.network` (SSH/GPG) + new `suites/network-tools`.
4. `setup.sh`/`sync.sh` brought up to date with `schema.nix` - found and
   fixed a real `programs.ssh.settings."*"` assertion bug via a
   fresh-setup regression test (see `learnings.md`); implemented
   `sync.sh`'s long-documented-but-missing `-g` flag.
5. CLI-only-by-default `priv` context (`opener`/`clipboard`/
   `sixel-tools` no longer forced on); core minimization (removed
   `psutils`/`t3`/`ov`, 5 duplicate packages); moved `prettier`/`curlie`/
   `tailspin` into suites; removed the `fresh` editor (confirmed no-op
   vs. helix); pager cleanup (removed `moor`, wired up `difftastic`
   properly).
6. Removed `.bashrc-core`/`.profile-core` indirection; AppImage catalog
   moved into `dots` (`profiles/priv/appimages/manifest.nix`, fixed a
   real `recursiveUpdate`/null-stripping bug); named syncables registry
   (`modules/core/syncables.nix`) + `sync.enable` schema field +
   `niri-noctalia` assertion.
7. Removed chromaden's now-redundant `tune.flags` override; added
   `dots-local-options` command (live schema introspection via
   `lib.optionAttrSetToDocList`).
8. Replaced `setup.sh`'s embedded heredoc with real
   `templates/dots-local/*` files (later renamed, see #19).
9. Wrap-up audit: `git-tools.nix` onto `mkAppSet`, removed several
   duplicate packages (`zellij`/`lazygit`/`bash`/`delta`), wired up
   butterfish's `shell` option, filled README feature-table gaps.
10. Removed the never-consumed `.feature` key from all alien specs
    (~101 occurrences); added real alien-spec conflict detection instead
    (throws on divergent same-name specs across files).
11. Fixed `suites.git-tools.jj` installing the wrong nixpkgs package
    (`tidwall/jj` JSON tool instead of Jujutsu); fixed `NIXON=1` mode
    never guaranteeing the raw `nix` binary was on PATH (root cause of a
    real `apply-dots` failure); fixed chromaden's half-finished
    `nixonDefault`.
12. Dead-code audit (user-itemized approval): fixed a real
    `sixel-tools.nix` `FONTCONFIG_FILE` bug, `dev-tools.nix`'s wrong
    `.nixd.json` reference, removed several dead functions/entries,
    documented `etc/` as intentional reference material.
13. Root-caused and removed the `noctalia-qs` "non-existent input"
    warning (permanent no-op, confirmed via upstream's own `flake.nix`).
14. `modules/core/platform.nix` - consolidated `clipboard`/`opener`
    backend detection into one shared derived value.
15. Extended Debian (bookworm) alien specs for `sixel-tools`/
    `cloud-tools`/`dev-tools`/`ai-apps` (user now has real hardware).
16. Quarkdown updated to 2.4.0, dropped the Nix-provided `jre` entirely
    (upstream now bundles its own runtime).
17. Simplified `nixpkgs-quarto-pin` to quarto-only (dropped a redundant
    pandoc override - pandoc's version was never actually different).
18. flake.nix necessity audit - commented out unused `nur`/`nixgl`
    inputs (kept, not deleted, per user decision).
19. Renamed `templates/dots-local/`→`templates/local/`, added
    `templates/local/host.nix`.
20. Verified `setup.sh` correctly hooks into pre-existing shell content
    (tested end-to-end with realistic pre-existing `.bashrc`/`.profile`
    content, including the no-trailing-newline edge case).

---

## Notes
- Phases 1→2 are the architectural core; phases 3-9 are more
  independent/reorderable.
- `sync.sh`/`setup.sh`: substantially revised across rounds 4/7/8/19
  above; no broader redesign currently planned (see `open-questions.md`).
- laputa/triomino still need the documented follow-up in
  `host-migration-phase2.md` - explicitly left to the user, not this
  session's to do.
