#!/usr/bin/env python3
"""
Apply sprite preloading fix to index.html
Adds loading screen to ensure all AI-enhanced sprites load before game starts
"""
import os
import re

def apply_fix():
    """Add sprite preloading script to index.html"""
    
    print("=" * 60)
    print("MegaRealms - Sprite Loading Fix")
    print("=" * 60)
    
    # Read the JavaScript fix
    if not os.path.exists('fix_sprite_loading.js'):
        print("Error: fix_sprite_loading.js not found")
        return
    
    with open('fix_sprite_loading.js', 'r') as f:
        fix_script = f.read()
    
    # Read index.html
    if not os.path.exists('index.html'):
        print("Error: index.html not found")
        return
    
    print("\nReading index.html...")
    with open('index.html', 'r', encoding='utf-8') as f:
        html = f.read()
    
    # Check if fix already applied
    if 'sprite-loading' in html:
        print("\n⚠️  Fix already applied!")
        print("To reapply, restore from backup first:")
        print("  mv index.html.backup index.html")
        return
    
    # Find where to insert (before </body>)
    body_end = html.rfind('</body>')
    if body_end == -1:
        print("Error: Could not find </body> tag")
        return
    
    # Insert the script
    script_tag = f"\n<script>\n{fix_script}\n</script>\n"
    new_html = html[:body_end] + script_tag + html[body_end:]
    
    # Backup if not exists
    if not os.path.exists('index.html.backup'):
        print("Creating backup: index.html.backup")
        with open('index.html.backup', 'w', encoding='utf-8') as f:
            f.write(html)
    
    # Write fixed version
    print("Writing fixed index.html...")
    with open('index.html', 'w', encoding='utf-8') as f:
        f.write(new_html)
    
    print("\n" + "=" * 60)
    print("✅ Fix applied successfully!")
    print("=" * 60)
    print("\nWhat was added:")
    print("- Loading screen with progress bar")
    print("- Preloads all 14 AI-enhanced monster sprites")
    print("- Shows loading progress (sprite count + size)")
    print("- Only starts game when all sprites are loaded")
    print("\nNext steps:")
    print("1. Open index.html in Chrome")
    print("2. You'll see a loading screen: '🎮 Loading Enhanced Sprites...'")
    print("3. Wait for progress bar to reach 100%")
    print("4. Game will start with all AI sprites loaded!")
    print("\nIf issues occur, restore backup:")
    print("  mv index.html.backup index.html")

if __name__ == '__main__':
    apply_fix()
