# 🔍 MegaRealms - Tibia Research Document

**Data:** 2026-02-26  
**Agente:** Pesquisador Tibia  
**Objetivo:** Identificar elementos do Tibia adaptáveis ao MegaRealms

---

## 📋 Índice

- [A) CRIATURAS E MONSTROS](#a-criaturas-e-monstros)
- [B) ITENS E EQUIPAMENTOS](#b-itens-e-equipamentos)
- [C) SISTEMAS DE JOGO](#c-sistemas-de-jogo)
- [D) MAPAS E AMBIENTES](#d-mapas-e-ambientes)
- [E) SPRITES E VISUAL](#e-sprites-e-visual)

---

## A) CRIATURAS E MONSTROS

### IDEIA #1: Rotworm - Criatura Iniciante
**CATEGORIA:** A  
**REFERÊNCIA TIBIA:** Rotworms são vermes gigantes com mandíbulas moedoras, encontrados em túneis úmidos. São um dos primeiros desafios significativos para novos jogadores após Rookgaard. Deixam corpses e podem dropar ham, gold coins.  
**ADAPTAÇÃO MEGAREALMS:** Adicionar Rotworm como inimigo de nível 2-4, encontrado em áreas de caverna. Comportamento: patrulha lenta em corredores. Drop: small meat (healing item), 1-5 gold. HP: 65, ataque corpo-a-corpo fraco.  
**PRIORIDADE:** Alta  
**DIFICULDADE:** Fácil

---

### IDEIA #2: Cyclops - Monstro Médio
**CATEGORIA:** A  
**REFERÊNCIA TIBIA:** Humanoides gigantes de um olho só, nível ~20-30. Encontrados em Cyclopolis e outras áreas. Dropam club, meat, gold, chain armor. Evocam memórias nostálgicas de treino de skills.  
**ADAPTAÇÃO MEGAREALMS:** Boss de área na cidade subterrânea "Cyclopolis". HP: 260, ataque poderoso de porrada. Drop raro: club weapon (+3 atk). Comportamento: agressivo, persegue jogador por longa distância.  
**PRIORIDADE:** Média  
**DIFICULDADE:** Médio

---

### IDEIA #3: Dragon - Criatura Icônica
**CATEGORIA:** A  
**REFERÊNCIA TIBIA:** Dragões são criaturas lendárias, parte do logo do jogo. Matar o primeiro dragon é um marco. São encontrados em Dragon Lairs. Podem atacar com fogo e corpo-a-corpo. Drop valioso: dragon ham, dragon shield.  
**ADAPTAÇÃO MEGAREALMS:** Mini-boss raro em áreas vulcânicas. HP: 1000, breath weapon de fogo (AOE 3x3). Drop: dragon scale (crafting material), rare dragon shield (+8 def). Animação de voo idle.  
**PRIORIDADE:** Alta  
**DIFICULDADE:** Médio

---

### IDEIA #4: Demon - Lendário Boss
**CATEGORIA:** A  
**REFERÊNCIA TIBIA:** Historicamente o monstro mais forte do Tibia. Servant de Zathroth. Requer times de alto nível para matar. Drop: demon armor, golden legs, magic sword. Extremamente raro.  
**ADAPTAÇÃO MEGAREALMS:** Raid boss que spawna 1x por dia em local aleatório. HP: 8000, múltiplos ataques (fire, energy, melee). Sistema de participação para loot compartilhado. Drop lendário: demon armor (melhor armor do jogo).  
**PRIORIDADE:** Baixa  
**DIFICULDADE:** Difícil

---

### IDEIA #5: Comportamento - Fuga com Baixa Vida
**CATEGORIA:** A  
**REFERÊNCIA TIBIA:** Algumas criaturas fogem quando HP cai abaixo de 20%, tornando a caça mais dinâmica e frustrante (mas realista).  
**ADAPTAÇÃO MEGAREALMS:** Implementar AI flee behavior: monstros com <20% HP tentam fugir do jogador. Aplica a: deer, rabbit, weak enemies. Adiciona desafio de chase.  
**PRIORIDADE:** Média  
**DIFICULDADE:** Fácil

---

### IDEIA #6: Loot com Raridade
**CATEGORIA:** A  
**REFERÊNCIA TIBIA:** Sistema de drops com % de chance. Sempre drop de gold/comum, às vezes rare items. Creates excitement.  
**ADAPTAÇÃO MEGAREALMS:** Sistema de loot tables: Common (100%), Uncommon (25%), Rare (5%), Epic (1%). Cada monstro tem tabela própria. Display de "Rare Drop!" com efeito visual.  
**PRIORIDADE:** Alta  
**DIFICULDADE:** Médio

---

### IDEIA #7: Criaturas por Bioma
**CATEGORIA:** A  
**REFERÊNCIA TIBIA:** Deer/rabbits em florestas, slimes perto de água, dwarves em minas, demons no subsolo profundo. Lógica ambiental.  
**ADAPTAÇÃO MEGAREALMS:** Distribuição lógica: Floresta (deer, wolf, bear), Caverna (bat, rotworm, spider), Deserto (scorpion, snake), Gelo (ice golem, yeti), Vulcão (dragon, hell hound).  
**PRIORIDADE:** Alta  
**DIFICULDADE:** Fácil

---

### IDEIA #8: Hydra - Multi-Cabeça Boss
**CATEGORIA:** A  
**REFERÊNCIA TIBIA:** Hydra tem múltiplas cabeças que atacam simultaneamente. Boss challenge de médio-alto nível.  
**ADAPTAÇÃO MEGAREALMS:** Boss com 3 "cabeças" (3 alvos separados mas HP compartilhado). Cada cabeça ataca diferente: poison, ice, fire. Deve matar todas 3 simultaneamente.  
**PRIORIDADE:** Baixa  
**DIFICULDADE:** Difícil

---

### IDEIA #9: Orc - Humanoid Army
**CATEGORIA:** A  
**REFERÊNCIA TIBIA:** Orcs são uma raça comum, aparecem em grupos. Variedades: Orc Spearman, Orc Warrior, Orc Shaman. Encontrados em Orc Fortress.  
**ADAPTAÇÃO MEGAREALMS:** "Orc Camp" area com 3 tipos: Orc Grunt (melee), Orc Archer (distance), Orc Shaman (healer). Spawnam em grupos de 2-4. Shaman cura outros orcs (priority target).  
**PRIORIDADE:** Média  
**DIFICULDADE:** Médio

---

### IDEIA #10: Comportamento Agressivo vs Passivo
**CATEGORIA:** A  
**REFERÊNCIA TIBIA:** Deer são passivos (só atacam se atacados), Dragons são agressivos (atacam on sight). Cria variedade estratégica.  
**ADAPTAÇÃO MEGAREALMS:** Tag de comportamento: PASSIVE (deer, rabbit), NEUTRAL (wolf, apenas se provocado), AGGRESSIVE (skeleton, dragon, demon). Afeta AI pathfinding.  
**PRIORIDADE:** Média  
**DIFICULDADE:** Fácil

---

## B) ITENS E EQUIPAMENTOS

### IDEIA #11: Sistema de Armas por Tipo
**CATEGORIA:** B  
**REFERÊNCIA TIBIA:** Swords, Axes, Clubs cada um com skill separado. Players especializam em um tipo. Variedade: Spike Sword, Fire Sword, Golden Axe, etc.  
**ADAPTAÇÃO MEGAREALMS:** 3 tipos de arma melee: Sword (balanced), Axe (high damage, slow), Club (fast, low damage). Cada tipo tem progression: wooden → iron → steel → mythril → dragon.  
**PRIORIDADE:** Alta  
**DIFICULDADE:** Médio

---

### IDEIA #12: Potions - Healing Consumables
**CATEGORIA:** B  
**REFERÊNCIA TIBIA:** Health Potions restauram HP instantaneamente. Variedades: Health Potion (100HP), Strong (200), Great (400), Ultimate (800), Supreme (1100). Cooldown de 2s.  
**ADAPTAÇÃO MEGAREALMS:** 4 tiers de potion: Small (50HP), Medium (150HP), Large (350HP), Supreme (750HP). Cooldown 3s, podem ser craftadas ou dropadas. Animação de beber.  
**PRIORIDADE:** Alta  
**DIFICULDADE:** Fácil

---

### IDEIA #13: Armor Sets por Nível
**CATEGORIA:** B  
**REFERÊNCIA TIBIA:** Leather Armor (lv1) → Chain Armor (lv10) → Plate Armor (lv20) → Magic Plate Armor (lv40) → Demon Armor (lv100+). Progression clara.  
**ADAPTAÇÃO MEGAREALMS:** Progression de armor: Cloth (0 def) → Leather (2 def) → Chain Mail (5 def) → Plate Armor (10 def) → Dragon Scale (15 def) → Demon Plate (20 def). Requer level para equipar.  
**PRIORIDADE:** Alta  
**DIFICULDADE:** Médio

---

### IDEIA #14: Runes - Spell Stones
**CATEGORIA:** B  
**REFERÊNCIA TIBIA:** Runes são spells em pedra que podem ser usadas por qualquer vocação (se tiver magic level). Great Fireball Rune, Ultimate Healing Rune, Sudden Death. Cooldown 2s.  
**ADAPTAÇÃO MEGAREALMS:** Sistema de runes consumíveis: Fire Rune (10 dmg AOE), Ice Rune (8 dmg + slow), Heal Rune (100 HP). Stackable (max 10), encontradas ou craftadas. Hotkey para uso rápido.  
**PRIORIDADE:** Média  
**DIFICULDADE:** Médio

---

### IDEIA #15: Quest Rewards - Unique Items
**CATEGORIA:** B  
**REFERÊNCIA TIBIA:** Quests dão items únicos não-dropáveis: Magic Sword (Demon Helmet Quest), Blessed Shield (Annihilator). Incentiva exploração.  
**ADAPTAÇÃO MEGAREALMS:** Quest-only items: "Ancient Blade" (complete Forgotten Temple), "Phoenix Shield" (kill Fire Boss 10x). Stats superiores, visual único. Bind on pickup.  
**PRIORIDADE:** Baixa  
**DIFICULDADE:** Médio

---

### IDEIA #16: Food System
**CATEGORIA:** B  
**REFERÊNCIA TIBIA:** Food regenera HP lentamente: Ham, Meat, Bread, Cheese. Stackable. Barato mas útil para early game.  
**ADAPTAÇÃO MEGAREALMS:** Food items: Bread (5 HP/s por 30s), Meat (8 HP/s por 20s), Fish (regen mana). Pode ser craftado de monster drops (wolf meat, fish from lakes). Inventory item.  
**PRIORIDADE:** Média  
**DIFICULDADE:** Fácil

---

### IDEIA #17: Distance Weapons - Bows/Crossbows
**CATEGORIA:** B  
**REFERÊNCIA TIBIA:** Paladins usam distance weapons: bows + arrows ou crossbows + bolts. Require ammunition. Royal Spear, Composite Hornbow.  
**ADAPTAÇÃO MEGAREALMS:** Classe Archer: equipar bow + arrows (arrows são consumíveis). Ataque ranged de 5 tiles. Arrows: wooden (2 dmg), iron (5 dmg), fire (8 dmg + burn DOT).  
**PRIORIDADE:** Média  
**DIFICULDADE:** Médio

---

### IDEIA #18: Shields - Defense Slots
**CATEGORIA:** B  
**REFERÊNCIA TIBIA:** Knights usam shields para aumentar defense. Wooden Shield, Steel Shield, Dragon Shield, Demon Shield. Shielding skill reduz damage tomado.  
**ADAPTAÇÃO MEGAREALMS:** Equipment slot de shield (só para warrior class). Shields: +2 to +12 defense. Chance de "block" (20%) que nega 50% do dano. Animação de defesa.  
**PRIORIDADE:** Média  
**DIFICULDADE:** Médio

---

### IDEIA #19: Rings e Amulets - Accessories
**CATEGORIA:** B  
**REFERÊNCIA TIBIA:** Rings (Life Ring, Might Ring) e Amulets (Protection Amulet, Stone Skin Amulet) dão buffs temporários. Têm durabilidade (charges).  
**ADAPTAÇÃO MEGAREALMS:** Accessory slots: Ring (passivo: +HP, +mana, +regen) e Amulet (ativo: usar para buff temporário). Ring of Health (+50 max HP), Amulet of Protection (use: +5 def por 60s). Limited uses (10 charges).  
**PRIORIDADE:** Baixa  
**DIFICULDADE:** Médio

---

### IDEIA #20: Equipment Upgrade/Enchantment
**CATEGORIA:** B  
**REFERÊNCIA TIBIA:** Equipment Upgrade system: adicionar special effects usando Dust, Slivers, Cores. Onslaught (weapons), Ruse (armors). Tiers progressivos.  
**ADAPTAÇÃO MEGAREALMS:** Sistema de enchant simples: usar "Enchant Scroll" + item + gold para adicionar bonus. Fire Enchant (+5 fire dmg), Defense Enchant (+3 def). Max 1 enchant por item. Scrolls são raros.  
**PRIORIDADE:** Baixa  
**DIFICULDADE:** Difícil

---

## C) SISTEMAS DE JOGO

### IDEIA #21: Vocations - Classes
**CATEGORIA:** C  
**REFERÊNCIA TIBIA:** 4 vocations: Knight (tank melee), Paladin (ranged), Sorcerer (offensive magic), Druid (healing/support magic). Cada uma com skills e spells únicos.  
**ADAPTAÇÃO MEGAREALMS:** 3 classes no início: Warrior (melee, high HP), Archer (ranged, medium HP), Mage (spells, low HP). Escolha no character creation. Afeta stats base, equipment disponível, skill tree.  
**PRIORIDADE:** Alta  
**DIFICULDADE:** Difícil

---

### IDEIA #22: Skills - Trainable Abilities
**CATEGORIA:** C  
**REFERÊNCIA TIBIA:** Skills melhoram com uso: Sword Skill (usar swords), Magic Level (cast spells), Shielding (tomar hits com shield). Progresso lento = rewarding.  
**ADAPTAÇÃO MEGAREALMS:** Skill system simplificado: Combat (melee damage), Defense (reduce damage), Magic Power (spell effectiveness). Aumentam automaticamente ao matar monstros (XP do skill separado de level XP). Display no UI.  
**PRIORIDADE:** Média  
**DIFICULDADE:** Médio

---

### IDEIA #23: Spell System
**CATEGORIA:** C  
**REFERÊNCIA TIBIA:** Spells são aprendidos em levels específicos e custam mana. Knights: Berserk, Groundshaker. Sorcerers: Hell's Core, Sudden Death. Druids: Mass Healing, Icicle.  
**ADAPTAÇÃO MEGAREALMS:** Mage class aprende spells automaticamente ao subir level. Lv5: Fireball (20 mana, 30 dmg), Lv10: Ice Blast (30 mana, 40 dmg + slow), Lv15: Healing (25 mana, 80 HP). Hotbar para quick cast.  
**PRIORIDADE:** Média  
**DIFICULDADE:** Difícil

---

### IDEIA #24: Party/Team System
**CATEGORIA:** C  
**REFERÊNCIA TIBIA:** Players formam party para shared XP e coordenação. Party chat, leader system, XP bonus por teamhunt.  
**ADAPTAÇÃO MEGAREALMS:** Sistema de party: convidar até 3 players. XP compartilhado em área (split + 10% bonus). Nomes de party members em cor diferente. Party chat tab.  
**PRIORIDADE:** Baixa  
**DIFICULDADE:** Difícil

---

### IDEIA #25: PvP Zones
**CATEGORIA:** C  
**REFERÊNCIA TIBIA:** Protected zones (cities), Optional PvP (precisa atacar de volta), Hardcore PvP (full loot). Variedade de risco.  
**ADAPTAÇÃO MEGAREALMS:** Safe zones (cidades), PvP zones (arenas específicas). Em PvP zone: players podem atacar uns aos outros, morte não perde items mas perde 10% XP. Arena com ranking.  
**PRIORIDADE:** Baixa  
**DIFICULDADE:** Difícil

---

### IDEIA #26: Guild System
**CATEGORIA:** C  
**REFERÊNCIA TIBIA:** Guilds com nome, logo, guild hall, wars entre guilds. Social aspect importante.  
**ADAPTAÇÃO MEGAREALMS:** Sistema básico de guild: criar guild (100 gold), convidar membros (max 10), guild tag aparece antes do nome. Guild chat channel. Future: guild wars, guild hall.  
**PRIORIDADE:** Baixa  
**DIFICULDADE:** Difícil

---

### IDEIA #27: Death Penalty
**CATEGORIA:** C  
**REFERÊNCIA TIBIA:** Morrer = perder XP (5-10%), perder skills, drop items (em alguns servers). Alto stakes cria tensão.  
**ADAPTAÇÃO MEGAREALMS:** Morte = respawn na cidade, perde 5% do XP do level atual, perde metade do gold inventory. Items no chão no local da morte (pode voltar para pegar, 2 min timer). Temple como safe respawn point.  
**PRIORIDADE:** Média  
**DIFICULDADE:** Fácil

---

### IDEIA #28: Cooldown System
**CATEGORIA:** C  
**REFERÊNCIA TIBIA:** Spells têm cooldown individual (1-2s) e group cooldown. Prevents spam, adds strategy.  
**ADAPTAÇÃO MEGAREALMS:** Cooldowns visuais: circle indicator ao redor do spell icon. Group cooldown: offensive spells compartilham 2s, healing spells 3s. Potion cooldown 4s.  
**PRIORIDADE:** Média  
**DIFICULDADE:** Médio

---

### IDEIA #29: Mana System
**CATEGORIA:** C  
**REFERÊNCIA TIBIA:** Mana bar regenera lentamente (mais rápido para mages). Mana potions restauram instantaneamente. Spells custam mana.  
**ADAPTAÇÃO MEGAREALMS:** Implementar mana bar (100 base, 200 para mages). Regen: 2 mana/s (5 mana/s para mages). Spells custam 10-50 mana. Mana potions: Small (30), Medium (80), Large (150).  
**PRIORIDADE:** Alta  
**DIFICULDADE:** Médio

---

### IDEIA #30: Level Progression
**CATEGORIA:** C  
**REFERÊNCIA TIBIA:** Level up aumenta HP, mana, capacity. Curve exponencial (lv1-50 fácil, 50-100 médio, 100+ slow). Sense of achievement.  
**ADAPTAÇÃO MEGAREALMS:** XP curve: level 1-10 (100 XP each), 10-20 (300 XP), 20-30 (800 XP), etc. Level up: +20 HP, +10 mana, +5 capacity, unlock de novos equipments/áreas. Visual effect + sound.  
**PRIORIDADE:** Alta  
**DIFICULDADE:** Médio

---

## D) MAPAS E AMBIENTES

### IDEIA #31: Thais - Capital City
**CATEGORIA:** D  
**REFERÊNCIA TIBIA:** Thais é a cidade principal, hub inicial. Tem depot, shops, temple, training areas próximos. Nostalgia central.  
**ADAPTAÇÃO MEGAREALMS:** Criar "Thais City" como spawn inicial. Elementos: Temple (respawn point), Depot (storage), Shops (weapons, potions, food), Training dummy area, Quest NPCs. Safe zone (no combat).  
**PRIORIDADE:** Alta  
**DIFICULDADE:** Médio

---

### IDEIA #32: Depot - Storage System
**CATEGORIA:** D  
**REFERÊNCIA TIBIA:** Depot é banco onde players guardam items. Todos depots conectados. Essencial para inventory management.  
**ADAPTAÇÃO MEGAREALMS:** Depot NPC/building em cada cidade. Interface de storage: 50 slots extra. Items guardados são compartilhados entre todos depots. Organize por categoria (weapons, potions, misc).  
**PRIORIDADE:** Média  
**DIFICULDADE:** Médio

---

### IDEIA #33: Temple - Respawn Point
**CATEGORIA:** D  
**REFERÊNCIA TIBIA:** Temple é onde players respawn após morte. Pode mudar temple para outra cidade. Safe zone.  
**ADAPTAÇÃO MEGAREALMS:** Temple building em cada cidade. Falar com NPC para set como respawn point. Funciona como checkpoint. Animação de "holy light" ao respawnar.  
**PRIORIDADE:** Alta  
**DIFICULDADE:** Fácil

---

### IDEIA #34: Dungeon Design - Mintwallin Style
**CATEGORIA:** D  
**REFERÊNCIA TIBIA:** Mintwallin é cidade minotaur subterrânea, maze-like, sob Ancient Temple. Multi-level dungeon com loot progressivo.  
**ADAPTAÇÃO MEGAREALMS:** Dungeon "Minotaur Maze": 3 andares underground. Level 1 (weak minotaurs), Level 2 (strong minotaurs + traps), Level 3 (Minotaur King boss). Loot chest no final.  
**PRIORIDADE:** Média  
**DIFICULDADE:** Médio

---

### IDEIA #35: NPCs com Diálogos
**CATEGORIA:** D  
**REFERÊNCIA TIBIA:** NPCs respondem a keywords: "hi", "trade", "quest", "bye". Dialog tree complexo, parte da lore.  
**ADAPTAÇÃO MEGAREALMS:** Sistema de NPC dialog: clicar abre chat box. Options: "Trade" (shop), "Quest" (se disponível), "Rumors" (hints), "Goodbye". NPC pode dar quests multi-step.  
**PRIORIDADE:** Média  
**DIFICULDADE:** Médio

---

### IDEIA #36: Biomas Visuais Distintos
**CATEGORIA:** D  
**REFERÊNCIA TIBIA:** Floresta (green grass, trees), Deserto (sand, cactus), Gelo (snow, ice), Vulcão (lava, rocks). Visual cues ajudam navegação.  
**ADAPTAÇÃO MEGAREALMS:** 5 biomas com tiles únicos: 1) Grassland (green), 2) Desert (yellow sand), 3) Snow (white), 4) Volcanic (red/black), 5) Cave (gray stone). Criaturas apropriadas por bioma.  
**PRIORIDADE:** Alta  
**DIFICULDADE:** Médio

