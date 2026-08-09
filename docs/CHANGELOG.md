# Changelog

## Unreleased

### Fixed

- iOS simulator installation now has valid executable bundle metadata.
- iOS cold launch no longer stops on a direct WAL pragma in sqflite.
- Deterministic demo capture and crafting no longer request unavailable real
  Bluetooth or Motion permissions.
- Demo steps initialize to the deterministic 4,275-unit source.
- Deterministic demo data now uses its own SQLite database and cannot affect a
  production-mode launch.
- Compact codex cards and the crafting detail preview retain usable layout at
  narrow widths and larger text sizes.

### Changed

- User-visible app identity is Locus.
- Capture uses a surroundings/sensor glyph instead of a camera glyph.
- Home, crafting, inventory, and codex object visuals share deterministic
  geometry, weather and capture-time palettes, connector marks, construction
  state, and `visualSeed` detail channels.
- New crafts use the `object-v2` visual contract while saved `object-v1`
  collectibles retain their previous geometry.
- Native launch background generation uses Locus navy `#071522`.
- Added `pubspec.lock` so application dependency resolution is reproducible.

### Assets

- Added one normalized Pro-generated AppIcon candidate and its complete prompt.
  It is intentionally not selected as the shipping icon yet.
