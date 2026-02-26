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

## Status

- ✅ Original sprites extracted (14 monsters)
- ✅ Design guide created
- ⏳ Improved sprites generation (pending API quota)
- ⏳ Tile improvements
- ⏳ Integration into index.html

---

**Last updated:** 2026-02-26