---

### IDEIA #37: Bridges e Water Mechanics
**CATEGORIA:** D  
**REFERÊNCIA TIBIA:** Water blocks movement, bridges permitem cruzar. Alguns items afundam na água. Boats para travel marítimo.  
**ADAPTAÇÃO MEGAREALMS:** Water tiles = impassable. Bridge tiles sobre water = passable. Future: boat item para navegar, alguns monstros em water (fish, sea serpent). Items dropados em water = perdidos.  
**PRIORIDADE:** Baixa  
**DIFICULDADE:** Médio

---

### IDEIA #38: Secret Passages
**CATEGORIA:** D  
**REFERÊNCIA TIBIA:** Paredes secretas que se abrem ao usar alavancas, hidden paths atrás de bookshelves. Exploration reward.  
**ADAPTAÇÃO MEGAREALMS:** Mechanic de hidden walls: parecem wall normal, mas ao "use" (click) abrem. Revelam treasure rooms ou atalhos. Visual hint sutil (small crack). Dica em NPC rumors.  
**PRIORIDADE:** Baixa  
**DIFICULDADE:** Médio

---

### IDEIA #39: Training Areas
**CATEGORIA:** D  
**REFERÊNCIA TIBIA:** Monk training: dummies que não morrem, para treinar skills AFK (exercise weapons). Premium feature.  
**ADAPTAÇÃO MEGAREALMS:** Training dummies em cidade: não dão XP, mas aumentam Combat/Magic skills lentamente. Free (sem exercise weapons). Good para iniciantes entenderem combat mechanics.  
**PRIORIDADE:** Baixa  
**DIFICULDADE:** Fácil

