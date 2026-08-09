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

- [ ] Add valid/invalid footprint highlighting and target-visitor condition
      deltas to placement editing.
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

## Deferred release work

- [ ] Frame animation and expanded scenery variants after the static v1 atlas
      composition is approved.
- [ ] WeatherKit App ID/profile activation and physical-device verification.
- [ ] Store product identifiers, analytics gates, backup/import UI, widgets,
      high-resolution sharing, and device accessibility/battery/thermal audit.
