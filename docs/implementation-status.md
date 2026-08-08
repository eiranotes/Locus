# Implementation status

## Included in the current repository

- product architecture and versioned content definitions;
- SQLite persistence and transactional crafting/visitor resolution;
- cooldown and resource economy;
- explicit actual-step/fallback-step selection and native bridge contracts;
- iOS WeatherKit adapter and Android prototype HTTP weather adapter;
- production weather/location capture that fails closed;
- Android and iOS foreground BLE aggregation bridges;
- crafting/construction flow;
- 5×5 placement and visitor rules;
- pixel-style isometric prototype renderer;
- inventory, settings, and codex;
- tests, repository contracts, Android/iOS compile CI, and reproducible publish/archive helpers.

## Deliberately not represented as complete

- production pixel atlases and frame animation;
- Apple Developer portal App ID/profile activation for WeatherKit;
- Play Billing/App Store product identifiers;
- home-screen widgets and Android Quick Settings tile;
- production analytics and TestFlight/Play testing gates;
- backup/import UI;
- high-resolution share renderer implementation;
- accessibility, battery, and thermal audit on physical devices.

These are post-core-loop tasks in the v6 roadmap, not silent omissions.

## Capture and persistence hardening

- Production weather failures create no demo/fake material.
- Missing location does not call a provider and does not persist a fake Seoul cell.
- Surroundings-only capture remains available when weather is unavailable.
- Crafting, material consumption, step spending, and initial placement are committed in one SQLite transaction.
- Visitor sightings and their recipe/reward unlock metadata are committed in one SQLite transaction.
- Removing an incomplete placed construction keeps its `building` lifecycle in both memory and SQLite.
- Android BLE scanning is stopped on completion, scan failure, permission race, and activity destruction.
- Current-weather visitor requirements use only a confirmed current weather observation, not a stale stored material.
- Changing step sources preserves spent work but removes unused credit from the previous source.
- App resume and pull-to-refresh synchronize configured steps and advance construction.

## Platform weather status

- iOS: native WeatherKit current weather and attribution method channel; entitlement checked in.
- Android: Open-Meteo prototype gateway with visible attribution; replaceable behind `WeatherGateway`.
- Demo: deterministic weather/location/steps/BLE only when `DEMO_MODE=true`.

## Validation boundary for this snapshot

The source tree includes CI that pins Flutter 3.44.9, regenerates platform wrappers, resolves packages, parses Dart sources with the formatter, runs the analyzer and tests, builds an Android debug APK, and compiles an iOS simulator build.

The current generation environment has no Flutter SDK, Android SDK, or Xcode. Local validation therefore covers repository contracts, content reachability, JSON/XML/plist parsing, Swift syntax, Kotlin syntax-level checks, Bash/Python checks, privacy-string checks, and git diff integrity. The first remote CI run remains the authoritative Flutter/Gradle/Xcode type-check gate.