---

### IDEIA #40: Quest Markers e Storylines
**CATEGORIA:** D  
**REFERÊNCIA TIBIA:** Quests como Annihilator, Demon Helmet, Pits of Inferno. Lore-rich, multi-step, rewards valiosos.  
**ADAPTAÇÃO MEGAREALMS:** Quest system: NPC com "!" acima da cabeça. Accept quest → objectives (kill X, find Y) → return for reward. Quest log no UI. 5 quests iniciais simples, 3 quests avançadas (lv 20+).  
**PRIORIDADE:** Média  
**DIFICULDADE:** Médio

---

## E) SPRITES E VISUAL

### IDEIA #41: Manter 32x32 Pixel Art
**CATEGORIA:** E  
**REFERÊNCIA TIBIA:** Sprites 32x32 são icônicos, criam constraint criativo que força clareza visual. Facilita criação de assets.  
**ADAPTAÇÃO MEGAREALMS:** Continuar usando 32x32 para consistência. Novos sprites (items, tiles, monsters) devem seguir essa dimensão. Alguns bosses podem ser 64x64 (2x2 grid).  
**PRIORIDADE:** Alta  
**DIFICULDADE:** Fácil

---

### IDEIA #42: Paleta de Cores por Bioma
**CATEGORIA:** E  
**REFERÊNCIA TIBIA:** Cores limitadas, estratégicas. Floresta = greens, Deserto = yellows/browns, Gelo = blues/whites, Vulcão = reds/oranges. Coesão visual.  
**ADAPTAÇÃO MEGAREALMS:** Definir paletas: Grassland (6 shades green), Desert (5 shades yellow/tan), Snow (4 shades blue/white), Volcanic (6 shades red/orange/black), Cave (5 shades gray). Stick to palette rigorosamente.  
**PRIORIDADE:** Alta  
**DIFICULDADE:** Fácil

