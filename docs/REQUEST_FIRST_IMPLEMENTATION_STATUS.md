# Request-first implementation status

## Implemented locally

- [x] Additive request-first enums, entities, catalogs, and balance rules.
- [x] Deterministic request scheduling with the 04:00 game-day boundary,
      one-to-two slots, locked-axis filtering, overlap preference, expiry, and
      persisted history-specimen bindings.
- [x] Confidence-gated specimen matching with hard/soft constraints, partial
      feedback, and pinned similarity/contrast thresholds.
- [x] Relationship milestones with idempotent 1/3/6/10 reward keys.
- [x] SQLite schema v5, executable schema validation, atomic capture and
      exclusive assignment writes.
- [x] Lossless v4 mapping for captures, crafted objects, placements, and
      visitor sightings, with a transaction-final migration marker.
- [x] Deterministic demo sampling plus iOS `AVAudioEngine` and Android
      `AudioRecord` foreground feature samplers that return no PCM or file path.
- [x] Feature-flagged request-first app shell with home, capture, assignment,
      specimen archive, visitor relationships, settings, and relationship
      result UI.
- [x] Shared 5×5 diorama adapter and relationship keepsake auto-placement.
- [x] Manual keepsake placement, directional movement, authored rotation, and
      return-to-storage through the shared placement rules.
- [x] Targeted retrieval of older history-reference specimens without loading
      an unbounded archive.

## Required before defaulting to request-first

- [ ] Compare feature distributions on physical iPhone and multiple Android
      manufacturers using quiet room, street, cafe, transit, repeating, and
      intermittent fixtures.
- [ ] Verify calls, backgrounding, audio-route changes, permanent permission
      denial recovery, battery, thermal behavior, and OS temporary-file residue.
- [ ] Add and visually audit a deterministic end-to-end UI tour, including
      large text, narrow screens, VoiceOver, TalkBack, and keepsake persistence.
- [ ] Run the 14-day request-memory, behavior-change, match-trust, assignment
      choice, and voluntary-return experiment.
- [ ] Decide whether to default to request-first and remove the v6
      weather/BLE/steps/crafting path in a separate reviewed change.
