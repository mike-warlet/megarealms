#!/usr/bin/env python3
"""
Integrate AI-enhanced sprites into index.html
Converts PNG files to base64 and updates the HTML
"""
import os
import base64
import re

def png_to_base64(file_path):
    """Convert PNG file to base64 data URI"""
    with open(file_path, 'rb') as f:
        data = f.read()
    b64 = base64.b64encode(data).decode('utf-8')
    return f"data:image/png;base64,{b64}"

def integrate_monsters(html_content):
    """Replace monster sprite base64 data in HTML"""
    monsters = [
        'bug', 'rat', 'cave_rat', 'snake', 'spider', 
        'scorpion', 'wolf', 'bear', 'deer', 'boar', 
        'troll', 'rotworm', 'skeleton', 'dragon'
    ]
    
    # Map monster names to variable names in the code
    monster_vars = {
        'bug': '_bugI',
        'rat': '_ratI',
        'cave_rat': '_crI',
        'snake': '_snkI',
        'spider': '_pspI',  # poison_spider
        'scorpion': '_scpI',
        'wolf': '_wlfI',
        'bear': '_brI',
        'deer': '_drI',
        'boar': '_boaI',
        'troll': '_trlI',
        'rotworm': '_rwI',
        'skeleton': '_sklI',
        'dragon': '_drgI'
    }
    
    replacements = 0
    for monster, var in monster_vars.items():
        sprite_path = f'assets/sprites/monsters/improved/{monster}.png'
        
        if not os.path.exists(sprite_path):
            print(f"  ⚠ Skipped {monster}: file not found")
            continue
        
        # Convert to base64
        b64_data_uri = png_to_base64(sprite_path)
        
        # Find and replace in HTML
        pattern = rf"(window\.{var}\.src=)'data:image/png;base64,[^']+'"
        replacement = rf"\1'{b64_data_uri}'"
        
        new_content, count = re.subn(pattern, replacement, html_content)
        
        if count > 0:
            html_content = new_content
            replacements += count
            file_size = os.path.getsize(sprite_path) / 1024
            print(f"  ✓ {monster:12s} → {var:8s} ({file_size:6.1f} KB)")
        else:
            print(f"  ✗ {monster:12s} → {var:8s} (pattern not found)")
    
    return html_content, replacements

def main():
    """Main integration process"""
    print("=" * 60)
    print("MegaRealms Sprite Integration")
    print("=" * 60)
    
    # Read original HTML
    html_path = 'index.html'
    if not os.path.exists(html_path):
        print(f"Error: {html_path} not found")
        return
    
    print(f"\nReading {html_path}...")
    with open(html_path, 'r', encoding='utf-8') as f:
        original_html = f.read()
    
    original_size = len(original_html) / 1024
    print(f"Original size: {original_size:.1f} KB")
    
    # Integrate monsters
    print("\n=== Integrating Monster Sprites ===")
    html_content, monster_count = integrate_monsters(original_html)
    
    print(f"\n✓ Integrated {monster_count} monster sprites")
    
    # Calculate new size
    new_size = len(html_content) / 1024
    size_diff = new_size - original_size
    
    print("\n" + "=" * 60)
    print(f"Original size: {original_size:8.1f} KB")
    print(f"New size:      {new_size:8.1f} KB")
    print(f"Difference:    +{size_diff:7.1f} KB ({size_diff/original_size*100:+.1f}%)")
    print("=" * 60)
    
    # Backup original
    backup_path = 'index.html.backup'
    if not os.path.exists(backup_path):
        print(f"\nCreating backup: {backup_path}")
        with open(backup_path, 'w', encoding='utf-8') as f:
            f.write(original_html)
    
    # Write new HTML
    print(f"Writing updated {html_path}...")
    with open(html_path, 'w', encoding='utf-8') as f:
        f.write(html_content)
    
    print("\n✓ Integration complete!")
    print("\nNext steps:")
    print("1. Test the game locally: open index.html in browser")
    print("2. Verify sprites display correctly")
    print("3. Commit and push changes")
    print("4. If issues occur, restore from backup: mv index.html.backup index.html")

if __name__ == '__main__':
    main()