---

### IDEIA #43: Animações de Ataque
**CATEGORIA:** E  
**REFERÊNCIA TIBIA:** Player swing sword cria slash effect. Spells têm projectile animation (fireball traveling). Blood splatter ao hit.  
**ADAPTAÇÃO MEGAREALMS:** Attack animations: Melee (weapon swing sprite aparece 0.2s), Ranged (arrow sprite travel), Magic (spell projectile + impact effect). Hit = brief red flash no monster. Death = corpse sprite + fade out.  
**PRIORIDADE:** Média  
**DIFICULDADE:** Médio

---

### IDEIA #44: Efeitos Visuais de Magia
**CATEGORIA:** E  
**REFERÊNCIA TIBIA:** Spell effects coloridos: Fireball (red/orange), Ice (blue/white), Energy (purple), Earth (green/brown). Reconhecíveis instantaneamente.  
**ADAPTAÇÃO MEGAREALMS:** Spell VFX: Fireball (red particle burst), Ice Blast (blue shatter), Lightning (white zig-zag), Heal (green sparkles rising). Use particle system simples (5-10 particles, 0.5s lifetime).  
**PRIORIDADE:** Média  
**DIFICULDADE:** Médio

---

### IDEIA #45: Corpse Sprites
**CATEGORIA:** E  
**REFERÊNCIA TIBIA:** Cada creature tem corpse sprite único. Corpse desaparece após 1 min. Pode ser "opened" para loot.  
**ADAPTAÇÃO MEGAREALMS:** Ao morrer, monster deixa corpse sprite (versão "deitada" do monster). Clicar corpse abre loot window. Corpse fade out após 60s. Items no chão aparecem como sprites pequenos.  
**PRIORIDADE:** Média  
**DIFICULDADE:** Fácil

