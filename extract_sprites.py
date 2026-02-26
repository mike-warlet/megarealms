#!/usr/bin/env python3
import re
import base64

# Read index.html
with open('index.html', 'r') as f:
    html = f.read()

# Monster sprites to extract (main 5 + extras)
sprites = {
    'rat': '_ratI',
    'skeleton': '_sklI',
    'dragon': '_drgI',
    'troll': '_trlI',
    'spider': '_pspI',  # poison_spider
    'bug': '_bugI',
    'cave_rat': '_crI',
    'snake': '_snkI',
    'scorpion': '_scpI',
    'wolf': '_wlfI',
    'bear': '_brI',
    'deer': '_drI',
    'boar': '_boaI',
    'rotworm': '_rwI'
}

# Extract and save each sprite
for name, var in sprites.items():
    pattern = rf"window\.{var}\.src='data:image/png;base64,([^']+)'"
    match = re.search(pattern, html)
    
    if match:
        b64_data = match.group(1)
        try:
            img_data = base64.b64decode(b64_data)
            output_path = f'assets/sprites/monsters/original/{name}.png'
            with open(output_path, 'wb') as img_file:
                img_file.write(img_data)
            print(f"✓ Extracted: {name}.png")
        except Exception as e:
            print(f"✗ Failed to extract {name}: {e}")
    else:
        print(f"✗ Not found: {name}")

print("\n✓ Sprite extraction complete!")
