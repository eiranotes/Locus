# Production art placeholder

The current prototype draws the diorama using deterministic canvas primitives so that game rules and layout can be tested without inconsistent generated artwork.

Replace the painter primitives with shared pixel atlases only after the G2 diorama-quality gate. Use nearest-neighbor filtering and preserve identical geometry across the home scene, crafting preview, inventory thumbnail, codex, and share renderer.
