# Project status

Last updated: 2026-08-09

## Current state

`main` at `41c8b79` contains the iOS simulator launch fixes, Locus identity
cleanup, deterministic demo isolation, and shared deterministic object-rendering
contract. The current slice replaces the visibly provisional runtime art with a
production-bound generated pixel-art package while retaining Canvas fallbacks.

## Completed in the current slice

- Added missing iOS executable metadata and changed user-visible identity from
  Reality Diorama to Locus.
- Changed the native launch background patch to `#071522` to avoid a white
  transition before Flutter paints its first frame.
- Replaced the failing direct SQLite WAL pragma with sqflite's supported
  `setJournalMode('WAL')` helper.
- Made `DEMO_MODE=true` use deterministic steps and capture inputs without
  requesting Bluetooth or Motion permissions on the simulator, and isolated
  demo progress from the production SQLite database.
- Replaced the capture camera glyph; Locus does not use the camera.
- Extracted one deterministic object descriptor/renderer used by the home
  scene, crafting, inventory, and codex. Crafting preview and saved objects now
  share the same `visualSeed` derivation and capture-time palette. New objects
  use `object-v2`; persisted `object-v1` collectibles keep their legacy shape.
- Generated one Pro-model AppIcon candidate and normalized it to an opaque
  1024 × 1024 sRGB PNG. It remains unselected and is not wired into iOS assets.
- Generated, keyed, cropped, and installed 42 production-bound pixel assets:
  10 crafted objects, 6 visitors, 8 scenery pieces, 10 material emblems, and 8
  weather/time overlays.
- Connected the generated art to the home diorama, object previews, inventory,
  codex, visitor goal, and material UI. The deterministic renderer remains the
  construction-state and asset-load fallback.
- Added reproducible prompt/source provenance, an exact manifest with SHA-256
  hashes, and a standard-library validation gate for the generated package.

## Simulator evidence

Verified on `AppAudit iPhone 16 Pro`, iOS 26.5, UDID
`AF3F5D7C-00EA-4AEE-9268-84BEE844DD61`, using Flutter 3.44.9 and
`--dart-define=DEMO_MODE=true`:

1. install and cold launch;
2. capture opens without Bluetooth/Motion permission alerts;
3. deterministic rain and surroundings material is collected;
4. an alley lamp consumes 1,500 of 4,275 steps and auto-places;
5. the lamp moves one grid cell and commits;
6. force termination and relaunch restore 2,775 steps, the object, and its
   placement.

The simulator run also confirmed that placement currently lacks valid-cell
highlighting and target-visitor condition deltas.

After the shared-renderer and review fixes, the final local gate used Flutter
3.44.9: repository/content/manifest/Swift checks passed, `flutter analyze`
reported no issues, all 38 tests passed, and the Debug iOS simulator build
installed and cold-relaunched successfully. The fresh demo home showed 4,275
steps, and the simulator container contained a separate
`reality_diorama_demo.sqlite3` with its own unspent bucket.

The generated-art slice was then verified with the same pinned SDK: the exact
42-asset manifest passed, `flutter analyze` reported no issues, all 39 tests
passed, and a Debug iOS simulator build installed and launched. The final home
capture shows the generated house, tree, bench, fence, path, atmospheric layer,
and visitor portrait; excessive daytime overlay noise was removed after the
first visual pass.

## Known risks and gates

- The first production-bound atlas pass is installed, but it still needs final
  composition tuning against a range of populated neighborhoods and text sizes.
- Place plaques and a share-output renderer remain outside this first shared
  renderer slice.
- Visitor scene persistence still depends on transient arrival state rather
  than persisted sightings.
- Placement feedback and rotation/footprint validation need a dedicated slice.
- The AppIcon candidate requires owner review at actual icon sizes before use.
- Wrapper bootstrap remains mutating and must use exactly Flutter 3.44.9; the
  audit machine's global SDK was 3.44.1.
- WeatherKit provisioning, signing, Store products, physical-device permission
  behavior, accessibility, battery, and thermal checks remain release gates.
