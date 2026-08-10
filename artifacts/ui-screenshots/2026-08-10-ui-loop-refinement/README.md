# Core-loop UI refinement tour

This folder contains the deterministic iOS integration tour captured on the
existing `LocusPlacementQA` iPhone 16 Pro simulator with
`DEMO_MODE=true`. The tour passed from capture through crafting, direct
placement, inventory, codex, and settings.

`02-capture-ready.png` shows the optional surroundings control and explicit
eight-second foreground scan. `03-capture-result.png` shows the user-facing
result: one provider-neutral surroundings class and confidence. Because this
tour uses `DemoAmbientScanner`, its `변화가 큰 주변 · 신뢰도 88%` result is a
deterministic fixture rather than physical Bluetooth evidence.

Production native scans aggregate only distinct-session count, median signal,
strong-signal ratio, persistence, churn, and observation coverage. Peripheral
names, identifiers, addresses, and raw advertisements never enter the Flutter
result or persistent database.

The 17 full-resolution PNGs are arranged in `contact-sheet.png`. Visual review
confirmed that the carried crafting context, safe-area craft action,
outcome-specific completion action, placement fine-adjustment labels, and
active-tab inventory counts remain visible without overflow at the captured
size.
