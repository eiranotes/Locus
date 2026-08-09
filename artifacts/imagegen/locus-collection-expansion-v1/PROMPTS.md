# ImageGen prompts

All prompts used the existing Locus sprite sheets as strict visual references.

## Directional atlases

Common prompt: Create a production-ready pixel-art sprite atlas for Locus that
strictly matches the supplied isometric night-neighborhood reference: crisp
nearest-neighbor pixels, deep navy outlines, muted slate and moss materials,
small amber highlights, no gradients or soft shadows. Use a flat `#FF00FF`
background. Arrange exactly 6 rows by 4 columns. Columns are true quarter-turn
redraws in this exact order: NE, SE, SW, NW. Keep one centered isolated object
per cell with generous consistent padding and no text, labels, borders, grid,
people, UI, logos, or extra props.

- Street rows: mailbox; rain shelter; stone gate; old street clock post; book
  kiosk; laundry line.
- Garden rows: flower arch; bird bath; small greenhouse; stone fountain; picnic
  table; weeping willow.
- Night-market rows: string lights between two posts; wind chime on a post; low
  tea table with teapot and stool; night market stall; stone lantern; compact
  observatory with dome and telescope.

## Construction atlases

Common prompt: Create a construction-progress pixel-art atlas using the supplied
Locus construction sheet as strict style and staging reference. Keep the same
isometric angle, navy outlines, muted slate/moss materials and tiny amber accents
on flat `#FF00FF`. Arrange exactly 6 rows by 3 columns. Columns are 25 percent
foundation, 60 percent frame, and 85 percent nearly finished. Progress must be
monotonic and preserve the final object's footprint. One centered isolated build
per cell; no completed final sprite, text, labels, borders, people, UI, logos, or
unrelated props.

- Street rows: mailbox; rain shelter; stone gate; old street clock post; book
  kiosk; laundry line.
- Garden rows: flower arch; bird bath; small greenhouse; stone fountain; picnic
  table; weeping willow.
- Night-market rows: string lights between two posts; wind chime on a post; low
  tea table; night market stall; stone lantern; compact observatory.

## Visitor atlases

Common prompt: Create a production-ready Locus visitor sprite sheet that strictly
matches the supplied visitor reference: charming compact pixel-art silhouettes,
deep navy outlines, muted natural colors, sparse amber accents, readable at small
mobile size, flat `#FF00FF` background. Arrange exactly 3 columns by 2 rows, one
centered isolated visitor per cell with consistent scale and padding. No text,
labels, borders, scenery, UI, logos, or duplicate poses.

- Sheet A: sparrow pair; rain frog under a leaf; letter-carrier pigeon; scarfed
  window fox; tea-cup mouse; pale blue wind sprite.
- Sheet B: garden keeper; brook heron; book-collector owl; hooded night watcher
  with telescope; rain-shelter dog; rooftop swallow in flight.
