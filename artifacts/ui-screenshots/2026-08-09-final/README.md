# Locus iOS UI screenshot tour

Captured on 2026-08-09 from the deterministic demo integration tour.

- Device: AppAudit iPhone 16 Pro, iOS 26.5
- Simulator UDID: `AF3F5D7C-00EA-4AEE-9268-84BEE844DD61`
- Flutter: 3.44.1 (repository pin remains 3.44.9)
- Build: Debug iOS Simulator, `DEMO_MODE=true`
- Resolution: 1206×2622 PNG
- Result: demo capture → craft → auto-place → full UI tour passed

## Screens

1. `01-home.png` — scene-first home
2. `02-capture-ready.png` — capture readiness and privacy copy
3. `03-capture-result.png` — persisted weather and surroundings result
4. `04-crafting-list.png` — unlocked recipes
5. `05-crafting-detail.png` — shared object preview and material choices
6. `06-crafting-complete.png` — completion confirmation
7. `07-placement.png` — isometric placement editor
8. `08-inventory-records.png` — capture records
9. `09-inventory-materials.png` — collected materials
10. `10-inventory-objects.png` — crafted objects
11. `11-codex-visitors.png` — visitor codex
12. `12-codex-objects.png` — object codex
13. `13-codex-recipes.png` — recipe codex
14. `14-settings.png` — settings, privacy, and provider state

`contact-sheet.png` is the labeled overview. A conditional first-arrival dialog
uses the `06b-visitor-arrival.png` name when the exercised route naturally
unlocks one; this one-object route did not, so no synthetic arrival state was
captured.
