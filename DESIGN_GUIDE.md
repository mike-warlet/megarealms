# MegaRealms — Design Guide (Tibia 7.x Style)

> **Visual Direction:** Classic Tibia MMORPG aesthetic (versions 7.x–8.x), pixel art top-down perspective, retro 2D game look.

---

## 🎨 Color Palette

### Core Tibia Colors
**Earthy & Muted Tones:**
- **Browns:** `#654321` (dark), `#8b6914` (medium), `#d4af37` (gold/sand)
- **Greens:** `#2e5016` (dark forest), `#3a7d2f` (grass), `#4a9d3f` (bright grass)
- **Grays:** `#4a4a4a` (stone), `#8b7765` (cave), `#e6e1d9` (bone/skeleton)
- **Blues:** `#1e4d9b` (deep water), `#4a95ff` (shallow water), `#87ceeb` (ice)
- **Reds:** `#8b0000` (blood), `#b22222` (fire), `#ff4444` (lava)

### Character Skin Tones
- Base: `#e8c4a0`
- Shadow: `#d4a580`

### UI/HUD Colors
- Gold (currency, highlights): `#f0c040`
- Health bar: `#f44` → `#c22` → `#a11` (gradient)
- Mana bar: `#44f` → `#22c` → `#11a` (gradient)
- XP bar: `#fa4` → `#c82` → `#a61` (gradient)

---

## 📐 Pixel Art Rules

### Resolution
- **Base tile size:** `32×32 pixels`
- **Character/monster sprites:** `32×32 pixels` (fill ~70–85% of tile)
- **Items:** `32×32 pixels` (smaller items can use 16×16 centered)

### Anti-Aliasing
- ❌ **NO anti-aliasing** — hard edges only
- ✅ Use **dithering** for gradients/shadows (checkerboard pattern)
- ✅ **1px black outlines** for characters, monsters, and important objects

### Shape & Form
- **Top-down perspective** (slight 3/4 angle on tall objects)
- **Simple silhouettes** — should be recognizable at thumbnail size
- **Limited colors per sprite:** 4–8 colors max
- **Avoid gradients** — use flat colors or 2-color dithering

---

## 🧍 Character & Monster Proportions

### Humanoid Characters (Knight, Paladin, Mage)
```
Head:     10px × 8px   (top)
Torso:    12px × 8px   (body/armor)
Arms:     2px × 8px    (each side)
Legs:     5px × 8px    (each leg)
Boots:    5px × 4px    (each foot)
```
- Eyes: `1–2px` black dots
- Mouth: Optional `2–3px` horizontal line
- Hair: `8–12px` width cap/helmet

### Monsters (Rat, Troll, Dragon)
- **Small (Rat, Bug):** `16–20px` max dimension
- **Medium (Troll, Orc):** `24–28px` height
- **Large (Dragon):** `28–32px` width/height (can overflow slightly)

### Animation Frames (Optional)
- **Idle:** 1–2 frames
- **Walk:** 2–4 frames (legs alternating)
- **Attack:** 2–3 frames

---

## 🌍 Tile Design

### Ground Tiles
**Grass (`TT.G`):**
- Base: `#3a7d2f`
- Highlights: `#4a9d3f` (random 4–6 tufts)
- Shadows: `#2a6d2f` (random 3–5 pixels)

**Dirt (`TT.D`):**
- Base: `#8b7355`
- Patches: `#6b5345` (6–8 irregular shapes)
- Highlights: `#a68f69` (8–10 scattered pixels)

**Sand (`TT.SA`):**
- Base: `#e8c75a`
- Dunes: `#d4a937` (wavy 5–7 patches)

**Cave Floor (`TT.CV`):**
- Base: `#4a3c2a`
- Rocks: `#654321` (4–6 small shapes)
- Cracks: `#2a1810` (1px lines)

### Walls
**Stone Wall (`TT.WL`):**
- Base: `#654321`
- Bricks: `#555` (4×4 grid, alternating)
- Mortar: `#444` (1px gaps)

**Cave Wall (`TT.CW`):**
- Base: `#8b7765`
- Rock faces: `#654321` (hexagonal/angular)
- Highlights: `#a68f69` (inner polygon)

### Water
- Base: `#1e4d9b`
- Mid: `#2563d4` (20×20px center)
- Highlights: `#4a95ff` (4–6 small waves)
- Waves: `#0d2649` (2 horizontal lines)

---

## 🗡️ UI/HUD Style

