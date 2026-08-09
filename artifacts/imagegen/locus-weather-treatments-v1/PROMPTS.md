# Locus weather treatments v1 — exact ImageGen prompts

Both images were generated with OpenAI built-in `image_gen` on 2026-08-09.
The tracked directional-object contact sheet was supplied as the reference.

## surface-treatments.png

```text
Use case: stylized-concept
Asset type: reusable production pixel-art weather surface-treatment atlas for Locus
Use the input Locus directional object contact sheet only as a strict reference for pixel scale, palette, crisp stepped edges, upper-left lighting, and weathered material tone. Do not reproduce any complete object.

Create exactly six isolated sparse pixel-art surface-treatment patterns in one precise 3-column by 2-row atlas, ordered:
Row 1 left to right: clear, rain, cloudy.
Row 2 left to right: windy, cold, warm.

Treatments:
- clear: restrained cream and amber upper-left edge sparkles and dry bright flecks
- rain: rain-blue wet specular streaks, droplets, and tiny reflective highlights
- cloudy: cool muted-gray matte mottling with low-contrast pale clusters
- windy: mint diagonal scratches, tiny leaf flecks, and directional motion marks
- cold: ice-blue and cream frost crystals and sharp rim speckles
- warm: amber ember flecks and restrained warm radiant pixels

Every cell is a reusable transparent-ready treatment texture, not a centered emblem or icon. Use sparse evenly distributed marks with 20–35 percent motif coverage, generous inner padding, and no overlap between cells. Keep all six cells on the same fixed hard-edged Locus pixel scale.

Background: perfectly flat uniform solid #FF00FF across every gap and outer edge; no gradient, floor, reflection, vignette, cast shadow, or lighting variation. Never use #FF00FF inside a treatment.
Palette: #071522, #10202D, #172A36, #77C9B4, #D6A657, #E9DCC3, #72AEDD, #A6A99F, restrained violet only if needed.
Avoid: complete objects, object silhouettes, terrain tiles, material emblems, buildings, people, text, labels, numbers, UI frames, logos, watermark, blur, bloom, vector gloss, smooth painting, antialias haze.
```

## footprint-effects.png

```text
Use case: stylized-concept
Asset type: reusable production isometric footprint-effect atlas for Locus
Use the input Locus directional object contact sheet only as a strict reference for 2:1 projection, pixel scale, palette, crisp stepped edges, and upper-left light. Do not reproduce any complete object.

Create exactly six isolated transparent-ready 2:1 isometric footprint effects in one precise 3-column by 2-row atlas, ordered:
Row 1 left to right: clear, rain, cloudy.
Row 2 left to right: windy, cold, warm.

Effects:
- clear: a few warm sunlit edge glints on an otherwise empty isometric footprint
- rain: a shallow rain-blue puddle reflection with two small pixel ripples
- cloudy: a quiet cool-gray low mist rim with an open center
- windy: two mint directional wind curls with three tiny leaf pixels
- cold: a thin frost rim and sparse crystalline snow pixels
- warm: a restrained amber ground radiance made of hard-edged pixel clusters and several warm speckles, not a smooth glow

Use the same apparent footprint size, bottom-center anchor, and generous padding in every cell. Preserve large negative space. No solid opaque terrain tile.

Background: perfectly flat uniform solid #FF00FF everywhere; no floor plane beyond the requested sparse effect, no gradient, texture, reflection, vignette, cast shadow, or lighting variation. Never use #FF00FF inside an effect.
Style: premium handcrafted Locus pixel art with crisp hard-edged stepped clusters, fixed 2:1 isometric projection, no blur or antialias haze.
Avoid: object silhouettes, props, buildings, people, text, labels, logos, watermark, smooth glow, bloom, overlapping cells.
```
