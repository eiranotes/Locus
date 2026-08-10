# Locus — Reality Collection Diorama v6

## Product definition

Locus is a local-first iOS and Android game that turns a brief real-world capture into materials for a small pixel diorama.

> Collect the current weather and optional surroundings, use recent steps as crafting work, build miniature neighborhood objects, and arrange them to discover visitors and new recipes.

The product is not a sensor dashboard. Sensors are useful only when their meaning survives into a visible object and a repeatable game rule.

## Core loop

```text
steps accumulate
→ weather / surroundings become ready
→ capture now or leave them ready
→ retain each input pattern and any simultaneous-input combination pattern
→ use immediately or store
→ choose a recipe
→ spend one weather material, optional surroundings material, and steps
→ complete or continue constructing an object
→ place and rotate it on the 5×5 diorama
→ satisfy environment / connection / height conditions
→ discover a visitor, recipe, variant, or scene element
→ collect again for a desired scene
```

The user should need to understand only six verbs: collect, store, craft, place, complete, discover. Patterns are collection results, not another required verb.

## Product boundaries

First release:

- Flutter application for iOS 18+ and Android API 26+;
- local SQLite state;
- no account or developer-operated server;
- no ads, subscription, social graph, exchange, or live competition;
- one 5×5 diorama with at most eight active objects;
- one non-consumable Lifetime purchase after the loop is validated;
- WeatherKit on iOS and an adapter-based weather provider on Android;
- steps through CMPedometer on iOS and installation-forward step-counter evidence on Android;
- optional explicit foreground Bluetooth scan;
- no camera and no background microphone.

Not promised:

- counting nearby people;
- identifying phones or accessories;
- background BLE crowd scanning;
- exact point-level weather observation;
- buying steps, cooldown reductions, retries, materials, or visitor odds;
- generated artwork at runtime.

## Resource economy

### Steps

Steps are crafting work, not a fictional currency. Recent available steps are stored in day buckets and spent oldest-first. A small object costs roughly 1,200–1,800 steps, medium 2,400–3,500, and large 4,500–7,000.

When the available amount is insufficient, crafting creates a visible construction state. Later step synchronization advances the same object. Only one construction may be active in the MVP.

If motion evidence is unavailable, the user can explicitly select a 2,000-unit daily work allowance. Switching sources preserves spent work but does not carry unused work between sources.

### Weather material

Weather determines object material, palette, local environment effects, and provenance.

Initial broad classes:

- clear: brightness and warmth;
- rain: wet surfaces and wet cells;
- cloudy/foggy: cool, low-contrast surfaces;
- windy: directional details and wind cells;
- cold/snow: frost and cool cells;
- warm: warm surfaces and warm cells.

Default cooldown is two hours. A meaningful weather-class or time-band change can make it ready after the minimum interval. A ready material remains ready until collected.

Weather data is provider model data. UI language must not claim direct measurement at the exact location.

Each collected weather material may also keep zero to two cataloged
atmospheric traits derived only from numeric fields shared by both weather
providers: visibility, precipitation rate, cloud cover, wind speed, and
apparent temperature. The six first-release traits are low visibility, active
precipitation, strong wind, sharp cold, intense heat, and deep cloud. Priority
and thresholds are versioned in `atmospheric_traits.json`; classification is
deterministic and collection cooldown still keys off the broad class and time
band, so changing a secondary trait cannot be used to reroll materials.

### Surroundings material

Surroundings are optional and collected only through a foreground 8-second Bluetooth scan. Native code aggregates density, persistence, churn, relative signal strength, and observation coverage. It discards names, peripheral identifiers, MAC addresses, and raw advertisements.

Initial classes have equal value but different placement functions:

- dense: connects several nearby objects;
- dynamic: passes effects in sequence;
- stable: keeps one connection or effect active;
- sparse: connects one distant object.

The system never labels the result as a crowd count. If the channel cannot be distinguished from shuffled evidence during validation, it is removed without breaking the game.

## Crafting

A recipe is selected before materials. The initial visible recipes are alley lamp, planter, bench, and stairs. Additional recipes unlock through deterministic visitor rewards.

```text
recipe + one weather material + optional surroundings material + steps
= crafted miniature object
```

The weather material is required. Surroundings are optional; without one, the object uses a basic adjacent effect. Capture records remain permanently visible after their consumable materials are used.

Visual generation is deterministic:

```text
base object
+ weather skin
+ one selected atmospheric focus trait
+ time palette
+ connector treatment
+ place plaque
+ construction / complete state
```

The same renderer must be used for crafting preview, inventory, codex, diorama, and future sharing.

## Diorama rules

- fixed 2:1 isometric camera;
- logical 360×360 scene;
- 5×5 placement grid;
- objects occupy 1×1 or 1×2 cells;
- four rotations;
- maximum eight active objects;
- fixed background architecture in the MVP;
- only crafted objects are movable.

The game computes three rule families.

### Environment

