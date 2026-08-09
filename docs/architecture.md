# Architecture

## Product loop

```text
recent steps accumulate
→ weather / optional surroundings become ready
→ capture now or keep the ready state
→ spend a weather material, optional surroundings material, and steps
→ craft or continue constructing a miniature object
→ place and rotate it on a 5×5 isometric board
→ recompute environment cells and object connections
→ satisfy a visitor predicate
→ unlock a visitor, recipe, visual variant, or scene element
```

## Cross-platform boundary

The domain layer never imports Flutter plugins. Platform-dependent features are interfaces:

- `WeatherGateway`
- `LocationGateway`
- `StepSource`
- `AmbientScanner`

Android and iOS bridges return normalized values. A platform failure produces an explicit unavailable state; it never manufactures a rare material.

## State and persistence

`AppController` is the single UI-facing state coordinator. `GameRepository` serializes all writes through one database boundary. Static content is versioned JSON; user state is SQLite.

The domain engines are deterministic and independently testable:

- cooldown engine;
- weather classifier;
- cataloged atmospheric-trait classifier;
- surroundings classifier;
- step ledger;
- recipe/crafting engine;
- placement validator;
- environment grid;
- connection graph;
- visitor evaluator;
- seeded visual descriptor.

## Diorama renderer

The renderer uses a fixed logical 360×360 scene and 5×5 2:1 isometric tiles.
Production sprites are resolved through `placement_catalog.json`; each recipe
declares four independent directional PNGs. The directional package is built
from tracked source atlases and validated for exact recipe/rotation coverage,
distinct hashes, RGBA dimensions, and installed paths, so a later asset pack can
replace one direction without editor code changes. Deterministic Canvas geometry
remains the construction and load-failure fallback.

Completed `object-v3` visuals use one alpha-clipped compositor for the home
scene and Flutter previews. It resolves a directional recipe sprite, the
weather catalog's isometric footprint effect and surface pattern, time tint,
surroundings connector, and one bounded focus-trait layer. `object-v1` and
`object-v2` rows preserve their previous appearance; schema v2 adds versioned
weather-trait JSON plus nullable object focus and stable variant-key columns.

`PlacementEngine` is the single source for rotated footprints, bounds,
collisions, and valid anchors. The editor queries that engine before enabling a
move or rotation, then `AppController.placeOrMoveObject` repeats the same
validation before the repository transaction. The scene snapshot carries a
transient editor overlay only; selection and valid-cell hints are never stored.
