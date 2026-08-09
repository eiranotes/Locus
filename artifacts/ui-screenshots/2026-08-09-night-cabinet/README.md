# Locus Night Cabinet UI screenshot tour

Captured on 2026-08-09 from the deterministic demo integration tour after the
Night Cabinet UI review and redesign.

- Device: AppAudit iPhone 16 Pro, iOS 26.5 simulator
- Simulator UDID: `AF3F5D7C-00EA-4AEE-9268-84BEE844DD61`
- Flutter: 3.44.1 (repository pin remains 3.44.9)
- Build: Debug iOS Simulator, `DEMO_MODE=true`
- Resolution: 1206×2622 PNG
- Result: capture → craft → auto-place → inventory → codex → settings passed

## Screens

1. `01-home.png` — scene-first home and in-scene actions
2. `02-capture-ready.png` — weather and surroundings sensor trays
3. `03-capture-result.png` — persisted material result
4. `04-crafting-list.png` — borderless workbench recipe list
5. `05-crafting-detail.png` — object stage and material choices
6. `06-crafting-complete.png` — deterministic completion artwork
7. `07-placement.png` — scene and compact control dock
8. `08-inventory-records.png` — record drawer
9. `09-inventory-materials.png` — material rows
10. `10-inventory-objects.png` — crafted-object rows
11. `11-codex-visitors.png` — visitor silhouettes and hints
12. `12-codex-objects.png` — deterministic object silhouettes
13. `13-codex-recipes.png` — recipe index
14. `14-settings.png` — grouped settings and privacy information

`contact-sheet.png` is the labeled overview. The visual review checked every
full-resolution screen for hierarchy, repeated container treatment, clipped
content, framework exceptions, and the former generic floating-center action.
No blocking visual defect remained in this simulator route. Larger text,
compact/expanded layouts, eight-object neighborhoods, and physical devices
remain separate verification gates.
