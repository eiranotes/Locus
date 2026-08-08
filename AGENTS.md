# Repository implementation rules

This repository implements the Reality Collection Diorama v6 specification in Flutter for iOS and Android.

## Product invariants

- The home surface is the 5×5 isometric neighborhood diorama.
- Steps are crafting work. Weather controls material/environment. Optional foreground BLE controls connection behavior.
- BLE output is never described as people, crowd size, or device identity.
- Weather is regional model data, not a claim of direct measurement at the exact capture point.
- Capture results are persisted before any "use now" or "store" choice.
- Production capture failures never create demo or fake materials.
- The complete loop must work without Bluetooth, without a developer server, and without an account.
- Never monetize cooldowns, steps, weather materials, scan retries, or visitor odds.
- Reuse the same deterministic object renderer in the diorama, crafting preview, inventory, codex, and share output.

## Engineering boundaries

- Put deterministic rules in `lib/src/domain`; no Flutter imports there unless the model is explicitly UI-facing.
- Route persistence through `GameRepository`; multi-entity state changes must use one SQLite transaction.
- Keep schema migrations explicit.
- Native sensor bridges return aggregated values only. Do not persist BLE identifiers, names, MAC addresses, or raw advertisements.
- Android step totals are installation-forward and reboot-safe; iOS may query recent `CMPedometer` history.
- Step-source changes may preserve spent work but must not carry unused allowance between sources.
- iOS weather is WeatherKit; Android weather is an adapter behind `WeatherGateway`.
- Keep the grid at 5×5 and active placed objects at eight or fewer for the MVP.
- Visitor conditions must have no more than three user-visible requirements.
- Any new recipe or visitor must be reachable from initial unlocks or an existing deterministic reward path.

## Required checks

For an ordinary code change with wrappers already present:

```bash
./tool/validate.sh
flutter build apk --debug --dart-define=DEMO_MODE=true --no-pub
```

Regenerate wrappers only when recovering or intentionally updating the pinned Flutter template:

```bash
./tool/bootstrap_platforms.sh
./tool/validate.sh
```

Review the wrapper diff before committing. When Flutter is unavailable, `./tool/validate.sh` still performs repository, content, manifest, entitlement, Swift parse, and Kotlin syntax-level checks. Remote CI is the authoritative Flutter/Gradle/Xcode compilation gate.