### Borders & Frames
- **Outer border:** 2px `#c9a959` (gold)
- **Inner shadow:** 1px `#8b6914` (dark gold)
- **Background:** `#2a2420` → `#1e1a16` (gradient)

### Buttons
- **Normal:** `#333` background, `#555` border
- **Hover:** `#f0c040` border, slight glow
- **Pressed:** `#222` background, inset shadow

### Text
- **Font:** `Press Start 2P` or similar pixel font
- **Primary:** `#f0c040` (gold)
- **Secondary:** `#ccc` (light gray)
- **Error/Combat:** `#e44` (red)
- **Success/Heal:** `#4e4` (green)
- **Info/System:** `#6af` (blue)

### Health/Mana Bars
- **Container:** 2px `#666` border, `#0a0a0a` background
- **Inner glow:** Subtle box-shadow matching bar color
- **Text overlay:** 6px white text with `1px #000` shadow

---

## 📦 Item Design

### Weapons
- **Swords:** Silver blade `#c0c0c0`, brown hilt `#654321`
- **Axes:** Gray head `#888`, wood handle `#8b6914`
- **Bows:** Light wood `#d4af37`, dark string `#333`

### Armor
- **Knight (plate):** `#8b8b8b` (steel), `#c9a959` (trim)
- **Paladin (leather):** `#654321` (brown), `#8b6914` (accents)
- **Mage (robe):** `#4a3c8c` (purple), `#d4af37` (trim)

### Potions
- **Health:** Red bottle `#f44`, cork `#654321`
- **Mana:** Blue bottle `#44f`, cork `#654321`
- **Antidote:** Green bottle `#4f4`, cork `#654321`

### Loot Bags
- Base: `#8b6914` (dark brown)
- Body: `#d4af37` → `#f0c040` (gold gradient)
- Ties: `#654321` (dark brown rope)
- Coins: `#ffff00` (3–4 small circles)

---

## 🎯 Reference Monsters (Style Guide)

### Rat
- Body: `#a09a96` (gray-brown)
- Eyes: `1px #000` dots
- Tail: `8px` curved line
- Size: `16×10px`

### Skeleton
- Bones: `#e6e1d9` (off-white)
- Shadows: `#c8c0b0`
- Eyes: `2px #ff0000` glow
- Size: `10×27px` (tall)

### Troll
- Skin: `#468246` (mossy green)
- Eyes: `2px #ff0` dots
- Tusks: `#fff` (2–3px)
- Size: `12×26px`

### Dragon
- Scales: `#b4461e` (burnt orange)
- Wings: `#8b2500` (darker)
- Eyes: `2px #ff0` glow
- Breath: `#ff4400` particles
- Size: `30×28px` (large)

### Spider (Poison)
- Body: `#506e32` (dark green)
- Legs: `#3c5528` (8 legs, 2px each)
- Eyes: `4–6px red dots`
- Size: `28×18px` (wide)

---

## ✅ Do's and Don'ts

### ✅ DO
- Use **flat colors** with **dithering** for depth
- Keep **silhouettes simple** and recognizable
- Add **1px black outlines** to important objects
- Use **earthy, muted tones** (browns, greens, grays)
- Design for **32×32px** base resolution
- Test sprites at **1x zoom** (actual size)

### ❌ DON'T
- Use gradients (use dithering instead)
- Enable anti-aliasing
- Use more than 8 colors per sprite
- Make sprites too detailed (lose clarity at small size)
- Use bright/neon colors (breaks Tibia aesthetic)
- Exceed 32×32px tile boundaries (except large bosses)

---

## 🔗 References

### Official Tibia Resources
- [Tibia Wiki (7.x sprites)](https://tibia.fandom.com/)
- [TibiaML Sprite Archive](https://tibia.fandom.com/wiki/Category:Artwork)

### Pixel Art Tools
- **Aseprite** (paid, best for animation)
- **Piskel** (free, web-based)
- **GIMP** (free, disable anti-aliasing)

### Color Palette Tools
- [Lospec Palette List](https://lospec.com/palette-list) (search "earthy" or "retro")
- Use 8–16 color palettes for consistency

---

## 📝 Changelog

- **2026-02-26:** Initial design guide created for sprite improvement phase
- **Target:** Improve all monster sprites (rat, skeleton, dragon, troll, spider, etc.)
- **Next:** Generate improved tiles (grass, dirt, water, walls)

---

**Made for MegaRealms** — On-Chain MMORPG on Base 🎮
