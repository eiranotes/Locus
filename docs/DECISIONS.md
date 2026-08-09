# Decisions

## 2026-08-09

### Product identity is Locus

User-visible runtime strings, iOS bundle display/name metadata, and the native
launch transition use Locus. Existing internal package names and the bundle ID
remain unchanged in this slice to avoid an unrequested storage/provisioning
migration.

### Simulator checks use deterministic demo gateways

`DEMO_MODE=true` is the supported offline simulator path. It uses deterministic
weather, location, surroundings, and steps, and must not ask for real Bluetooth
or Motion permissions. Production gateways and in-context permission timing are
unchanged. Demo state is stored in `reality_diorama_demo.sqlite3`, separate from
the production database, so synthetic materials and steps cannot leak into a
normal launch.

### SQLite WAL uses the package API

Database startup calls `Database.setJournalMode('WAL')`. Executing the pragma
directly during sqflite `onConfigure` failed on the audited iOS simulator.

### Object visuals have one deterministic contract

Home, crafting, inventory, and codex use `ObjectVisualDescriptor` and
`DeterministicObjectRenderer`. Seeded variations use named stable-seed channels
and remain inside fixed placement silhouettes. Capture time selects a palette;
crafting preview and the created object share one seed function. New objects use
`object-v2`, while `object-v1` bypasses new detail channels to preserve existing
collectibles.

### Generated static art is now the primary renderer input

The owner explicitly approved moving beyond prototype geometry. A fixed v1
package of 42 generated sprites now supplies crafted objects, visitors, fixed
scenery, material emblems, and weather/time effects. Generation happens only at
authoring time: sources, exact prompts, crop rules, output dimensions, alpha
contract, and SHA-256 hashes are tracked. Locus never generates artwork at
runtime. Deterministic Canvas geometry remains available for construction state
and asset-load failure, preventing saved objects from becoming unreadable.

The AppIcon remains a separate review candidate outside `AppIcon.appiconset`.
Launch continues to use a solid native background rather than generated splash
art.

### Application dependencies are locked

Locus is an application rather than a reusable Dart package, so the generated
`pubspec.lock` is retained to keep local and CI package resolution reproducible
with Flutter 3.44.9.

### Placement presentation is catalog-driven

`assets/content/placement_catalog.json` is the editor-facing contract for every
recipe's four directions and directional art. Gameplay dimensions and effects
remain in `recipes.json`; the placement catalog must cover the recipe set
exactly once. Each direction points to an independent production PNG from the
40-asset directional package. The four views are authored quarter-turn redraws,
not runtime mirrors, so asymmetric openings, backs, signs, and approaches remain
spatially truthful. Source atlases, reviewed row bounds, contact sheet, alpha
processing, and hashes are retained as a reproducible authoring contract.

Board selection fills, valid-anchor markers, connection emphasis, and direction
controls remain code-rendered. They are stateful interaction feedback rather
than collectible art and must scale cleanly with layout and accessibility.

All editor actions query the same `PlacementEngine` validation used by commits.
Invalid moves and rotations are disabled before mutation, selected footprints
and valid anchors are visible on the board, and only connections involving the
selected object remain emphasized. Direct drag is deferred until coordinate,
gesture-cancellation, and accessibility behavior can be tested together.
