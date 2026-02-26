#!/usr/bin/env python3
"""
Local sprite improvement script for MegaRealms
Applies Tibia 7.x style enhancements without using external APIs
"""
import os
from PIL import Image, ImageEnhance, ImageFilter, ImageDraw
import numpy as np

# Tibia 7.x color palette (earthy muted tones)
TIBIA_PALETTE = {
    'brown_dark': (101, 67, 33),
    'brown_medium': (139, 105, 20),
    'brown_light': (212, 175, 55),
    'green_dark': (46, 80, 22),
    'green_grass': (58, 125, 47),
    'green_bright': (74, 157, 63),
    'gray_dark': (74, 74, 74),
    'gray_medium': (139, 119, 101),
    'gray_light': (230, 225, 217),
    'red_dark': (139, 0, 0),
    'red_bright': (255, 68, 68),
    'blue_water': (30, 77, 155),
    'blue_ice': (135, 206, 235),
}

def quantize_to_palette(img, palette_colors, max_colors=8):
    """Reduce image to limited color palette (Tibia style)"""
    img_array = np.array(img.convert('RGB'))
    height, width, _ = img_array.shape
    
    # Flatten image
    pixels = img_array.reshape(-1, 3)
    
    # Simple k-means-like clustering to palette
    palette_values = list(palette_colors.values())[:max_colors]
    
    # Find closest palette color for each pixel
    quantized = np.zeros_like(pixels)
    for i, pixel in enumerate(pixels):
        distances = [np.linalg.norm(pixel - np.array(p)) for p in palette_values]
        closest = palette_values[np.argmin(distances)]
        quantized[i] = closest
    
    # Reshape back
    quantized_img = quantized.reshape(height, width, 3).astype(np.uint8)
    result = Image.fromarray(quantized_img)
    
    # Preserve alpha channel if exists
    if img.mode == 'RGBA':
        result.putalpha(img.split()[3])
    
    return result

def add_outline(img, outline_color=(0, 0, 0), thickness=1):
    """Add 1px black outline to non-transparent pixels"""
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    # Create a copy for drawing
    outlined = img.copy()
    alpha = img.split()[3]
    
    # Find edges
    edges = alpha.filter(ImageFilter.FIND_EDGES)
    
    # Create mask for outline
    outline_mask = Image.new('L', img.size, 0)
    outline_mask.paste(edges, (0, 0))
    
    # Apply outline
    draw = ImageDraw.Draw(outlined)
    for x in range(img.width):
        for y in range(img.height):
            if alpha.getpixel((x, y)) > 0:
                # Check neighbors
                for dx in [-thickness, 0, thickness]:
                    for dy in [-thickness, 0, thickness]:
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < img.width and 0 <= ny < img.height:
                            if alpha.getpixel((nx, ny)) == 0:
                                outlined.putpixel((x, y), outline_color + (255,))
                                break
    
    return outlined

def improve_sprite(input_path, output_path, target_size=(32, 32), add_border=True):
    """
    Improve a sprite using local processing:
    - Resize to 32x32 (nearest neighbor for pixel art)
    - Enhance sharpness
    - Quantize to Tibia palette
    - Add 1px black outline
    """
    print(f"Processing: {os.path.basename(input_path)}")
    
    try:
        # Load image
        img = Image.open(input_path)
        
        # Ensure RGBA
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        # Resize if needed (nearest neighbor to preserve pixels)
        if img.size != target_size:
            img = img.resize(target_size, Image.NEAREST)
        
        # Enhance sharpness
        enhancer = ImageEnhance.Sharpness(img)
        img = enhancer.enhance(2.0)
        
        # Quantize to Tibia palette (reduce colors)
        img = quantize_to_palette(img, TIBIA_PALETTE, max_colors=6)
        
        # Add outline
        if add_border:
            img = add_outline(img, outline_color=(0, 0, 0), thickness=1)
        
        # Ensure output directory exists
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        
        # Save with maximum quality
        img.save(output_path, 'PNG', optimize=True)
        print(f"  ✓ Saved: {output_path}")
        
    except Exception as e:
        print(f"  ✗ Error processing {input_path}: {e}")

def improve_all_monsters():
    """Improve all monster sprites"""
    original_dir = 'assets/sprites/monsters/original'
    improved_dir = 'assets/sprites/monsters/improved'
    
    if not os.path.exists(original_dir):
        print(f"Error: {original_dir} not found")
        return
    
    os.makedirs(improved_dir, exist_ok=True)
    
    monsters = [
        'rat', 'skeleton', 'dragon', 'troll', 'spider',
        'bug', 'cave_rat', 'snake', 'scorpion', 'wolf',
        'bear', 'deer', 'boar', 'rotworm'
    ]
    
    print("\n=== Improving Monster Sprites ===")
    for monster in monsters:
        input_path = os.path.join(original_dir, f"{monster}.png")
        output_path = os.path.join(improved_dir, f"{monster}.png")
        
        if os.path.exists(input_path):
            improve_sprite(input_path, output_path)
        else:
            print(f"  ⚠ Skipped (not found): {monster}.png")

