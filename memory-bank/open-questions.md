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

### Pagers / HTTP fetchers overlap — CLOSED, keep as-is
`moor`/`ov`/`less` (three pagers) and `curl`/`wget`/`curlie` (three HTTP
tools) look like overlap at a glance but are plausibly intentional
(different habitual uses per the inline comments). User confirmed
(2026-07-19, wrap-up round) no further action needed - closing this
out rather than leaving it open indefinitely.

### Debian support scope — RESOLVED for the 4 suites requested
User confirmed (2026-07-19) which suites their real Debian 12
(bookworm) machine needs: `sixel-tools`, `cloud-tools`, `dev-tools`,
`ai-apps`. Added `*.debian-packages.nix` for all four, verified each
candidate package's actual presence in bookworm's *official* archive
via packages.debian.org before including it (matching the existing
conservative, official-repos-only convention) - see `decisions.md` for
the full per-package confirm/skip list.

Still not covered (no Debian specs yet, not requested): `gui-apps`,
`pim-apps`, `scanning`, `niri-noctalia`, `opener`, `llama-cpp` -
revisit if/when the user's Debian machine needs any of these too.

### `location` axis concrete usage — CLOSED for now, revisit if a use case emerges
Currently just a freeform tag with no consuming behavior wired up yet
(per the 2026-07-18 decision). User confirmed (2026-07-19, wrap-up
round) no concrete use case yet - closing this out as "intentionally
inert" rather than a lingering open question. Revisit once there's a
concrete use case (e.g. VPN/proxy/DNS switching) to decide whether it
needs to become a typed enum or richer submodule.

### Platform/OS detection follow-up candidates
`network.nix` (ssh-agent socket path differs on macOS) and `viewer.nix`
(image viewer choice may need a macOS-specific path) were flagged as
follow-up candidates for the same platform-detection consolidation as
clipboard/opener, but are not required in the initial pass. Revisit after
Phase 2/3.

### `noctalia-qs` "non-existent input" warning - RESOLVED, removed
Root-caused (2026-07-19): fetched upstream `noctalia-shell`'s own
`flake.nix` directly (github raw + `nix flake metadata`'s `locks.root
.inputs`) - it has only ever declared `nixpkgs` as an input, never
`noctalia-qs`. `dots`'s `inputs.noctalia.inputs.noctalia-qs.follows =
"noctalia-qs";` was therefore a permanent no-op, not a transient
lock-file issue. Removed just that cross-reference line; the separate,
standalone `noctalia-qs` flake input (genuinely used via
`noctalia-qs.enable`/`noctalia-qs.overlays.default` elsewhere in
flake.nix) is completely untouched. Verified the warning is gone and
`config.home.packages` is byte-identical to before.

### `sync.sh` / `setup.sh` deeper improvements — CLOSED, substantially done
Originally deferred by the user ("stash this for later") beyond
what each phase directly required. Since then, substantially more has
landed than "deferred": named syncables + `sync.sh -g`/`--force-regen`
(post-Phase-9 round 4/7), the SSH-assertion bug fix (round 4), and real
standalone `templates/dots-local/*` files replacing the `setup.sh`
heredoc (round 10) - see `decisions.md` for each. User confirmed
(2026-07-19, wrap-up round) closing this out - no broader sync.sh/
setup.sh redesign is currently planned; revisit only if a new concrete
need comes up.

### `barch` remains unused/dead — CLOSED for now, revisit if a use case emerges
Confirmed during Phase 1: `dotsLocal.barch` (baseline arch level, e.g.
"x86_64-v3") is still not consumed by any module - only `march` is (now
correctly wired into the `-opt` profile build, see decisions.md). Kept as a
schema field for forward-compat since it costs nothing, but there's no
current concrete use. User confirmed (2026-07-19, wrap-up round) closing
this out - revisit if a real need emerges (e.g. distinguishing "tuned for
my exact CPU" from "compatible with this baseline level" for binary
distribution scenarios).

### `features.fonts.enable` - RESOLVED, see decisions.md 2026-07-19
Was flagged as an open decision during Phase 9 (discovered
`features.fonts.enable` has never been `true` anywhere, on any host, ever
- not a regression from this re-architecture; chromaden's fonts currently
work only by accident via a native pacman package). User decided
(2026-07-19): leave it off for now, revisit later. Full details in
`decisions.md`'s "features.fonts.enable: leave off for now" entry and
`plan.md`'s Phase 9 section.

### `.feature = "..."` key in alien-package spec files - RESOLVED, removed
User clarified (2026-07-19) the original intent: shadowing an alien
(distro-native) package over its Nix counterpart when a feature is
enabled for the current distro. That's exactly what already happens
today via plain package-**name** matching (`hasAlien pkgName =
rawAlienSpecs ? ${pkgName}` in both `alien-package-specs.nix`/
`alien-packages.nix`) - the `.feature` field was never part of that
mechanism (confirmed unconsumed since the repo's very first commit).
User agreed: nothing to salvage, remove it - all ~101 occurrences
deleted across every `*.<distro>-packages.nix` file; `OVERVIEW.md`/
`AGENTS.md`'s matching doc examples updated to match (and `AGENTS.md`'s
"use the feature name as the key" instruction corrected to "use the
package name as the key", which was already slightly wrong
independent of the `.feature` field itself).

Follow-up the user raised while discussing this (not a re-litigation,
a genuinely new and better idea): rather than re-introducing any kind
of per-feature ownership/isolation for alien specs ("a bit weird" per
the user's own words), instead **detect and report if the same package
name is ever defined with different content by more than one spec
file** - since the previous plain `//` merge silently let whichever
file was walked last win, with zero indication of an override. Done:
`modules/flake/alien-discovery.nix`'s `collectAlienSpecs` now throws a
clear build-time error identifying every such conflict (file paths
included), naturally running as part of every `nix build`/`apply-dots`
since alien-spec discovery is on that critical path already - no
separate validation script needed. Verified end-to-end by introducing
a synthetic conflict (temporarily duplicating `nmap`'s key with
different content across two spec files) and confirming the exact
expected error fires, then reverting. Identical-content duplicates
across files are deliberately NOT flagged (harmless redundancy, not a
real disagreement).
