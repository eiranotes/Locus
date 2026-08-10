# Architecture

## Product loop

```text
recent steps accumulate
→ weather / optional surroundings become ready
→ capture now or keep the ready state
→ retain individual information patterns and bounded simultaneous combinations
→ spend a weather material, optional surroundings material, and steps
→ craft or continue constructing a miniature object
→ place and rotate it on a 5×5 isometric board
→ recompute environment cells and object connections
→ refresh readiness and evaluate one prioritized visitor predicate
→ unlock a visitor, recipe, visual variant, or scene element
→ retain repeat visits as coarse scene memories
```

## Cross-platform boundary

The domain layer never imports Flutter plugins. Platform-dependent features are interfaces:

- `WeatherGateway`
- `LocationGateway`
- `StepSource`
- `AmbientScanner`

Android and iOS bridges return normalized values. A platform failure produces an explicit unavailable state; it never manufactures a rare material.

## State and persistence

`AppController` is the single UI-facing state coordinator. `GameRepository` serializes all writes through one database boundary. Static content is versioned JSON; user state is SQLite. Cold launch and resume use one ordered refresh contract: steps/construction, passive capture preparation, then visitor evaluation. Passive preparation never requests location permission.

The domain engines are deterministic and independently testable:

- cooldown engine;
- weather classifier;
- cataloged atmospheric-trait classifier;
- surroundings classifier;
- collection-pattern engine;
- step ledger;
- recipe/crafting engine;
- placement validator;
- environment grid;
- connection graph;
- visitor evaluator;
- visitor selection policy;
- seeded visual descriptor.

## Collection patterns

`CollectionPatternEngine` receives only normalized weather data and aggregated
surroundings features after a channel has successfully produced a material. It
emits individually collectible context patterns and at most six combination
patterns for inputs collected in the same capture. Combination rows retain
derived component keys so their origin is inspectable without retaining raw
sensor observations.

SQLite schema v3 adds `collected_patterns`. `GameRepository.saveCapture`
inserts the capture, optional materials, and all pattern occurrences in one
transaction, and deleting a capture cascades to its pattern rows. The inventory
aggregates rows by stable `pattern_key` for unique-pattern and repeat-count UI;
the underlying occurrences remain available for future progression rules.

Time and representative-weather patterns are also presentation evidence for
matching visitor requirements. They are never consumed, never satisfy a
predicate on their own, and never become a currency or recipe gate.

`pattern_presentation.dart` resolves each combination into a short title,
summary, component count, and normalized visual-family list. Capture and
inventory pass that same descriptor to `PixelWeaveMark`, whose non-antialiased
10×10-grid painter uses fixed time, weather, and surroundings source slots.
Same-family component lists deliberately retain duplicates, allowing a channel
weave to paint differently from a mixed scene without adding bitmap assets or
duplicating key parsing in screen widgets.

## Visitor return history

SQLite schema v4 keeps `visitor_sightings` as the latest per-visitor summary and
adds append-only `visitor_encounters` for repeat scene memories. Each row keeps
only visit time, a coarse weather/time variant, placed object IDs, and the
existing bounded snapshot JSON. `GameRepository.saveVisitorResolution` writes
the latest sighting, encounter, and unlock metadata in one transaction.
Controllers query grouped encounter counts; detail consumers use a five-row
recent-history limit rather than loading the full visit log.

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