def create_tile_sprites():
    """Generate improved tile sprites programmatically"""
    tiles_dir = 'assets/sprites/tiles/improved'
    os.makedirs(tiles_dir, exist_ok=True)
    
    print("\n=== Creating Improved Tiles ===")
    
    # Grass tile
    grass = Image.new('RGBA', (32, 32), TIBIA_PALETTE['green_grass'] + (255,))
    draw = ImageDraw.Draw(grass)
    # Add grass tufts
    for _ in range(8):
        x, y = np.random.randint(0, 32, 2)
        draw.rectangle([x, y, x+3, y+3], fill=TIBIA_PALETTE['green_bright'] + (255,))
    # Add shadows
    for _ in range(5):
        x, y = np.random.randint(0, 32, 2)
        draw.point((x, y), fill=TIBIA_PALETTE['green_dark'] + (255,))
    grass.save(os.path.join(tiles_dir, 'grass.png'))
    print("  ✓ Created: grass.png")
    
    # Dirt tile
    dirt = Image.new('RGBA', (32, 32), (139, 115, 85, 255))
    draw = ImageDraw.Draw(dirt)
    # Add dirt patches
    for _ in range(10):
        x, y = np.random.randint(0, 30, 2)
        draw.rectangle([x, y, x+6, y+6], fill=(107, 83, 69, 255))
    # Add highlights
    for _ in range(8):
        x, y = np.random.randint(0, 32, 2)
        draw.point((x, y), fill=(166, 143, 105, 255))
    dirt.save(os.path.join(tiles_dir, 'dirt.png'))
    print("  ✓ Created: dirt.png")
    
    # Water tile
    water = Image.new('RGBA', (32, 32), TIBIA_PALETTE['blue_water'] + (255,))
    draw = ImageDraw.Draw(water)
    # Add water ripples
    draw.rectangle([6, 6, 26, 26], fill=(37, 99, 212, 255))
    for i in range(6):
        x, y = np.random.randint(0, 28, 2)
        draw.rectangle([x, y, x+4, y+4], fill=(74, 149, 255, 255))
    # Wave lines
    draw.line([(2, 14), (30, 14)], fill=(13, 38, 73, 255), width=1)
    draw.line([(2, 22), (30, 22)], fill=(13, 38, 73, 255), width=1)
    water.save(os.path.join(tiles_dir, 'water.png'))
    print("  ✓ Created: water.png")
    
    # Stone wall tile
    stone = Image.new('RGBA', (32, 32), (101, 67, 33, 255))
    draw = ImageDraw.Draw(stone)
    # Draw brick pattern
    for y in range(0, 32, 8):
        for x in range(0, 32, 8):
            if (x + y) % 16 == 0:
                draw.rectangle([x+2, y+2, x+6, y+6], fill=(85, 85, 85, 255))
    stone.save(os.path.join(tiles_dir, 'stone_wall.png'))
    print("  ✓ Created: stone_wall.png")
    
    # Sand tile
    sand = Image.new('RGBA', (32, 32), (232, 199, 90, 255))
    draw = ImageDraw.Draw(sand)
    # Add sand dunes
    for _ in range(9):
        x, y = np.random.randint(0, 28, 2)
        draw.rectangle([x, y, x+5, y+3], fill=(212, 169, 55, 255))
    sand.save(os.path.join(tiles_dir, 'sand.png'))
    print("  ✓ Created: sand.png")
    
    # Cave floor tile
    cave = Image.new('RGBA', (32, 32), (74, 60, 42, 255))
    draw = ImageDraw.Draw(cave)
    # Add rocks
    for _ in range(6):
        x, y = np.random.randint(0, 28, 2)
        draw.rectangle([x, y, x+4, y+4], fill=(101, 67, 33, 255))
    # Add cracks
    for _ in range(4):
        x1, y1 = np.random.randint(0, 32, 2)
        x2, y2 = np.random.randint(0, 32, 2)
        draw.line([(x1, y1), (x2, y2)], fill=(42, 24, 16, 255), width=1)
    cave.save(os.path.join(tiles_dir, 'cave_floor.png'))
    print("  ✓ Created: cave_floor.png")
    
    # Ice tile
    ice = Image.new('RGBA', (32, 32), (184, 224, 255, 255))
    draw = ImageDraw.Draw(ice)
    # Add ice patches
    for _ in range(4):
        x, y = np.random.randint(0, 28, 2)
        draw.rectangle([x, y, x+12, y+12], fill=(212, 240, 255, 255))
    # Add sparkles
    for _ in range(8):
        x, y = np.random.randint(0, 32, 2)
        draw.point((x, y), fill=(255, 255, 255, 255))
        draw.point((x+1, y), fill=(255, 255, 255, 255))
    ice.save(os.path.join(tiles_dir, 'ice.png'))
    print("  ✓ Created: ice.png")
    
    # Lava tile
    lava = Image.new('RGBA', (32, 32), (74, 32, 32, 255))
    draw = ImageDraw.Draw(lava)
    # Add lava pools
    for _ in range(4):
        x, y = np.random.randint(0, 28, 2)
        draw.ellipse([x, y, x+8, y+8], fill=(255, 68, 68, 255))
    for _ in range(3):
        x, y = np.random.randint(0, 28, 2)
        draw.ellipse([x, y, x+10, y+10], fill=(255, 136, 68, 255))
    lava.save(os.path.join(tiles_dir, 'lava.png'))
    print("  ✓ Created: lava.png")

def main():
    """Main execution"""
    print("=" * 50)
    print("MegaRealms Sprite Improvement (Local)")
    print("=" * 50)
    
    # Improve monster sprites
    improve_all_monsters()
    
    # Create improved tiles
    create_tile_sprites()
    
    print("\n" + "=" * 50)
    print("✓ All sprites and tiles improved successfully!")
    print("=" * 50)

if __name__ == '__main__':
    main()
