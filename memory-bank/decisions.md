# Decision Log

Append-only. Newest entries at the bottom. Each entry: date, decision,
rationale, and (if relevant) who/what prompted it.

---

### 2026-07-18 — Memory bank location and format
**Decision:** `dots/memory-bank/` (git-tracked), plain markdown files,
project-specific structure (not the generic Cline-style productContext/
activeContext template) since this is a single large refactor effort with a
clear phase structure, not an evolving general product.
**Rationale:** Needs to survive across machines/clones/sessions like
AGENTS.md does; a phase-tracker shape is more useful here than generic
memory-bank templates.

### 2026-07-18 — Bundle bugfixes into the re-architecture
**Decision:** Yes — fix concrete bugs found during inventory as part of the
relevant phase rather than tracking them separately.
**Rationale:** We're touching most files anyway during the refactor; cheaper
to fix in place than context-switch later.

### 2026-07-18 — Refactor depth: deep
**Decision:** Unify duplicated subsystems (tuning defaults, alien-package
discovery, suite boilerplate) rather than just reorganizing directories.
**Rationale:** User explicitly asked for deep consolidation once we talked
through the specific duplications found.

### 2026-07-18 — mkAppSet-style helper for suite boilerplate
**Decision:** Introduce a shared helper (`modules/core/lib.nix`) replacing
the hand-repeated enable-flag/package/alien-entry triples (26x in gui-apps
alone).
**Rationale:** Highest-leverage single reduction in duplication across every
suite file.

### 2026-07-18 — Dead options: wire up, don't remove
**Decision:** viewer.nix's 5 unused options and fonts.required get actually
wired to behavior, rather than deleted.
**Rationale:** They represent intended-but-unfinished functionality worth
completing rather than surface-area to cut.

### 2026-07-18 — Librewolf: keep native alien package, delete dead HM block
**Decision:** `programs.librewolf.enable = false` stays effectively "off";
delete the ~25 lines of unreachable extension/hardening config in
gui-apps.nix. Keep installing librewolf-bin via the alien/pacman path.
**Rationale:** User's explicit choice — simplicity over switching to a
Nix-managed librewolf.

### 2026-07-18 — Branch/checkout strategy is out of scope
**Decision:** This project does NOT design git branch topology. "Every
machine has its own checkout" — that's the user's process to manage. Our
job is narrower: make `dots` contain zero embedded local/host state so it's
branch/merge-friendly *regardless* of whatever topology is chosen.
**Rationale:** Direct user correction — I had over-specified a
personal/work branch scheme that wasn't asked for.

### 2026-07-18 — `location` axis meaning
**Decision:** `dotsLocal.location` is a freeform/loosely-typed tag for
physical location and/or network "situation" (home/parents/travel/office/
...), not a strict enum yet. Concrete consuming behavior (VPN, proxy, DNS,
etc.) is added feature-by-feature later, not designed upfront.
**Rationale:** User's own clarification; keep it flexible since concrete use
cases aren't fully known yet.

### 2026-07-18 — `dots-local` schema formality
**Decision:** Yes — formalize as a typed `lib.evalModules` schema, defined
in `dots`, evaluated once in `flake.nix`. Escape valves (`extraModules`,
`extraOverlays`, `tags`) included alongside typed axes so unmodeled needs
aren't blocked.
**Rationale:** User agreed; matches the multi-axis ask and removes the
30+ scattered ad-hoc `or`-fallback reads.

### 2026-07-18 — Rollout validation depth
**Decision:** `nix eval`/`nix build` per milestone; live `apply-dots` switch
only at explicitly flagged checkpoints (not every single commit).
**Rationale:** chromaden is the daily driver; balance fast iteration against
not breaking the primary machine on every small step. Shell-bootstrap
changes (Phase 6) and script-consolidation (Phase 7) are flagged as
mandatory live-checkpoint phases regardless, since they're hard to verify
via eval alone.