---

### IDEIA #46: Oblique Projection (não Isometric)
**CATEGORIA:** E  
**REFERÊNCIA TIBIA:** Tibia usa oblique projection, não isometric verdadeiro. Dá seu visual único, mas é mais simples de desenhar.  
**ADAPTAÇÃO MEGAREALMS:** MegaRealms já usa top-down 2D (mais simples que oblique). Manter consistência: objetos vistos de cima, sombras simples para profundidade. Não tentar isometric.  
**PRIORIDADE:** Alta  
**DIFICULDADE:** Fácil

---

### IDEIA #47: Item Icons Consistentes
**CATEGORIA:** E  
**REFERÊNCIA TIBIA:** Items têm icons 32x32 claros: sword (metal blade), potion (flask shape), gold coin (round yellow). Instant recognition.  
**ADAPTAÇÃO MEGAREALMS:** Redesign items para clarity: Potion (clear flask shape + cor do líquido), Sword (blade + hilt distinct), Gold (coin stack). Use shading para depth. Test na resolução nativa (não zoom).  
**PRIORIDADE:** Média  
**DIFICULDADE:** Fácil

---

### IDEIA #48: Decoração de Mapa - Árvores e Rochas
**CATEGORIA:** E  
**REFERÊNCIA TIBIA:** Trees, rocks, mushrooms, flowers adicionam vida ao mapa. Alguns bloqueiam movimento, outros são só decoração.  
**ADAPTAÇÃO MEGAREALMS:** Adicionar decoração ambiental: Trees (block movement), Small bushes (deco only), Rocks (block, têm HP, podem ser minerados?), Flowers (deco). Distribui aleatoriamente em grassland.  
**PRIORIDADE:** Média  
**DIFICULDADE:** Fácil

