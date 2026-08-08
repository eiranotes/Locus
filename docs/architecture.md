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
- surroundings classifier;
- step ledger;
- recipe/crafting engine;
- placement validator;
- environment grid;
- connection graph;
- visitor evaluator;
- seeded visual descriptor.

## Diorama renderer

The renderer uses a fixed logical 360×360 scene and 5×5 2:1 isometric tiles. The current prototype draws coherent primitives. Production atlases can replace individual drawing functions without altering placement, visitor, or crafting rules.
