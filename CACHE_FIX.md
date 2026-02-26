# 🔧 MegaRealms - Problema de Cache do Navegador

## Problema

Você atualizou os sprites do jogo mas não vê as mudanças ao abrir o jogo.

**Causa:** O navegador está usando a versão antiga em cache (index.html de 310KB ao invés de 14MB).

---

## ✅ Soluções (Tente em ordem)

### Solução 1: Hard Refresh (Limpar Cache)

**Chrome/Edge/Firefox:**
- **Windows:** `Ctrl + Shift + R` ou `Ctrl + F5`
- **Mac:** `Cmd + Shift + R`

**Safari:**
- `Cmd + Option + R`

### Solução 2: Limpar Cache Manualmente

**Chrome:**
1. `F12` (DevTools)
2. Clique direito no botão de recarregar
3. Selecione "**Empty Cache and Hard Reload**"

**Firefox:**
1. `Ctrl + Shift + Delete`
2. Marque "**Cache**"
3. Clique "**Clear Now**"

### Solução 3: Modo Anônimo/Incógnito

Abra o jogo em uma janela privada:
- **Chrome:** `Ctrl + Shift + N`
- **Firefox:** `Ctrl + Shift + P`

### Solução 4: Verificar Tamanho do Arquivo

Abra DevTools (F12) → aba **Network** → recarregue a página:
- **Versão antiga:** ~310 KB
- **Versão nova (sprites AI):** ~14 MB

Se ainda mostrar 310 KB, o cache não foi limpo.

### Solução 5: Forçar Download Novo

Adicione parâmetro de query na URL:
```
file:///caminho/para/megarealms/index.html?v=2
```

Ou via servidor local:
```bash
cd /data/repos/megarealms
python3 -m http.server 8000
# Acesse: http://localhost:8000/index.html?v=2
```

---

## 🔍 Verificar se Sprites Carregaram

### Teste Rápido:
1. Abra DevTools (`F12`)
2. Vá para **Console**
3. Digite:
```javascript
window._ratI.src.length
```
Se retornar **~931000** (930KB), os sprites AI estão carregados ✅  
Se retornar **~350** (350 bytes), está usando sprites antigos ❌

### Teste Visual:
Abra `test_sprites.html` no navegador:
```bash
cd /data/repos/megarealms
# Abrir test_sprites.html no navegador
```

Deve mostrar os 5 sprites principais (rat, skeleton, dragon, troll, spider) em alta qualidade.

---

## 🐛 Problema Persiste?

### Possível Causa: Sprites Muito Grandes

Os sprites AI-enhanced têm **~700-900 KB cada** (14 MB total).  
Navegadores antigos ou com pouca memória podem ter problemas.

**Solução:**
1. Use navegador moderno (Chrome/Firefox/Edge atualizados)
2. Feche outras abas para liberar memória
3. Verifique console do navegador (F12) por erros

### Verificar Erros no Console:

Se aparecer:
- `Failed to load resource` → Arquivo não encontrado
- `Out of memory` → Sprites muito grandes para o navegador
- `Timed out` → Carregamento muito lento

---

## 📊 Estatísticas dos Sprites

| Arquivo | Tamanho (PNG) | Base64 | Status |
|---------|---------------|--------|--------|
| rat | 682 KB | 931 KB | ✅ |
| skeleton | 910 KB | 1.2 MB | ✅ |
| dragon | 837 KB | 1.1 MB | ✅ |
| troll | 766 KB | 1.0 MB | ✅ |
| spider | 747 KB | 1.0 MB | ✅ |
| **Total (14 monstros)** | **~10 MB** | **~14 MB** | ✅ |

---

## 🚀 Se Nada Funcionar

### Opção A: Usar Sprites Locais (Pillow)

Os sprites locais são menores (~300 bytes cada) mas com qualidade inferior:

```bash
cd /data/repos/megarealms
git checkout 4dc3540  # Versão com sprites Pillow
```

### Opção B: Otimizar Sprites AI

Comprimir PNGs para reduzir tamanho:

```bash
cd /data/repos/megarealms
# Instalar pngquant se necessário
brew install pngquant  # Mac
apt install pngquant   # Linux

# Comprimir sprites (perda mínima de qualidade)
pngquant --quality=80-95 assets/sprites/monsters/improved/*.png --ext .png --force
python3 integrate_sprites.py  # Reintegrar
```

### Opção C: Carregar Sprites Externos

Ao invés de base64 inline, carregar como arquivos externos:
- Menores (~700KB) ao invés de base64 (~900KB)
- Cache funciona melhor
- Requer servidor web (não funciona com file://)

---

## ✅ Confirmação Final

Depois de limpar o cache, você deve ver:
- ✅ Sprites em alta qualidade (Tibia 7.x style)
- ✅ Cores vibrantes e definidas
- ✅ Contornos pretos nítidos
- ✅ Detalhes visíveis nos monstros

Se ainda ver sprites pixelados/simples, o cache não foi limpo!

---

**Última atualização:** 2026-02-26 10:50 GMT-3
