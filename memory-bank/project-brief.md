# Project Brief: dots Re-architecture

Status: **Active** | Started: 2026-07-18

## Why

The current setup (two-repo: `dots` shared + `dots-local` private, with a
`common -> priv/work -> hosts/<name>.nix` profile-inheritance hierarchy) has
been used long enough in practice to expose real limits:

- `dots` is manually copied via GitHub to several machines with quite
  different contexts (personal desktop, personal laptop, WSL2, work). Machines
  are not always connected, leading to stale copies and painful merges.
- Two GitHub remotes already exist (`origin` = personal `boggle/dots`,
  `other` = work `spmsft/dots`) both historically merged into the same
  `main`, which is exactly the kind of cross-context conflict we want to stop
  causing.
- The profile/host-directory model requires a real committed file to exist
  per host, which has already produced drift and bugs (broken `work` profile,
  a silent `features.scanning` vs `suites.scanning` typo on laputa, duplicated
  host-specific data instead of parametrized config, copy-pasted header
  comments, etc.)
- Picking/configuring features is coarse (one profile string + one host file)
  instead of reflecting the real multi-axis nature of a machine: hardware,
  distro/WSL-ness, work/priv context, identity, physical/network location.

## Vision

- `dots` contains **zero local/host state**. It is pure shared, mergeable
  code: modules, features, suites, composition rules. Git branch/checkout
  strategy across machines is the user's call, not something this project
  designs around — `dots` just needs to be branch/merge-friendly *by
  construction*.
- All local/private/per-machine state lives in `dots-local`, described via a
  formal multi-axis schema (hardware, distro/WSL, context, identity,
  location, ...). `dots` ships the schema + a template so bootstrapping a new
  machine or adopting a new feature is easy and self-documenting.
- Feature/suite selection is driven by **simple, explicit dependency rules**
  over those axes (e.g. "if AI-capable GPU present, pull in AI suite"),
  instead of static per-host imports.
- A brand-new machine can get a **minimal, fast** environment running with
  minimal downloads, then progressively opt into more via axes.
- All existing subsystems are preserved: alien (native) package management
  (gaining Debian support), AppImages (host-local + shared), the 3-scope
  package tuning system, the settings-sync system, the niri-noctalia desktop,
  llama-cpp, butterfish, the AI-apps suite, all GUI/TUI/PIM/scanning/sixel
  suites, dev-tools, cross-platform clipboard/opener/viewer (Linux Wayland/X11
  + WSL2 + macOS), fonts, sd-switch, and the nixon shell-bootstrap mechanism
  (kept, just retargeted to `.bashrc-nix`/`.profile-nix`).
- Where duplication/drift has crept in (tuning defaults defined 3-4x, two
  independent alien-package discovery engines, repeated enable-flag/package
  boilerplate in every suite, OS-backend enums repeated per feature), we
  consolidate to a single source of truth.
- Known concrete bugs get fixed along the way (bundled into the relevant
  phase, not deferred).

## Constraints / Non-Goals

- Branch/repo topology across machines is explicitly **out of scope** for
  this project — "every machine has its own checkout", managed by the user.
  Our job is just to make `dots` itself free of embedded local state.
- `apply-dots`/`update-dots`/`dots-sync`/`update-alien-packages`/
  `appimage-update` naming stays as-is (well-established); only the
  `install-<x>`/`uninstall-<x>` imperative-installer scripts (llama-cpp, pi,
  graphify) get renamed to a `setup-<x> {install|remove|update}` convention.
- `sync.sh`/`setup.sh` improvements are explicitly deferred ("stash for
  later") except where directly required by other changes (e.g. the
  dots-local template must stay in sync with the schema).
- Core CLI tool list gets reviewed for trims, but **non-aggressively** — the
  user actively uses the "modern CLI / rust rewrite" tools and wants to keep
  them; only genuinely mislabeled/redundant/accidental inclusions are trim
  candidates, and only after confirmation.
- Debian alien-package support is added structurally (spec convention + apt
  backend + CLI-feature specs) but cannot be runtime-verified until there's
  an actual Debian machine — this is a known, explicitly-flagged gap, not a
  false "done".

## Success Criteria

- `nix eval`/`nix build` succeeds for every phase before moving to the next.
- No existing feature regresses (see `preserved-features-checklist.md`).
- A new machine (or a new feature on an existing machine) can be onboarded by
  editing only `dots-local` (schema-driven), without touching `dots` in the
  common case.
- Live-switch checkpoints (via `apply-dots` on chromaden, the daily driver)
  pass at each flagged milestone.
- The memory bank (`memory-bank/*.md`) stays current across sessions so any
  agent (or the user) can resume this project without re-deriving context.

## Key References

- `AGENTS.md` — repo-wide agent guide (revised to point here)
- `memory-bank/architecture.md` — target design detail
- `memory-bank/plan.md` — phase-by-phase execution tracker
- `memory-bank/decisions.md` — decision log with rationale
- `memory-bank/preserved-features-checklist.md` — regression checklist
- `memory-bank/learnings.md` — gotchas discovered while executing
- `memory-bank/open-questions.md` — unresolved items
