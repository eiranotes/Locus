# Tasks

## Completed

- [x] Reproduce iOS simulator install and startup from the imported `main`.
- [x] Fix missing `CFBundleExecutable` and sqflite WAL startup failure.
- [x] Align runtime and iOS display identity with Locus.
- [x] Bypass real Bluetooth/Motion permission requests in deterministic demo
      mode without changing production permission behavior or data.
- [x] Verify capture → craft → auto-place → move → relaunch persistence on an
      iOS simulator.
- [x] Share one deterministic object renderer across home, crafting,
      inventory, and codex surfaces, including capture-time palettes and v1
      collectible compatibility.
- [x] Ask the Locus Pro conversation to review the next slice and generate one
      AppIcon candidate from a recorded production prompt.
- [x] Generate and install the first complete object, visitor, scenery,
      material, and atmosphere art package with prompt/source/hash provenance.
- [x] Use generated sprites across the home scene, crafting, inventory, codex,
      visitor goal, and materials while preserving deterministic fallbacks.

## Next

- [x] Add selected-footprint highlighting, valid anchor markers, relevant
      connection emphasis, and disabled invalid move/rotation actions.
- [x] Move placement directions and artwork variants into an exact recipe
      catalog with exhaustive four-direction and boundary tests.
- [x] Generate, process, and catalog true four-direction sprites for all ten
      placeable objects with source/hash/contact-sheet provenance.
- [x] Generate and catalog three recipe-specific construction stages for every
      recipe and use them in projected crafting and incomplete-object previews.
- [x] Generate and catalog the bounded 12-asset shared weather-treatment pack.
- [x] Replace linear placement arrows with a 48 dp isometric direction pad and
      expose selected state on material/object catalogs.
- [x] Keep stored and in-progress objects in the placement catalog so removed
      objects can select a direction and return to a validated empty cell.
- [x] Centralize alpha-clipped sprite composition and apply the cataloged
      weather surface/footprint layers identically across every object surface.
- [x] Catalog and persist up to two provider-neutral atmospheric traces per
      material, let each recipe retain at most one compatible focus, and apply
      anchor-based environment/connection modifiers without a new permission.
- [ ] Tune atmospheric thresholds and focus effects after a structured
      eight-object playtest; do not add more trait families first.
- [ ] Make home scene-first, derive scene visitors from persisted sightings,
      and add a semantic scene summary.
- [ ] Derive the scene visitor from persisted sightings while keeping the
      one-time arrival dialog transient.
- [ ] Add an integration test for the deterministic demo core loop.
- [ ] Add place-plaque treatment and route future share output through the same
      object renderer.
- [ ] Review the AppIcon candidate at 1024, 180, 60, and 29 pt; either approve
      it or request one focused revision before wiring wrapper generation.
- [ ] Count unique visitors rather than sightings in the home visitor target.
- [ ] Tune sprite scale and occlusion against neighborhoods containing the full
      eight-object limit and validate large-text card layouts.
- [ ] Add direct drag-to-cell manipulation after Flame/Flutter coordinate and
      accessibility behavior has a tested contract.
- [ ] Add target-visitor condition deltas for proposed placements.
- [ ] Add compact/medium/expanded layout policies and large-text fallbacks for
      records, visitors, material pickers, and the placement catalog.

## Deferred release work

- [ ] Frame animation and expanded scenery variants after the static v1 atlas
      composition is approved.
- [ ] WeatherKit App ID/profile activation and physical-device verification.
- [ ] Store product identifiers, analytics gates, backup/import UI, widgets,
      high-resolution sharing, and device accessibility/battery/thermal audit.
