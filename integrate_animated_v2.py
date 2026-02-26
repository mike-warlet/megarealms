#!/usr/bin/env python3
"""
Integrate animated transparent sprites - V2 (handles minified code)
"""
import os
import base64
import re

def png_to_base64(file_path):
    """Convert PNG to base64"""
    with open(file_path, 'rb') as f:
        data = f.read()
    b64 = base64.b64encode(data).decode('utf-8')
    return f"data:image/png;base64,{b64}"

def create_animation_code_inline(monster_name, var_prefix):
    """Generate compact inline JavaScript for animation"""
    frames_b64 = []
    
    for frame in range(4):
        sprite_path = f'assets/sprites/monsters/animated/{monster_name}_frame{frame}.png'
        if os.path.exists(sprite_path):
            frames_b64.append(png_to_base64(sprite_path))
        else:
            print(f"    ⚠ Missing: {sprite_path}")
            return None
    
    # Compact inline code (no newlines for minified HTML)
    code = (
        f"if(!window.{var_prefix}_f){{"
        f"window.{var_prefix}_f=[new Image(),new Image(),new Image(),new Image()];"
        f"window.{var_prefix}_fi=0;"
        f"window.{var_prefix}_t=0;"
        f"window.{var_prefix}_f[0].src='{frames_b64[0]}';"
        f"window.{var_prefix}_f[1].src='{frames_b64[1]}';"
        f"window.{var_prefix}_f[2].src='{frames_b64[2]}';"
        f"window.{var_prefix}_f[3].src='{frames_b64[3]}';"
        f"}}"
        f"const n=Date.now();"
        f"if(n-window.{var_prefix}_t>200){{"
        f"window.{var_prefix}_fi=(window.{var_prefix}_fi+1)%4;"
        f"window.{var_prefix}_t=n;"
        f"}}"
        f"const cf=window.{var_prefix}_f[window.{var_prefix}_fi];"
        f"if(cf.complete)ctx.drawImage(cf,0,0,32,32);"
        f"else px(ctx,8,12,16,10,'rgba(160,154,150,0.3)');"
    )
    
    return code

def integrate_monster(html_content, monster_name, var_name):
    """Replace single monster sprite code"""
    # Find the case statement for this monster
    # Pattern: case 'monster':{if(!window._var){...}if(window._var.complete)...else{...}}break;
    
    pattern = rf"case\s+'{re.escape(monster_name)}':\s*\{{[^}}]*?if\(!window\.{var_name}\)\{{[^}}]+?}};?[^}}]*?if\(window\.{var_name}\.complete\)[^}}]*?else\{{[^}}]*?}}\s*}}\s*break;"
    
    new_code = create_animation_code_inline(monster_name.replace('_', '_'), var_name)
    
    if not new_code:
        return html_content, 0
    
    # Create replacement
    replacement = f"case '{monster_name}':{{{new_code}}}break;"
    
    # Try to replace
    new_html, count = re.subn(pattern, replacement, html_content, count=1, flags=re.DOTALL)
    
    return new_html, count

def main():
    """Main integration"""
    print("=" * 70)
    print("MegaRealms - Animated Sprite Integration V2")
    print("=" * 70)
    
    html_path = 'index.html'
    
    if not os.path.exists(html_path):
        print(f"✗ Error: {html_path} not found")
        return
    
    print(f"\n📖 Reading {html_path}...")
    with open(html_path, 'r', encoding='utf-8') as f:
        html = f.read()
    
    original_size = len(html) / 1024 / 1024
    print(f"   Original size: {original_size:.2f} MB")
    
    # Monster mapping
    monsters = {
        'bug': '_bugI',
        'rat': '_ratI',
        'cave_rat': '_crI',
        'snake': '_snkI',
        'poison_spider': '_pspI',
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
    
    print(f"\n🔄 Processing {len(monsters)} monsters...\n")
    
    total_replaced = 0
    
    for monster, var in monsters.items():
        # Try with original name
        html, count = integrate_monster(html, monster, var)
        
        if count > 0:
            print(f"   ✓ {monster:15s} → animated ({var})")
            total_replaced += count
        else:
            print(f"   ✗ {monster:15s} → pattern not found")
    
    new_size = len(html) / 1024 / 1024
    size_diff = new_size - original_size
    
    print(f"\n{'=' * 70}")
    print(f"📊 Results:")
    print(f"   Replaced: {total_replaced}/{len(monsters)} monsters")
    print(f"   Size: {original_size:.2f} MB → {new_size:.2f} MB ({size_diff:+.2f} MB)")
    print(f"{'=' * 70}")
    
    if total_replaced > 0:
        # Backup
        backup = 'index.html.backup-anim'
        if not os.path.exists(backup):
            print(f"\n💾 Creating backup: {backup}")
            with open(backup, 'w', encoding='utf-8') as f:
                with open(html_path, 'r', encoding='utf-8') as orig:
                    f.write(orig.read())
        
        # Write
        print(f"✍️  Writing {html_path}...")
        with open(html_path, 'w', encoding='utf-8') as f:
            f.write(html)
        
        print("\n✅ Done! Features:")
        print("   • Transparent backgrounds (RGBA)")
        print("   • 4-frame idle animation")
        print("   • 32×32px optimized")
        print("   • 200ms frame timing")
        print("\n🚀 Next: wrangler deploy")
    else:
        print("\n⚠️  No replacements made. Check patterns.")

if __name__ == '__main__':
    main()