Wet, light, warm, cool, wind, and nature values are accumulated per cell.
Objects affect their own and adjacent cells. One user-selected atmospheric
focus may add a bounded catalog effect to diagonal, adjacent, or distance-two
cells from the placement anchor. This makes captured conditions affect a
placement decision without creating another currency or multiplying art files.

### Connections

Objects become graph nodes. Edges are adjacent, dense, sequential, stable, or far, based on placement and the optional surroundings material.

### Height

Objects expose low, medium, or high placement properties. Users do not manipulate raw altitude numbers.

Visitor requirements have no more than three visible conditions. A first discovery occurs deterministically as soon as the conditions are satisfied. Repeated visits use a six-hour interval and predefined reward order, not loot odds.

## Initial content cap

```text
weather classes       6
surroundings classes  4
recipes               10
initial recipes        4
visitors                6
grid                  5×5
active objects          8
scene themes            1
time palettes           3
weather overlays        4
```

New MVP ideas must replace an existing item rather than expand this cap.

## Primary screens

### Home / diorama

The diorama occupies roughly 60–70% of the screen. The header shows available steps and ready captures. Only one primary goal is shown, such as “one more wet cell needed.” Construction and visitors are visible in the scene.

### Capture

The sheet shows only ready channels. Weather resolves immediately. The optional surroundings scan shows one 8-second progress state and explains that it does not count people or store devices. Results are saved before “craft now” or “store” is chosen.

### Inventory

Three sections: records, usable materials, crafted objects. Record thumbnails are deterministic compositions, not one-off generated illustrations.

### Crafting

Recipe first, then weather material, optional surroundings material, step requirement, and a deterministic preview. Insufficient steps starts construction instead of failing.

### Placement editor

Select an object, move it one cell at a time, rotate, inspect, or return it to storage. Only relevant cells, connections, or visitor conditions are highlighted.

### Codex

Visitors, crafted object families, and recipes. Undiscovered visitors show directional hints rather than only “???”.

## Art direction

- soft pixel/dot aesthetic;
- consistent 2:1 isometric projection;
- miniature streets, gardens, stops, windows, lamps, stairs, and bridges;
- dark navy base with daytime, evening, night, rain, snow, and fog palettes;
- one fixed pixel scale and one light direction;
- limited local glow;
- native Korean text, not baked pixel text;
- collection marks use hard-edged code-rendered pixels and reflect the actual
  time, weather, and surroundings inputs rather than a generic network icon;
- no production use of fragments cut from exploratory concept screens;
- authoring-time generated sprites require an explicit inventory, shared atlas
  contract, transparent outputs, recorded prompts/sources, and deterministic
  runtime fallbacks.

The static v1 art package passed the initial shared-renderer gate and replaces
prototype primitives on primary surfaces. Canvas geometry remains the
construction and asset-load fallback. The application never generates artwork
at runtime.

## Privacy and provenance

Stored:

- coarse location cell and optional user label;
- classified weather evidence and provider/version;
- derived individual and simultaneous-combination pattern keys, labels,
  strength, component keys, and classifier version;
- day-level observed/spent step buckets;
- aggregate surroundings features and confidence;
- recipe/generator versions;
- captures, materials, objects, placements, visitors, unlocks.

Not stored:

- routes or continuous location history;
- Bluetooth identifiers, names, MAC addresses, or raw advertisements;
- camera images or audio;
- high-frequency motion streams.

## Monetization hypothesis

Free users must complete collection → crafting → placement → first visitor. Lifetime may unlock larger record retention, all base recipes/visitors, saved layouts, place history, high-resolution sharing, and export/restore.

Never monetize cooldowns, steps, collection attempts, retries, materials, connection results, or visitor probability.

## Validation gates

### G0 — technical capture

- basic capture succeeds at least 95%;
- no negative or duplicate step balance;
- capture completes within ten seconds;
- weather failure and BLE absence do not block existing gameplay.

### G1 — resource meaning

- weather variants are visually distinguishable;
- real surroundings evidence beats removed/shuffled evidence;
- permissions are justified by a visible gameplay difference.

### G2 — diorama quality

- four objects, three weather variants, two visitors, placement and conditions;
- weather variants can be recognized from screenshots;
- adding an object clearly improves scene satisfaction;
- 393pt phones render the diorama clearly;
- share intent reaches the internal 30% gate.

### G3 — core loop

Internal continuation thresholds:

- second voluntary capture within 48 hours: 40%;
- capture on three separate days in week one: 20%;
- crafting completion: 50%;
- placement change: 35%;
- return to check visitor: 25%;
- save/share scene: 10%.

These are product stop/continue hypotheses, not claimed industry benchmarks.

## Definition of done

- capture result is automatically saved;
- first object can be crafted within five minutes;
- construction advances without duplicate step spending;
- placement visibly changes environment or connections;
- visitor requirements are understandable and deterministic;
- at least one visitor is reachable on day one;
- weather/step/BLE failures are fail-closed and recoverable;
- the complete loop works without Bluetooth;
- Android debug and iOS simulator builds pass CI;
- the same visual seed reproduces the same object;
- migrations and content reachability are tested;
- the first store screenshot communicates both real-world provenance and the finished diorama.
