# Locus branding candidates

## Current candidate

- File: `candidates/locus-app-icon-pro-2026-08-09-1024.png`
- Source: generated in the existing Locus ChatGPT project conversation with the
  Pro model on 2026-08-09.
- Normalization: the downloaded 1254 × 1254 opaque PNG was resized to
  1024 × 1024 and assigned the sRGB IEC61966-2.1 profile with macOS `sips`.
- Status: owner-review candidate only. It is intentionally not copied into the
  generated iOS `AppIcon.appiconset` until the product owner approves it.
- Scope: app icon only. Runtime sprites are maintained independently under
  `assets/art/generated/v1`; this candidate is not a launch image, in-app
  illustration, or Weather attribution asset.

The candidate reads clearly as a nocturnal miniature place at medium sizes, but
its two-building composition becomes detail-dense at 29 pt. Review it at actual
iOS icon sizes before selecting it as the shipping identity.

## Generation prompt

```text
Create one original production-ready iOS app icon master for “Locus,” a calm local-first game where weather and walking shape a miniature neighborhood diorama.

OUTPUT
- Exactly one square artwork, 1024 × 1024 pixels.
- Full-bleed opaque sRGB RGB image; no alpha channel or transparent pixels.
- Do not round the corners; iOS applies its own mask.
- Show only the finished artwork, not a phone mockup, icon grid, presentation board, or UI screenshot.

COMPOSITION
- A single bold 2:1 isometric neighborhood tile centered in the canvas.
- On the tile, show a simple stepped path, one small planter, and one tall alley lamp with a restrained warm light.
- Add one tiny mint connector path or pair of dots between structures to suggest that real-world conditions shape relationships in the miniature place.
- Keep the essential silhouette within the central 72% of the canvas.
- Use large, readable forms that remain recognizable when reduced to 29 pixels.

STYLE
- Original soft pixel/dot art with crisp hard-edged clusters aligned to a consistent 8-pixel grid.
- Calm, handcrafted, collectible, nocturnal, and gently mysterious.
- One consistent light direction from the upper left.
- Limited local glow only around the lamp.
- Not photorealistic, not glossy, not cyberpunk, and not a generic map or navigation icon.

PALETTE
- Deep navy background: #071522
- Dark raised surfaces: #10202D and #172A36
- Mint accent: #77C9B4
- Amber light: #D6A657
- Warm cream: #E9DCC3
- Rain blue accent: #72AEDD
- Muted gray: #A6A99F

EXCLUDE
- No text, letters, numbers, Korean characters, or wordmark.
- No map pin, compass, globe, camera, people, faces, real-world landmark, or exact geographic location.
- No Apple, Flutter, Weather, WeatherKit, or third-party logos.
- No copyrighted characters, recognizable brand styling, watermark, signature, outer border, pre-rounded mask, or transparent edge.
```

## Runtime visual assets

The owner approved the first static runtime atlas after the shared renderer was
introduced. Its independent provenance and processing contract live in
`artifacts/imagegen/locus-art-v1`. Launch still uses a solid `#071522` native
background rather than generated splash art. WeatherKit attribution continues
to use Apple's official mark and text fallback.
