// MegaRealms - Sprite Preloading Fix
// Add this script before the game initializes

(function() {
    'use strict';
    
    // List of all monster sprites to preload
    const monsterSprites = [
        '_bugI', '_ratI', '_crI', '_snkI', '_pspI',
        '_scpI', '_wlfI', '_brI', '_drI', '_boaI',
        '_trlI', '_rwI', '_sklI', '_drgI'
    ];
    
    // Create loading overlay
    const loadingOverlay = document.createElement('div');
    loadingOverlay.id = 'sprite-loading';
    loadingOverlay.style.cssText = `
        position: fixed;
        inset: 0;
        background: rgba(0,0,0,0.95);
        z-index: 10000;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
        font-family: 'Press Start 2P', monospace;
        color: #f0c040;
    `;
    
    const title = document.createElement('h2');
    title.textContent = '🎮 Loading Enhanced Sprites...';
    title.style.cssText = 'font-size: 16px; margin-bottom: 20px; text-shadow: 0 0 10px rgba(240,192,64,0.5);';
    
    const progress = document.createElement('div');
    progress.style.cssText = 'font-size: 12px; margin-bottom: 10px;';
    
    const bar = document.createElement('div');
    bar.style.cssText = `
        width: 400px;
        height: 20px;
        background: #1a1a1a;
        border: 2px solid #f0c040;
        border-radius: 4px;
        overflow: hidden;
        position: relative;
    `;
    
    const fill = document.createElement('div');
    fill.style.cssText = `
        height: 100%;
        width: 0%;
        background: linear-gradient(90deg, #f0c040, #fa4);
        transition: width 0.3s;
    `;
    
    const details = document.createElement('div');
    details.style.cssText = 'font-size: 8px; margin-top: 15px; color: #888;';
    
    bar.appendChild(fill);
    loadingOverlay.appendChild(title);
    loadingOverlay.appendChild(progress);
    loadingOverlay.appendChild(bar);
    loadingOverlay.appendChild(details);
    document.body.appendChild(loadingOverlay);
    
    // Preload function
    let loadedCount = 0;
    let totalSize = 0;
    
    function preloadSprites() {
        return new Promise((resolve) => {
            const total = monsterSprites.length;
            let loaded = 0;
            
            progress.textContent = `Loading sprites: 0/${total}`;
            
            monsterSprites.forEach((varName, index) => {
                const img = window[varName];
                
                if (img && img.src && img.src.startsWith('data:image')) {
                    const size = Math.round(img.src.length / 1024);
                    totalSize += size;
                    
                    const checkLoaded = () => {
                        if (img.complete && img.naturalHeight !== 0) {
                            loaded++;
                            loadedCount = loaded;
                            const percent = Math.round((loaded / total) * 100);
                            fill.style.width = percent + '%';
                            progress.textContent = `Loading sprites: ${loaded}/${total}`;
                            details.textContent = `Loaded ${totalSize} KB of AI-enhanced graphics`;
                            
                            if (loaded === total) {
                                setTimeout(() => {
                                    loadingOverlay.style.opacity = '0';
                                    loadingOverlay.style.transition = 'opacity 0.5s';
                                    setTimeout(() => {
                                        loadingOverlay.remove();
                                        resolve();
                                    }, 500);
                                }, 300);
                            }
                        } else {
                            setTimeout(checkLoaded, 50);
                        }
                    };
                    
                    if (img.complete && img.naturalHeight !== 0) {
                        checkLoaded();
                    } else {
                        img.onload = checkLoaded;
                        img.onerror = () => {
                            console.error('Failed to load sprite:', varName);
                            checkLoaded();
                        };
                        // Force reload if needed
                        const src = img.src;
                        img.src = '';
                        img.src = src;
                        setTimeout(checkLoaded, 100);
                    }
                } else {
                    loaded++;
                    if (loaded === total) {
                        loadingOverlay.remove();
                        resolve();
                    }
                }
            });
        });
    }
    
    // Start preloading when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', preloadSprites);
    } else {
        preloadSprites();
    }
    
    console.log('🎨 MegaRealms: Sprite preloader initialized');
})();
