# Flutter and Android adaptation

The v6 specification was written around iPhone capabilities. This repository keeps game rules platform-neutral and isolates OS evidence behind services and method channels.

| Product evidence | iOS implementation | Android implementation | Domain output |
|---|---|---|---|
| Current location | Core Location through `geolocator` | Fused location through `geolocator` | coarse location cell, never a stored route |
| Current weather | native WeatherKit method channel | replaceable HTTP gateway; prototype Open-Meteo adapter | one of six weather materials |
| Recent work | `CMPedometer` daily queries, up to seven days | `TYPE_STEP_COUNTER` local baselines from installation onward | daily observed/spent step buckets |
| Surroundings | explicit foreground Core Bluetooth scan | explicit foreground BLE scan | aggregate density/persistence/churn features only |
| Diorama | Flutter + Flame canvas | Flutter + Flame canvas | identical deterministic 5×5 scene |
| Local storage | SQLite through `sqflite` | SQLite through `sqflite` | the same schema and transactions |

## Intentional differences

Android's raw step-counter sensor cannot reconstruct the same seven-day history as `CMPedometer`. The implementation records a local daily baseline, starts an unseen day at zero, carries the last observed daily total across device reboots, and recovers later deltas. If motion access or hardware is unavailable, the user can select the configured daily work allowance instead of being blocked.

Switching step sources does not carry unused work from the previous source. Already spent work remains recorded so toggling sources cannot create additional available balance.

iOS uses WeatherKit because it is the product's native Apple weather path and provides required attribution metadata. Android uses a separate adapter behind the same `WeatherGateway` interface. Provider differences are normalized before the weather classifier and do not change crafting rules.

The app does not pretend platform parity where it is absent. Every source is normalized into domain evidence and tagged with a source/version boundary. A future Health Connect adapter can implement `StepSource` without changing crafting, persistence, or UI.

## System surfaces

The core app works without system surfaces. Later platform-specific additions map as follows:

- iOS: App Shortcut, WidgetKit widget, optional Control Center control.
- Android: app shortcut, home-screen widget, optional Quick Settings tile.

No platform surface is allowed to run hidden Bluetooth scanning or create additional collection attempts.
