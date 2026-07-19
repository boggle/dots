# Open Questions / Parking Lot

Unresolved items that need the user's input before (or during) the relevant
phase. Move items to `decisions.md` once resolved.

---

### Flake output naming (Phase 2 checkpoint) — RESOLVED, executed
Collapsed `homeConfigurations.{priv,work,priv-opt,work-opt}` into
`default`/`default-opt` once composition became fully axis-driven (see
`flake.nix:172-175`). `apply-dots` / `apply-dots opt` now select
baseline vs. optimized with no profile-name argument. Done as part of
Phase 2; this entry is kept only as a historical record.

### `psutils` / `t3` — RESOLVED, removed
User confirmed (2026-07-19, core minimization round): remove both. Done -
see `decisions.md`'s "CLI-only defaults, core minimization, editor/pager
cleanup" entry.

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

### `noctalia-qs` "non-existent input" warning - investigate later
Confirmed not a regression (identical since before this session, see
decisions.md 2026-07-18 "noctalia-qs input override: intentional, do not
touch"), but flagged by user (2026-07-18, second time) for eventual
root-cause investigation: why does `inputs.noctalia.inputs.noctalia-qs.follows
= "noctalia-qs"` trigger "has an override for a non-existent input" - does
the upstream `noctalia-shell` flake not declare a `noctalia-qs` input at
all (making this override a permanent no-op), or is this a transient
lock-file staleness issue? Low priority, purely cosmetic today, but worth
resolving cleanly at some point rather than leaving a permanent warning in
every eval. Do NOT remove the override without figuring out the actual
answer first - user has twice confirmed dots needs it for something.

### `sync.sh` / `setup.sh` deeper improvements — mostly done, note is stale
Originally deferred by the user ("stash this for later") beyond
what each phase directly required. Since then, substantially more has
landed than "deferred": named syncables + `sync.sh -g`/`--force-regen`
(post-Phase-9 round 4/7), the SSH-assertion bug fix (round 4), and real
standalone `templates/dots-local/*` files replacing the `setup.sh`
heredoc (round 10) - see `decisions.md` for each. What remains
genuinely deferred/undone: no broader sync.sh/setup.sh redesign beyond
these targeted fixes has been attempted, and none is currently
planned unless the user asks for one.

### `barch` remains unused/dead
Confirmed during Phase 1: `dotsLocal.barch` (baseline arch level, e.g.
"x86_64-v3") is still not consumed by any module - only `march` is (now
correctly wired into the `-opt` profile build, see decisions.md). Kept as a
schema field for forward-compat since it costs nothing, but there's no
current concrete use. Revisit if a real need emerges (e.g. distinguishing
"tuned for my exact CPU" from "compatible with this baseline level" for
binary distribution scenarios).

### `features.fonts.enable` - RESOLVED, see decisions.md 2026-07-19
Was flagged as an open decision during Phase 9 (discovered
`features.fonts.enable` has never been `true` anywhere, on any host, ever
- not a regression from this re-architecture; chromaden's fonts currently
work only by accident via a native pacman package). User decided
(2026-07-19): leave it off for now, revisit later. Full details in
`decisions.md`'s "features.fonts.enable: leave off for now" entry and
`plan.md`'s Phase 9 section.