---

### IDEIA #49: Day/Night Cycle Visual
**CATEGORIA:** E  
**REFERÊNCIA TIBIA:** Em áreas externas, luz muda entre dia/noite. Cria atmosfera, não afeta gameplay muito.  
**ADAPTAÇÃO MEGAREALMS:** Sistema de lighting simples: Dia (tiles em cor normal), Noite (tiles com overlay azul escuro 30% opacity). Cycle 20 min real-time. Opcional: alguns monsters só spawnam à noite.  
**PRIORIDADE:** Baixa  
**DIFICULDADE:** Médio

---

### IDEIA #50: Teleport Effect
**CATEGORIA:** E  
**REFERÊNCIA TIBIA:** Teleports têm visual distinct: swirl effect, player desaparece e reaparece. Sound effect.  
**ADAPTAÇÃO MEGAREALMS:** Teleport tiles (magic stairs/portals): usar sprite animado (3-4 frames rotating). Ao entrar: flash effect branco, player desaparece, aparece em destino com mesmo flash. Sound: "whoosh".  
**PRIORIDADE:** Baixa  
**DIFICULDADE:** Médio

---

## 📊 Resumo por Categoria

| Categoria | Ideias | Prioridade Alta | Prioridade Média | Prioridade Baixa |
|-----------|--------|-----------------|------------------|------------------|
| **A) Criaturas** | 10 | 3 | 4 | 3 |
| **B) Itens** | 10 | 3 | 5 | 2 |
| **C) Sistemas** | 10 | 3 | 5 | 2 |
| **D) Mapas** | 10 | 3 | 5 | 2 |
| **E) Visual** | 10 | 4 | 5 | 1 |
| **TOTAL** | **50** | **16** | **24** | **10** |