### 2026-07-18 — Shell bootstrap: KEEP gutter-eval, rename outputs only
**Decision:** Reversed my initial proposal to eliminate the double-HM-eval
"gutter eval" mechanism. It stays as-is. Only change: `nixon.nix` writes to
`.bashrc-nix`/`.profile-nix` instead of force-overwriting the real
`.bashrc`/`.profile`; a small stable loader stub becomes the real
`~/.bashrc`/`~/.profile`.
**Rationale:** Direct user correction: "There were good reasons why we ended
up with that so I'm reluctant to just drop it." Noted and respected —
do not re-litigate this without new information.

### 2026-07-18 — Composition = explicit declarative dependency rules
**Decision:** `modules/composition-rules.nix` as a small, explicit,
greppable list of `{ when = predicate; set = {...}; }` rules over
`dotsLocal` axes, folded via `mkIf`/`mkDefault` in `modules/composition.nix`.
**Rationale:** User's explicit ask: "I can write simple dependency rules
somewhere in dots, like if AI hardware enabled, pull in AI packages."

### 2026-07-18 — Consolidate OS/platform detection
**Decision:** Introduce one shared platform-detection value/module
(`modules/core/platform.nix`) consumed by clipboard.nix and opener.nix
instead of each independently declaring an identical `backend` enum +
command table. Must support Linux (Wayland/X11) + WSL2 + macOS.
**Rationale:** User flagged the existing duplication directly; these are
"essentials" that need solid cross-platform support.

### 2026-07-18 — Core tool list: review non-aggressively
**Decision:** Do not aggressively trim `modules/core/default.nix`. Only flag
genuinely mislabeled/accidental inclusions (`psutils` = PostScript utils,
not process utils; `t3` = tee-replacement, not tree-like, comment is wrong)
for user confirmation before any removal. Multi-tool overlaps that look
redundant at a glance (three pagers, three HTTP fetchers) are left alone
unless the user says otherwise.
**Rationale:** User explicitly uses many of the "modern CLI / rust rewrite"
tools and asked for a light touch, not an aggressive cut.

### 2026-07-18 — `dots-local` gets a first-class `shell` axis
**Decision:** Add `dotsLocal.shell.{sessionVariables,shellAliases,initExtra}`
as typed schema fields (Phase 1), merged into `programs.bash.*` by a small
core module. This is in addition to, not a replacement for, the general
`extraModules`/`extraOverlays` escape hatch.
**Rationale:** User: "make adding shell vars and other shell init stuff easy
in dots-local" — a full extra Nix module is too much ceremony for "I just
want one env var"; needs a dedicated low-friction path.

### 2026-07-18 — Document every config that loses its home in `dots`
**Decision:** Whenever Phase 1/2 removes config from `dots` in favor of
`dotsLocal` fields (host files, hardcoded per-machine values, etc.), a
documentation/template update showing how to reproduce it in
`dots-local/flake.nix` must land in the *same* change — never delete first
and document later (or not at all).
**Rationale:** Direct user instruction: "some of the existing config will
no longer have a home, solve this by putting files in the checkout
documenting how to setup the respective dots-local/flake.nix." This is the
concrete mechanism satisfying the earlier "store the current template in
dots for easy setup/adoption" goal from the original brief.

### 2026-07-18 — Explicit directive: preserve all overlays/package sources
**Decision:** Treat the current overlay list and flake-input set
(`nur`, `niri`, `noctalia`/`noctalia-qs`, `externalOverlay`,
`nixpkgs-quarto-pin`, `tuneOverlay`, etc.) as must-preserve-exactly during
the schema/composition rework, verified by spot-checking resolved packages
before/after each relevant phase, not just "it builds".
**Rationale:** Direct user instruction: "take great care to preserve
overlays additional package sources and the like." Flagged because
`flake.nix` is exactly the file Phase 1 (schema) and Phase 2 (composition)
need to restructure, making this an easy thing to regress silently.

