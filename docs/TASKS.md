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
- [ ] Replace the fixed umbrella icon in the home visitor target with the
      actual visitor identity and count unique visitors rather than sightings.

## Deferred release work

- [ ] Production object/visitor atlas and frame animation after G2 geometry is
      stable.
- [ ] WeatherKit App ID/profile activation and physical-device verification.
- [ ] Store product identifiers, analytics gates, backup/import UI, widgets,
      high-resolution sharing, and device accessibility/battery/thermal audit.
