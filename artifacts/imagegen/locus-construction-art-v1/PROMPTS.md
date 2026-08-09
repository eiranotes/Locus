# Locus construction art v1 — exact ImageGen prompts

Both images were generated with OpenAI built-in `image_gen` on 2026-08-09.

## construction-a.png

References supplied:

- `artifacts/imagegen/locus-art-v1/sources/objects.png`
- `artifacts/imagegen/locus-directional-art-v1/sources/objects-a.png`

```text
Use case: stylized-concept
Asset type: production game sprite atlas for the Locus Flutter crafting workbench
Use both input images as strict style and subject-identity references. Preserve the exact handcrafted isometric pixel-art language: crisp stepped pixel edges, fixed pixel scale, approximately 2:1 isometric projection, muted charcoal stone and metal, weathered warm wood, mossy greens, tiny warm amber lights, cozy nocturnal neighborhood mood, bottom-center ground anchors. The first reference establishes the ten exact Locus object identities; the second establishes true directional proportions for these first five objects.

Create ONE precise 5-row by 3-column construction-progress sprite atlas on a perfectly flat solid #FF00FF chroma-key background.

Rows, top to bottom, exactly:
1. the same curved black alley lamp with one hanging amber lantern
2. the same wooden two-arrow signpost on a stone-and-grass base
3. the same square dark-stone planter with dense green foliage and tiny warm flowers
4. the same wood-and-charcoal park bench
5. the same compact dark-stone three-step stairs

Columns, left to right, exactly:
1. 25% built — recognizable foundation and neatly staged raw parts only
2. 60% built — coherent half-built frame, visibly incomplete
3. 85% built — almost complete but one defining final element visibly missing or unlit

All sprites face the same northeast isometric direction. Construction states must be recipe-specific and progress monotonically without changing footprint, object identity, material family, apparent scale, camera, anchor, or light direction. Use small timber braces, stone courses, scaffold pegs, laid-out pieces, or unlit fixtures only where appropriate to that exact object. Do not add people, tools with readable branding, generic construction signs, text, numbers, progress bars, sparkles, finished duplicates, or piles that obscure the object. The 85% alley lamp must remain unlit; the 85% planter may have planted greenery but fewer final flowers; the 85% bench must miss a final slat/detail; the 85% stairs must miss the top cap.

Composition: exact evenly spaced 3 columns × 5 rows; one complete sprite per cell; generous internal padding; no overlap; no cropped pixels; no grid lines; no captions; no text; no labels.
Background: uniform #FF00FF only, no shadow outside the compact footprint, no gradient, floor plane, texture, lighting variation, or magenta inside any subject.
Style: polished high-quality isometric pixel art matching the references, not smooth 3D, not vector, not painterly, no blur, antialias haze, bloom, watermark, logo.
```

## construction-b.png

References supplied:

- `artifacts/imagegen/locus-art-v1/sources/objects.png`
- `artifacts/imagegen/locus-directional-art-v1/sources/objects-b.png`

```text
Use case: stylized-concept
Asset type: production game sprite atlas for the Locus Flutter crafting workbench
Use both input images as strict style and subject-identity references. Preserve the exact handcrafted isometric pixel-art language: crisp stepped pixel edges, fixed pixel scale, approximately 2:1 isometric projection, muted charcoal stone and metal, weathered warm wood, mossy greens, tiny warm amber lights, cozy nocturnal neighborhood mood, bottom-center ground anchors. The first reference establishes the ten exact Locus object identities; the second establishes true directional proportions for these last five objects.

Create ONE precise 5-row by 3-column construction-progress sprite atlas on a perfectly flat solid #FF00FF chroma-key background.

Rows, top to bottom, exactly:
1. the same dense round green neighborhood tree on a square stone-and-grass base
2. the same compact dark teal bus stop shelter with roof, side/map panel, warm hanging lamp, wooden bench, and stone slab base
3. the same small oval blue pond edged with dark stones, reeds, and one lily pad
4. the same short weathered wooden rope bridge with four posts
5. the same tall square gray-stone neighborhood tower with warm illuminated window room, dark tiled pagoda-like roof, and tiny finial

Columns, left to right, exactly:
1. 25% built — recognizable foundation and neatly staged raw parts only
2. 60% built — coherent half-built frame, visibly incomplete
3. 85% built — almost complete but one defining final element visibly missing or unlit

All sprites face the same northeast isometric direction. Construction states must be recipe-specific and progress monotonically without changing footprint, object identity, material family, apparent scale, camera, anchor, or light direction. Use stone courses, timber braces, scaffold pegs, shallow earth/water shaping, laid-out bridge boards, or unlit fixtures only where appropriate. Do not add people, vehicles, text, numbers, progress bars, generic construction signs, finished duplicates, or piles that obscure the object. The 85% tree must have a smaller incomplete canopy; the 85% bus stop lamp stays unlit and one panel remains unfinished; the pond gains water and then reeds/lily detail; the bridge keeps one final rope/board missing; the tower remains unlit and lacks the finial at 85%.

Composition: exact evenly spaced 3 columns × 5 rows; one complete sprite per cell; generous internal padding; no overlap; no cropped pixels; no grid lines; no captions; no text; no labels.
Background: uniform #FF00FF only, no shadow outside the compact footprint, no gradient, floor plane, texture, lighting variation, or magenta inside any subject.
Style: polished high-quality isometric pixel art matching the references, not smooth 3D, not vector, not painterly, no blur, antialias haze, bloom, watermark, logo.
```
