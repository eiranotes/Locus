# Request-first v7 architecture

## Coexistence boundary

The current v6 application stays wired to `AppController`, `GameRepository`, weather/BLE capture, crafting, and the existing `DioramaSnapshot`. The request-first foundation is additive:

```text
RequestFirstCatalog
RequestScheduler
SenseSampler
SpecimenCaptureCoordinator
SpecimenMatcher
RelationshipEngine
RequestFirstRepository
SQLite schema v5 tables
```

No request-first class is imported by the current app bootstrap. This prevents an incomplete native sensor slice from destabilizing the shipping prototype while still allowing domain, content, and migration contracts to land in the repository.

## Capture boundary

`SenseSampler` returns only normalized values in the range 0...1 and a confidence score. It does not return PCM, file paths, device identifiers, or raw observations.

```text
SenseSampler.sample
→ SenseSampleResult
→ SpecimenCaptureCoordinator
→ CaptureRecord + Specimen
→ SpecimenMatcher for each active request
→ RequestFirstRepository.saveSpecimenCapture transaction
```

A later native implementation must preserve this exact Dart contract on iOS and Android.

## Request scheduling

`RequestScheduler` is deterministic for the same local game day and state. It:

- expires requests before filling empty slots;
- excludes templates that require locked axes;
- excludes history templates until enough specimens exist;
- assigns a concrete, deterministic history specimen to every history request;
- prevents two active requests from using the same visitor;
- avoids templates issued in the previous seven days where alternatives exist;
- prefers an overlapping second request according to `overlapPairRate`;
- maintains an everyday/outing split through `everydayRequestRatio`.

The scheduler does not persist. Its result is committed by `RequestFirstRepository.saveRequestSchedule`.

## Match stability

The matcher result is stored at capture time. Future threshold or algorithm changes do not retroactively alter whether a specimen could be assigned to a request that was visible when captured.

Normal constraints use bounded range scoring. A hard constraint must score at least 0.65 and the weighted total must be at least 0.75. A weighted result from 0.45 to 0.75 is partial feedback. History requests compare normalized Euclidean distance over common numeric axes.

## Atomic assignment

`RequestFirstRepository.assignSpecimen` rechecks all persistent preconditions inside one transaction:

1. no assignment exists for either specimen or request;
2. request is active and belongs to the selected visitor;
3. a passing stored match exists;
4. accepted score equals the stored score;
5. assignment, fulfilled request, relationship, events, sense unlocks, and scene objects are written together.

The database also enforces unique `specimen_id` and `request_id` in `specimen_assignments`.

## Relationship progression

`RelationshipEngine` is pure and receives a cataloged track. Every fulfillment creates one `requestFulfilled` event. Crossing a milestone may add:

- `becameResident` at one fulfillment;
- one sense-axis unlock at three;
- one reusable scene keepsake at six;
- relationship stage four at ten.

Reward keys are stored on the relationship row so replaying a state cannot grant a milestone twice.

## Scene migration target

`SceneObject` separates placement inventory from crafting provenance. Existing `CraftedObject` rows will later migrate with identical IDs, visual seeds, generator versions, variant keys, and placements. Weather, surroundings, focus trait, and construction state will be retained in `legacy_payload_json` for renderer compatibility.
