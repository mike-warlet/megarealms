# MegaRealms Sprites

## Directory Structure

```
sprites/
├── monsters/
│   ├── original/       # Extracted base64 sprites from index.html
│   └── improved/       # AI-enhanced Tibia 7.x style sprites (requires API quota)
└── tiles/
    ├── original/       # Current tile sprites from game
    └── improved/       # Enhanced Tibia-style tiles
```

## Monster Sprites (Extracted)

✅ **Original sprites extracted:**
- rat.png
- skeleton.png
- dragon.png
- troll.png
- spider.png (poison_spider)
- bug.png
- cave_rat.png
- snake.png
- scorpion.png
- wolf.png
- bear.png
- deer.png
- boar.png
- rotworm.png

## Improving Sprites

**Using nano-banana-pro (Gemini 3 Pro Image):**

```bash
cd /data/repos/megarealms

# Generate improved monster sprite
uv run /usr/local/lib/node_modules/openclaw/skills/nano-banana-pro/scripts/generate_image.py \
  --prompt "32x32 pixel art top-down RPG sprite, classic Tibia MMORPG style from version 7.x, [MONSTER NAME], earthy muted color palette, black outline, no anti-aliasing, transparent background, retro 2D game aesthetic" \
  --filename "assets/sprites/monsters/improved/[MONSTER].png" \
  -i "assets/sprites/monsters/original/[MONSTER].png" \
  --resolution 1K
```

**Note:** Requires `GEMINI_API_KEY` env var and available API quota.

## Design Guidelines

See [DESIGN_GUIDE.md](../../DESIGN_GUIDE.md) for full specifications:
- 32×32px resolution
- No anti-aliasing
- 1px black outlines
- Earthy muted color palette
- Tibia 7.x aesthetic

## Improvement Method

**Local Processing (Python + Pillow):**
- ✅ Quantize to Tibia color palette (6-8 colors max)
- ✅ Enhance sharpness (2.0x)
- ✅ Add 1px black outlines
- ✅ Nearest-neighbor resize (preserves pixel art)
- ✅ No anti-aliasing

**Script:** `improve_sprites.py` (run with `uv run --with pillow --with numpy improve_sprites.py`)

## Status

- ✅ Original sprites extracted (14 monsters)
- ✅ Design guide created (DESIGN_GUIDE.md)
- ✅ Improved monster sprites (14/14) — local processing
- ✅ Improved tiles (8/8) — grass, dirt, water, stone_wall, sand, cave_floor, ice, lava
- ⏳ Integration into index.html (next step)
- 🔄 Future: AI-enhanced versions when Gemini quota resets

---

**Last updated:** 2026-02-26 10:20 GMT-3