### 2026-07-18 — Shell bootstrap: corrected understanding, new suffix `-dots`
**Decision:** After investigating the live system, `.bashrc-nix`/
`.profile-nix` already exist and are already the correct pure-HM-output
files (no change needed there). The part that still needs fixing is the
*separate* NIXON-gatekeeper hybrid script, which today `lib.mkForce`s the
real `~/.bashrc`/`~/.profile` directly. That hybrid content moves to
`.bashrc-dots`/`.profile-dots` (new suffix, avoiding collision with the
already-in-use `-nix` suffix), and the real dotfiles are no longer
`home.file`-managed at all — an idempotent, additive-only hook (activation
or setup.sh step) ensures they source `.bashrc-dots`/`.profile-dots`,
without ever overwriting existing user content.
**Rationale:** Direct user correction: "I already have bashrc-nix so you may
have to pick yet another suffix (-dots or so)." Investigating first avoided
a filename collision that would have broken the live system.

### 2026-07-18 — `noctalia-qs` input override: intentional, do not touch
**Decision:** The `nix eval` warning "input 'noctalia' has an override for a
non-existent input 'noctalia-qs'" (from `flake.nix`'s
`inputs.noctalia-qs.follows`) is expected and must be left as-is.
**Rationale:** Direct user statement: "The noctalia-qs override I saw nix
complaining about is setup in dots flake.nix we need it." Not a bug to fix.

### 2026-07-18 — Standing procedure: `git add` new files immediately
**Decision:** Any brand-new file created during this project must be
`git add`ed immediately, before treating any `nix eval`/`nix build` against
it as a real validation.
**Rationale:** Discovered the hard way - local Nix flake evaluation only
sees git-tracked/staged files; a new untracked file is silently invisible
(no error), which briefly made the `gcc15`/`llama-cpp` alien-spec fix
inactive despite every eval/build "passing." See learnings.md for the full
trail. This will recur in every later phase that adds files (schema.nix,
composition.nix, externalized scripts, etc.) so it's recorded here as a
standing rule, not just a one-off note.

### 2026-07-18 — Alien-package orphan detection: cross-manager union required
**Decision:** Orphan detection in `update-alien-packages` must check a
package's required-status against the union of ALL managers' required
lists, not just the same manager's list, plus a defense-in-depth check
directly in the removal prompt loop. Implemented via `get_all_required()`
in `modules/core/alien-packages.nix`.
**Rationale:** Real bug, found via a live user report (`ghostty` wrongly
flagged for removal) - a package whose spec moves from one manager to
another (e.g. an AUR package later added to an official repo) was
permanently stuck flagged as an orphan under the old manager forever, even
though still required and installed. This is exactly the kind of
false-positive that could cause real damage on a daily-driver machine if
acted on without investigation - worth the extra robustness given the
consequence of getting it wrong (accidentally uninstalling a needed,
working package).

### 2026-07-18 — Lightweight `alienPackages.protectedPackages` allowlist
**Decision:** Add a simple `listOf str` option, unioned into the orphan
detector's `get_all_required()` check, for native packages dots doesn't
manage but that other native packages depend on (first use: `fzf` on
chromaden, required by `downgrade`/`fontpreview`). Kept intentionally
minimal - no per-manager scoping, no reason/comment field, just a flat list
consumed the same way `enabledPackages` is.
**Rationale:** User explicitly asked to keep it lightweight. A full
solution (e.g. auto-detecting reverse-deps via `pacman -Qi`) would be more
robust but is unnecessary complexity for what's currently a one-package
need; revisit if this comes up often enough to justify automation.

### 2026-07-18 — Flake output renaming: pending explicit confirmation
**Decision:** Proposed collapsing `homeConfigurations.{priv,work,priv-opt,
work-opt}` to something like `default`/`default-opt` once composition is
axis-driven (no more profile-name selection). User said "roughly right" to
the overall plan but this specific point wasn't explicitly re-confirmed —
treat as tentatively approved, but **reconfirm at the Phase 2 checkpoint**
before actually changing `apply-dots` command surface (breaking muscle
memory).
**Rationale:** This changes user-facing commands; worth a final explicit
go-ahead right before executing, not just inferred from "roughly right".