---

## 🎯 Recomendações de Implementação

### FASE 1 (Rápidas Wins - Alta Prioridade + Fácil)
1. ✅ Rotworm criatura (#1)
2. ✅ Dragon boss (#3)
3. ✅ Fuga com baixa vida (#5)
4. ✅ Criaturas por bioma (#7)
5. ✅ Potions healing (#12)
6. ✅ Armor sets (#13)
7. ✅ Temple respawn (#33)
8. ✅ Biomas visuais (#36)
9. ✅ Manter 32x32 (#41)
10. ✅ Paleta por bioma (#42)

### FASE 2 (Features Principais - Média Dificuldade)
1. Sistema de loot com raridade (#6)
2. Sistema de armas por tipo (#11)
3. Vocations/Classes (#21)
4. Mana system (#29)
5. Level progression (#30)
6. Thais City (#31)
7. NPCs com diálogos (#35)
8. Animações de ataque (#43)

### FASE 3 (End-game Content - Difícil)
1. Demon raid boss (#4)
2. Spell system para mages (#23)
3. Party/team system (#24)
4. PvP zones (#25)
5. Equipment enchantment (#20)

---

**FIM DO DOCUMENTO DE PESQUISA**

*Total de ideias documentadas: 50*  
*Pronto para aprovação e início da implementação!*
