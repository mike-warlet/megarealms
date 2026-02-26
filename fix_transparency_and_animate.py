#!/usr/bin/env python3
"""
Fix MegaRealms sprite transparency and add animation frames
"""
import os
from PIL import Image
import numpy as np

def remove_white_background(img):
    """Remove white background and make it transparent"""
    img = img.convert('RGBA')
    data = np.array(img)
    
    # Find pixels that are mostly white (RGB > 240)
    white_mask = (data[:, :, 0] > 240) & (data[:, :, 1] > 240) & (data[:, :, 2] > 240)
    
    # Make white pixels transparent
    data[white_mask] = [255, 255, 255, 0]
    
    # Also handle near-white pixels (anti-aliasing artifacts)
    near_white_mask = (data[:, :, 0] > 220) & (data[:, :, 1] > 220) & (data[:, :, 2] > 220)
    # Reduce alpha based on how white they are
    for i in range(data.shape[0]):
        for j in range(data.shape[1]):
            if near_white_mask[i, j] and not white_mask[i, j]:
                avg = (int(data[i, j, 0]) + int(data[i, j, 1]) + int(data[i, j, 2])) / 3
                if avg > 220:
                    alpha = int((240 - avg) * 12.75)  # Scale 220-240 to 255-0
                    data[i, j, 3] = max(0, alpha)
    
    return Image.fromarray(data, 'RGBA')

def create_animation_frame(img, frame_num, total_frames=4):
    """Create animation frame by slightly shifting the sprite"""
    width, height = img.size
    
    # Simple idle animation: slight vertical bob
    if total_frames == 4:
        offsets = [0, -1, 0, 1]  # Pixels to shift
        offset = offsets[frame_num]
    else:
        offset = 0
    
    # Create new image with offset
    new_img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    new_img.paste(img, (0, offset))
    
    return new_img

def process_sprite(input_path, output_base_path, create_frames=True):
    """Process a single sprite: transparency + animation frames"""
    print(f"Processing: {os.path.basename(input_path)}")
    
    # Load image
    img = Image.open(input_path)
    
    # Remove white background
    img = remove_white_background(img)
    
    # Resize to 32x32 for performance (original is 1024x1024)
    img = img.resize((32, 32), Image.Resampling.LANCZOS)
    
    if create_frames:
        # Create 4 animation frames
        for frame in range(4):
            frame_img = create_animation_frame(img, frame, 4)
            output_path = output_base_path.replace('.png', f'_frame{frame}.png')
            frame_img.save(output_path, 'PNG')
            print(f"  ✓ Frame {frame}: {os.path.basename(output_path)}")
    else:
        # Just save single frame
        img.save(output_base_path, 'PNG')
        print(f"  ✓ Saved: {os.path.basename(output_base_path)}")
    
    return True

def main():
    """Process all monster sprites"""
    print("=" * 60)
    print("MegaRealms - Transparency Fix + Animation")
    print("=" * 60)
    
    input_dir = 'assets/sprites/monsters/improved'
    output_dir = 'assets/sprites/monsters/animated'
    
    # Create output directory
    os.makedirs(output_dir, exist_ok=True)
    
    monsters = [
        'rat', 'skeleton', 'dragon', 'troll', 'spider',
        'bug', 'cave_rat', 'snake', 'scorpion', 'wolf',
        'bear', 'deer', 'boar', 'rotworm'
    ]
    
    print(f"\n=== Processing {len(monsters)} monsters ===\n")
    
    for monster in monsters:
        input_path = os.path.join(input_dir, f'{monster}.png')
        output_path = os.path.join(output_dir, f'{monster}.png')
        
        if os.path.exists(input_path):
            try:
                process_sprite(input_path, output_path, create_frames=True)
            except Exception as e:
                print(f"  ✗ Error: {e}")
        else:
            print(f"  ⚠ Skipped: {monster}.png not found")
    
    print("\n" + "=" * 60)
    print("✓ Processing complete!")
    print("=" * 60)
    print(f"\nOutput: {output_dir}/")
    print("Each monster has 4 animation frames:")
    print("  - monster_frame0.png (idle)")
    print("  - monster_frame1.png (up)")
    print("  - monster_frame2.png (idle)")
    print("  - monster_frame3.png (down)")
    print("\nNext: Run integrate_sprites.py to update index.html")

if __name__ == '__main__':
    main()
