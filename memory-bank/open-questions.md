# Open Questions / Parking Lot

Unresolved items that need the user's input before (or during) the relevant
phase. Move items to `decisions.md` once resolved.

---

### Flake output naming (Phase 2 checkpoint)
Proposed collapsing `homeConfigurations.{priv,work,priv-opt,work-opt}` into
something like `default`/`default-opt` once composition is fully
axis-driven (no more profile-name selection needed). This changes the
`apply-dots priv` / `apply-dots priv-opt` command surface. User said
"roughly right" to the overall plan but didn't explicitly re-confirm this
specific point — **must reconfirm before executing Phase 2's flake.nix
changes.**

### `psutils` / `t3` — keep or drop?
Both are mislabeled in `modules/core/default.nix`'s comments (see
`learnings.md`). Confirm whether they're actually used for their *real*
purpose (PostScript utils / tee-replacement) before removing anything —
"non-aggressive" trim policy means we don't remove without confirmation.

### Pagers / HTTP fetchers overlap
`moor`/`ov`/`less` (three pagers) and `curl`/`wget`/`curlie` (three HTTP
tools) look like overlap at a glance but are plausibly intentional
(different habitual uses per the inline comments). Not touching these
without explicit user input.

### Debian support scope
Structural support only for now (spec convention + apt backend + CLI
feature specs). GUI/AI suite Debian specs deferred until there's an actual
Debian machine to verify against. Confirm this scoping is acceptable when
Phase 3 starts, and revisit once a Debian machine exists.

### `location` axis concrete usage
Currently just a freeform tag with no consuming behavior wired up yet
(per the 2026-07-18 decision). Revisit once there's a concrete use case
(e.g. VPN/proxy/DNS switching) to decide whether it needs to become a
typed enum or richer submodule.

### Platform/OS detection follow-up candidates
`network.nix` (ssh-agent socket path differs on macOS) and `viewer.nix`
(image viewer choice may need a macOS-specific path) were flagged as
follow-up candidates for the same platform-detection consolidation as
clipboard/opener, but are not required in the initial pass. Revisit after
Phase 2/3.

### `sync.sh` / `setup.sh` deeper improvements
Explicitly deferred by the user ("stash this for later"). Only touched
where a phase directly requires it (Phase 1 template generation, Phase 5
tuning-table removal). Full sync.sh/setup.sh overhaul is a distinct future
project, not part of this one.
