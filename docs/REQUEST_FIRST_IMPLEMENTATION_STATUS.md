# Request-first implementation status

## Implemented in `agent/request-first-v7-foundation`

- [x] Additive request-first enums and entities.
- [x] Authored request, sense-axis, relationship, scene-object, and balance catalogs.
- [x] Deterministic request scheduler, including persistent history-specimen references.
- [x] Confidence-gated specimen matcher with partial and history comparison paths.
- [x] Relationship milestone engine with idempotent reward keys.
- [x] Platform-neutral sense sampling boundary and deterministic demo sampler.
- [x] Capture coordinator that emits permanent records, specimens, and per-request matches.
- [x] SQLite schema v5.
- [x] Separate request-first repository with transactional capture and assignment writes.
- [x] Static repository contract checker and focused unit tests.

## Next implementation slice

- [ ] Native iOS audio feature sampler.
- [ ] Native Android audio feature sampler.
- [ ] Device parity fixture and no-audio-file audit.
- [ ] v4-to-v5 legacy migration service.
- [ ] Request-first controller and feature-flagged demo shell.
- [ ] Home, capture, assignment, specimen archive, visitor relationship screens.
- [ ] `CraftedObject` to `SceneObject` renderer adapter.
- [ ] Remove v6 loop only after the request-first vertical slice passes device testing.
