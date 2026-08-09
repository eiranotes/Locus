# Locus directional object art v1

Generated with OpenAI built-in `image_gen` on 2026-08-09. The existing
`artifacts/imagegen/locus-art-v1/sources/objects.png` sheet was supplied as the
style and subject-identity reference. Runtime sprites are reproducibly cropped,
keyed, normalized, and hashed by `tool/process_directional_art.py`. The
authoring pipeline uses a reviewed 45% ImageMagick key tolerance to preserve
stone and metal pixels while removing the generated chroma field without a
runtime dependency.

## Shared contract

- One 5-row × 4-column atlas per prompt.
- Columns are northeast, southeast, southwest, northwest.
- True quarter-turn redraws, not runtime mirroring.
- Match the existing crisp isometric pixel scale, charcoal materials, warm
  amber lights, weathered wood, mossy greens, and bottom-center anchors.
- Perfectly flat `#FF00FF` background; no magenta inside the subjects.
- No labels, text, grid lines, shadows outside the footprint, blur, or watermark.

## objects-a.png — exact prompt

```text
Use case: stylized-concept
Asset type: production game sprite atlas for the Locus Flutter isometric placement editor
Input image: style and exact subject-identity reference. Preserve the reference's pixel-art scale, crisp stepped pixel edges, muted charcoal stone/metal, warm amber light, natural mossy greens, weathered warm wood, cozy nocturnal neighborhood mood, and approximately 2:1 isometric projection.

Create ONE precise 5-row by 4-column sprite atlas on a perfectly flat solid #FF00FF chroma-key background.

Rows, top to bottom, exactly:
1. the same curved black alley lamp with one hanging amber lantern
2. the same wooden two-arrow signpost on a stone-and-grass base
3. the same square dark-stone planter with dense green foliage and tiny warm flowers
4. the same wood-and-charcoal park bench
5. the same compact dark-stone three-step stairs

Columns, left to right, exactly:
1. facing northeast
2. facing southeast
3. facing southwest
4. facing northwest

Each row must show the same object redrawn as four TRUE quarter-turn isometric views. Do not merely mirror asymmetric details. Preserve object identity, materials, proportions, footprint, and lighting across all four views. The stairs must clearly open in four different directions. The bench seat/back orientation and sign arrows must correctly rotate. Keep a consistent bottom-center ground anchor and consistent apparent scale in every cell.

Composition: exact evenly spaced 4 columns × 5 rows; one complete sprite per cell; generous internal padding; no overlap; no cropped pixels; no grid lines; no captions; no text; no labels.
Background: uniform #FF00FF only, with no shadows, gradient, floor plane, texture, lighting variation, or magenta inside any object.
Style: handcrafted high-quality isometric pixel art matching the reference, not smooth 3D, not vector, not painterly.
Avoid: new props, extra plants, extra lamps, duplicate objects within a cell, cast shadows outside the sprite footprint, bloom, blur, antialias haze, watermark, logos.
```

## objects-b.png — exact prompt

```text
Use case: stylized-concept
Asset type: production game sprite atlas for the Locus Flutter isometric placement editor
Input image: style and exact subject-identity reference. Preserve the reference's pixel-art scale, crisp stepped pixel edges, muted charcoal stone/metal, warm amber light, natural mossy greens, weathered warm wood, cozy nocturnal neighborhood mood, and approximately 2:1 isometric projection.

Create ONE precise 5-row by 4-column sprite atlas on a perfectly flat solid #FF00FF chroma-key background.

Rows, top to bottom, exactly:
1. the same dense round green neighborhood tree on a square stone-and-grass base
2. the same compact dark teal bus stop shelter with roof, side/map panel, warm hanging lamp, wooden bench, and stone slab base
3. the same small oval blue pond edged with dark stones, reeds, and one lily pad
4. the same short weathered wooden rope bridge with four posts
5. the same tall square gray-stone neighborhood tower with warm illuminated window room, dark tiled pagoda-like roof, and tiny finial

Columns, left to right, exactly:
1. facing northeast
2. facing southeast
3. facing southwest
4. facing northwest

Each row must show the same object redrawn as four TRUE quarter-turn isometric views. Do not merely mirror asymmetric details. Preserve object identity, materials, proportions, footprint, and lighting across all four views. The bus shelter opening, map panel, bench, and lamp must rotate coherently; all four bridge approaches must be unmistakable; the tower windows and roof planes must rotate; pond reeds and lily pad should vary by viewpoint without changing identity. Keep a consistent bottom-center ground anchor and consistent apparent scale in every cell.

Composition: exact evenly spaced 4 columns × 5 rows; one complete sprite per cell; generous internal padding; no overlap; no cropped pixels; no grid lines; no captions; no text; no labels.
Background: uniform #FF00FF only, with no shadows, gradient, floor plane, texture, lighting variation, or magenta inside any object.
Style: handcrafted high-quality isometric pixel art matching the reference, not smooth 3D, not vector, not painterly.
Avoid: new props, people, vehicles, extra plants beyond the referenced object, duplicate objects within a cell, cast shadows outside the sprite footprint, bloom, blur, antialias haze, watermark, logos.
```
