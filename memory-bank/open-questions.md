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

### `sync.sh` / `setup.sh` deeper improvements
Explicitly deferred by the user ("stash this for later"). Only touched
where a phase directly requires it (Phase 5 tuning-table removal). Full
sync.sh/setup.sh overhaul is a distinct future project, not part of this
one. **Update (Phase 1)**: decided NOT to create `modules/dots-local/
template.nix` in Phase 1 after all - nothing was actually removed from
`dots-local`'s responsibility in Phase 1 (schema formalizes existing fields
+ adds new inert ones), so there's no new "config that lost its home"
requiring a fresh template yet. `schema.nix`'s option descriptions serve as
the self-documentation for now. Deferred to Phase 2, when host files
actually get retired and dots-local gains genuinely new required fields
(display config, CUDA arch, etc.) - that's when a real template becomes
necessary, per architecture.md section 1c's standing rule.

### `barch` remains unused/dead
Confirmed during Phase 1: `dotsLocal.barch` (baseline arch level, e.g.
"x86_64-v3") is still not consumed by any module - only `march` is (now
correctly wired into the `-opt` profile build, see decisions.md). Kept as a
schema field for forward-compat since it costs nothing, but there's no
current concrete use. Revisit if a real need emerges (e.g. distinguishing
"tuned for my exact CPU" from "compatible with this baseline level" for
binary distribution scenarios).

### `features.fonts.enable` is `false` everywhere - always has been, not a regression
Discovered during Phase 9 while wiring `niri-noctalia.nix` to contribute to
`features.fonts.required` (the literal Phase 9 ask). Confirmed via
`git log -p` on the pre-Phase-2 `profiles/priv/home.nix` history:
`features.fonts.enable = true` has **never** been set anywhere in this repo,
on any host, at any point - this is not something Phase 2's composition
refactor (or any later phase) broke. `modules/features/fonts.nix`'s entire
`config = lib.mkIf cfg.enable {...}` block (the `nerd-fonts.iosevka-term`/
`nerd-fonts.iosevka` packages, `fonts.fontconfig.enable`, and the
`defaultFonts` monospace/sansSerif/serif preferences) has been completely
inert on every host the whole time.

On chromaden this has caused no *visible* problem, but only by accident:
directly checked the live host - `ttf-iosevkaterm-nerd` is installed via
**native pacman**, `Install Reason: Explicitly installed` (the user ran
`pacman -S`/an AUR helper directly, outside of dots entirely, 2026-03-09).
It's also a hard dependency of `yazi`/`goverlay` (both already
alien-managed via `tui-apps`/`gui-apps`), so even without that manual
install some nerd font would land via pacman regardless - just not
necessarily Iosevka specifically. Noctalia's own icon needs (Tabler Icons)
are bundled inside its own package payload, unrelated to any of this.
`gui-apps.nix`'s wezterm config also has a hardcoded
`~/.nix-profile/share/fonts/truetype/NerdFonts/IosevkaTerm/...` path that
**does not exist** on chromaden today (confirmed directly) - dead/broken
fallback code, though harmless since wezterm isn't the active terminal.

**What Phase 9 did fix**: `features.fonts.required` is now actually
contributed to (`niri-noctalia.nix` adds `pkgs.inter`, since Noctalia's UI
wants "Inter" per `fonts.nix`'s `sansSerif` fontconfig default, and no
package providing it was ever installed by anything). Also moved
`fonts.nix` to `composition.nix`'s universal imports (same pattern as the
Phase 3 opener/clipboard/ai-apps fix) since `niri-noctalia.nix` - itself
universal - now needs to set `features.fonts.required` regardless of which
context is active. Verified this resolves correctly (`[ inter-4.1 ]` when
niri-noctalia is enabled, `[]` when it isn't) across chromaden (real),
a synthetic `profile = "work"` + `compositor = "niri"` config, and a
synthetic no-compositor config.

**What Phase 9 deliberately did NOT do**: flip `features.fonts.enable` to
`true` anywhere. Doing so would be a new, visible, live-system-affecting
default (actually installing the nerd-fonts/Inter packages via Nix and
turning on `fonts.fontconfig`'s `defaultFonts`, which could shift actual
font rendering on the next login/app restart) that goes beyond the literal
"wire up `fonts.required`" scope - and the current accidental pacman-driven
state has clearly been working fine for the user's daily use. **Needs an
explicit user decision**: (a) leave `features.fonts.enable` off forever
(fonts stay an alien/pacman-managed concern, `features.fonts.required`
becomes moot dead weight even though now "wired"), or (b) turn it on
(priv.nix, presumably) so dots/Nix actually manages fonts declaratively
going forward, understanding it's a live-affecting change worth a
dedicated `apply-dots` checkpoint rather than folding it silently into
Phase 9.
