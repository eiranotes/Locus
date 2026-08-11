# 2026-08-11 grid-anchor UI proof

This directory contains the complete deterministic iOS UI tour captured on the
`AppAudit iPhone 16 Pro` simulator after the placement ground-anchor correction.

- `07-placement.png` proves a sparse 1x1 object bottom is attached to the
  selected cell's front vertex.
- `15-placement-dense.png` proves the eight-object scene keeps natural
  footprint-aware depth while the dragged tower persists at cell `(3, 3)`.
- The remaining images retain the full primary-flow regression evidence from
  home through capture, crafting, inventory, codex, and settings.

Verification for this capture: `./tool/validate.sh` passed all 100 unit/widget
tests, the iOS deterministic drive passed all four integration checks, and the
required demo Android debug APK build completed successfully.
