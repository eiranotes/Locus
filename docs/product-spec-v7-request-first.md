# Locus v7 — Request-first foundation

Status: feature-flagged vertical slice. The v6 loop remains the default application path until request-first passes device and behavior validation.

## Product statement

Locus is a local-first game in which visitors ask for a sensory specimen, the player changes attention or movement in the real world to find it, and one specimen is assigned to one request. The permanent capture record remains in the archive; only its assignment right is consumed.

## Core loop

```text
visitor issues one authored request
→ player focuses the request
→ player records a four-second foreground specimen
→ the app stores feature vectors, never source audio
→ the specimen is compared with every active request
→ player chooses one compatible visitor
→ one specimen and one request become mutually exclusive
→ relationship stage advances
→ resident, sense axis, or scene keepsake unlocks
→ the 5×5 diorama remains a place to arrange relationship rewards
```

## Implemented vertical-slice scope

- SQLite schema v5 for specimens, requests, matches, assignments, relationships, events, scene keepsakes, placements, and sense unlocks.
- Deterministic request scheduling with a 04:00 local-day boundary, two slots, authored templates, locked-axis filtering, recent-template avoidance, overlap preference, and explicit history-specimen references.
- Specimen matching with hard/soft constraints, partial feedback, confidence fail-closed behavior, and history similarity/contrast.
- Atomic assignment persistence. Both `specimen_id` and `request_id` are unique in the assignment table.
- Relationship milestones at 1, 3, 6, and 10 completed requests.
- Reuse mapping for existing object art; no new production art is introduced.
- A platform-neutral `SenseSampler`, deterministic demo sampler, iOS
  `AVAudioEngine`, and Android `AudioRecord` feature extraction.
- Lossless legacy mapping, request-first controller, home/capture/assignment/
  archive/relationship/settings UI, and shared diorama scene adaptation.
- Relationship keepsake auto-placement plus manual place, move, rotate, and
  store actions using the existing placement rules.

## Invariants

1. A capture record is permanent.
2. A specimen can be assigned at most once.
3. A request can be fulfilled at most once.
4. Assignment requires a stored passing match for that exact specimen/request pair.
5. Relationship mutation, rewards, and assignment persist in one SQLite transaction.
6. Passive refresh never samples a sensor.
7. Low-confidence specimens are archived but cannot be assigned.
8. Placement does not satisfy requests and does not advance relationships.
9. The existing 5×5 grid and eight-active-object limit are preserved.
10. Existing v6 tables remain intact for later lossless migration.

## Initial content contract

- Visitors: `night_moth`, `fog_cat`, `tea_mouse`.
- Initially unlocked axes: loudness, intermittency, time band.
- Later axes: rhythmicity, dynamic range, spectral brightness.
- Authored templates: at least twelve; stage-zero templates may use only initially unlocked axes.
- Request slots: one during tutorial, two afterward.
- Request lifetime: 72 hours.
- Capture target: four seconds.
- Relationship milestones: 1 / 3 / 6 / 10 fulfillments.

## Remaining validation and product gates

- Physical-device parity calibration and interruption/permission/route testing.
- OS temporary-file residue, battery, thermal, and accessibility audits.
- Deterministic full-flow UI screenshots and keepsake persistence tour.
- Fourteen-day behavior validation.
- Replacement of the current crafting, weather, BLE, and step loop.
- Production analytics or remote configuration.

These remain explicit gates. The current application defaults to v6 while the
request-first slice is run with `REQUEST_FIRST_MODE=true`.
