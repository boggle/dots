# Open Questions / Parking Lot

Unresolved items that need the user's input. Move items here when raised;
remove (or compress to a one-liner below) once resolved - full rationale
for every resolution lives in `decisions.md`, dated.

---

## Currently open

### Platform/OS detection follow-up candidates
The consolidation these were meant to plug into now exists
(`config.core.platformBackend`, `modules/core/platform.nix` - see
`decisions.md` 2026-07-19). `network.nix` (ssh-agent socket path differs
on macOS) and `viewer.nix` (image viewer choice may need a macOS-specific
path) could read it directly whenever they're actually wired up.
Deliberately not done yet: no macOS host to validate against, no
concrete logic drafted for either. Revisit if/when a real need emerges.

---

## Resolved/closed (kept as a one-line index - see `decisions.md` for full detail)

- **Flake output naming** → `default`/`default-opt` (Phase 2).
- **`psutils`/`t3`** → removed, mislabeled (core-minimization round).
- **Pagers/HTTP fetchers overlap** (`moor`/`ov`/`less`, `curl`/`wget`/
  `curlie`) → confirmed intentional, kept as-is.
- **Debian support scope** → extended for the 4 suites the user's real
  bookworm machine needs (`sixel-tools`/`cloud-tools`/`dev-tools`/
  `ai-apps`); `gui-apps`/`pim-apps`/`scanning`/`niri-noctalia`/`opener`/
  `llama-cpp` still uncovered, not requested yet.
- **`location` axis** → still an inert freeform tag, no concrete use case
  yet; revisit if one emerges.
- **`noctalia-qs` "non-existent input" warning** → root-caused (upstream
  never declared that input) and removed.
- **`sync.sh`/`setup.sh` deeper improvements** → substantially done
  across several rounds (named syncables, `-g` flag, ssh-assertion fix,
  real template files); no broader redesign currently planned.
- **`barch`** → still unused, kept for forward-compat at zero cost;
  revisit if a concrete need emerges.
- **`features.fonts.enable`** → left off for now (user's explicit call);
  `fonts.required` wiring itself is correct and inert until enabled.
- **`.feature` key in alien-spec files** → removed (never consumed,
  shadowing already works via package-name matching); replaced with real
  alien-spec conflict detection instead.
