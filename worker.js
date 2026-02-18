// MegaRealms Authoritative Game Server - Cloudflare Worker with Durable Objects
// GameRoom DO: per-floor multiplayer state
// PlayerState DO: per-player authoritative state

import {
  MONS, ITEMS, QUEST_DEFS, SPELLS, VOCS,
  VOC_SKILL_MULT, DJINN_LOOT_PRICES, BLESSING_COST, PREMIUM_COST,
  xpNeeded, calcDamage, calcMonsterDamage, getSkillMult, skillXpNeeded,
  getDjinnPrice, getGreyDjinnPrice
} from './game-data.js';

// ============================================================================
// PLAYER STATE DURABLE OBJECT
// ============================================================================

export class PlayerState {
  constructor(state, env) {
    this.state = state;
    this.env = env;
    this.charId = null;
    this.data = null; // In-memory player state
    this.lastAttackTime = 0;
    this.lastSellTime = 0;
    this.spellCooldowns = new Map(); // spellId -> timestamp
    this.lastSaveTime = 0;
  }

  async fetch(request) {
    const url = new URL(request.url);
    const method = request.method;
    const pathname = url.pathname;

    // Extract character ID from query or header
    const charId = url.searchParams.get('charId');
    if (charId) this.charId = charId;

    // Check Authorization header for all /player routes
    if (pathname.startsWith('/player/')) {
      const auth = request.headers.get('Authorization');
      if (!auth || !auth.startsWith('Bearer ')) {
        return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 });
      }
    }

    try {
      if (pathname === '/player/load' && method === 'POST') {
        return await this.handleLoad(request);
      } else if (pathname === '/player/action' && method === 'POST') {
        return await this.handleAction(request);
      } else if (pathname === '/player/state' && method === 'GET') {
        return await this.handleGetState();
      }
    } catch (e) {
      console.error('PlayerState error:', e);
      return new Response(JSON.stringify({ error: e.message }), { status: 500 });
    }

    return new Response(JSON.stringify({ error: 'Not found' }), { status: 404 });
  }

  async handleLoad(request) {
    const body = await request.json();
    const { charId, data } = body;
    this.charId = charId;

    // Load from storage or initialize
    const stored = await this.state.storage.get('player');
    if (stored) {
      this.data = stored;
    } else if (data) {
      // First load: accept client data and validate
      this.data = this.validatePlayerData(data);
      await this.saveToStorage();
    } else {
      throw new Error('No saved data and no initial data provided');
    }

    return this.jsonResponse({ ok: 1, data: this.getSanitizedState() });
  }

  async handleAction(request) {
    const body = await request.json();
    const { charId, action } = body;
    this.charId = charId;

    // Ensure data is loaded
    if (!this.data) {
      const stored = await this.state.storage.get('player');
      if (!stored) {
        throw new Error('Player not found');
      }
      this.data = stored;
    }

    // Route to appropriate action handler
    let result = {};
    switch (action.type) {
      case 'attack':
        result = this.handleAttack(action);
        break;
      case 'spell':
        result = this.handleSpell(action);
        break;
      case 'loot':
        result = this.handleLoot(action);
        break;
      case 'buy':
        result = this.handleBuy(action);
        break;
      case 'sell':
        result = this.handleSell(action);
        break;
      case 'sell_djinn':
        result = this.handleSellDjinn(action);
        break;
      case 'equip':
        result = this.handleEquip(action);
        break;
      case 'unequip':
        result = this.handleUnequip(action);
        break;
      case 'use':
        result = this.handleUse(action);
        break;
      case 'quest_accept':
        result = this.handleQuestAccept(action);
        break;
      case 'quest_check':
        result = this.handleQuestCheck(action);
        break;
      case 'buy_premium':
        result = this.handleBuyPremium(action);
        break;
      case 'buy_blessing':
        result = this.handleBuyBlessing(action);
        break;
      case 'discard':
        result = this.handleDiscard(action);
        break;
      case 'move':
        result = this.handleMove(action);
        break;
      case 'save':
        result = { ok: 1, ts: Date.now() };
        break;
      default:
        throw new Error('Unknown action type: ' + action.type);
    }

    // Save to storage periodically or on explicit save
    if (action.type === 'save' || Date.now() - this.lastSaveTime > 30000) {
      await this.saveToStorage();
      this.lastSaveTime = Date.now();
    }

    return this.jsonResponse(result);
  }

  async handleGetState() {
    if (!this.data) {
      const stored = await this.state.storage.get('player');
      if (!stored) {
        throw new Error('Player not found');
      }
      this.data = stored;
    }

    return this.jsonResponse({ ok: 1, data: this.getSanitizedState() });
  }

  // ========== ACTION HANDLERS ==========

  handleAttack(action) {
    const now = Date.now();
    if (now - this.lastAttackTime < 200) {
      throw new Error('Attack cooldown');
    }
    this.lastAttackTime = now;

    if (this.data.hp <= 0) {
      throw new Error('Player is dead');
    }

    const tid = action.tid;
    const monDef = MONS[tid]?.def || 0;

    // Calculate player ATK: base + weapon + equipment
    let playerATK = this.data.batk;
    if (this.data.eq.weapon && ITEMS[this.data.eq.weapon]) {
      playerATK += ITEMS[this.data.eq.weapon].atk || 0;
    }

    // Calculate damage
    let dmg = Math.max(1, Math.floor(playerATK - monDef / 2) + Math.floor(Math.random() * 3 - 1));

    const result = {
      dmg,
      monHp: null, // Will be computed by GameRoom
    };

    // XP & level up logic (simplified - actual monster HP tracking is in GameRoom)
    // For now, just return dmg dealt
    return result;
  }

  handleSpell(action) {
    const spellIdx = SPELLS.findIndex(s => s.id === action.sid);
    if (spellIdx === -1) {
      throw new Error('Spell not found');
    }

    const spell = SPELLS[spellIdx];
    const now = Date.now();
    const cooldownTime = this.spellCooldowns.get(spell.id) || 0;

    if (now < cooldownTime) {
      throw new Error('Spell cooldown');
    }

    if (this.data.mp < spell.mana) {
      throw new Error('Not enough mana');
    }

    // Deduct mana
    this.data.mp = Math.max(0, this.data.mp - spell.mana);

    // Set cooldown
    this.spellCooldowns.set(spell.id, now + spell.cd);

    // Handle spell effects
    let result = { mpLeft: this.data.mp };

    if (spell.heal) {
      const oldHp = this.data.hp;
      this.data.hp = Math.min(this.data.mhp, this.data.hp + spell.heal);
      result.hpLeft = this.data.hp;
      result.heal = this.data.hp - oldHp;
    }

    if (spell.buff) {
      // Buff effect tracked (client applies visual, server tracks it)
      result.buff = { type: spell.buff, amt: spell.amt, dur: spell.dur };
    }

    if (spell.dmg) {
      // Damage spell - compute damage
      let playerMatk = 0;
      if (this.data.eq.weapon && ITEMS[this.data.eq.weapon]) {
        playerMatk = ITEMS[this.data.eq.weapon].matk || 0;
      }
      const monDef = action.tid ? (MONS[action.tid]?.def || 0) : 0;
      const dmg = Math.max(1, Math.floor((playerMatk || this.data.batk) * (spell.dmg / 100)) - Math.floor(monDef / 3));
      result.dmg = dmg;
    }

    // Add skill XP
    const skillXp = Math.max(1, Math.floor(spell.mana / 10));
    if (!this.data.skillXp.magic) this.data.skillXp.magic = 0;
    this.data.skillXp.magic += skillXp;
    this.checkSkillLevelUp('magic');

    return result;
  }

  handleLoot(action) {
    const items = action.items || [];

    for (const item of items) {
      if (item.id === 'gold_coin') {
        this.data.gold = Math.min(99999999, this.data.gold + item.q);
      } else {
        this.addItem(this.data.inv, item.id, item.q);
      }
    }

    return { inv: this.data.inv, gold: this.data.gold };
  }

  handleBuy(action) {
    const itemId = action.itemId;
    const item = ITEMS[itemId];

    if (!item) {
      throw new Error('Item not found');
    }

    if (this.data.gold < item.p) {
      throw new Error('Not enough gold');
    }

    if (this.data.inv.length >= 30) {
      throw new Error('Inventory full');
    }

    // Check vocation restrictions
    if (item.vocs && !item.vocs.includes(this.data.voc)) {
      throw new Error('Cannot equip this item');
    }

    this.data.gold -= item.p;
    this.addItem(this.data.inv, itemId, 1);

    return { gold: this.data.gold, inv: this.data.inv };
  }

  handleSell(action) {
    const now = Date.now();
    if (now - this.lastSellTime < 500) {
      throw new Error('Sell cooldown');
    }
    this.lastSellTime = now;

    const idx = action.idx;
    if (idx < 0 || idx >= this.data.inv.length) {
      throw new Error('Item not found');
    }

    const invItem = this.data.inv[idx];
    const item = ITEMS[invItem.id];
    const price = Math.floor(item.p / 3);

    this.data.gold = Math.min(99999999, this.data.gold + price);
    this.rmItem(this.data.inv, idx, 1);

    return { gold: this.data.gold, inv: this.data.inv };
  }

  handleSellDjinn(action) {
    const { idx, qty, djinnType } = action;

    if (idx < 0 || idx >= this.data.inv.length) {
      throw new Error('Item not found');
    }

    const invItem = this.data.inv[idx];
    if (invItem.q < qty) {
      throw new Error('Not enough items');
    }

    const pricePerItem = djinnType === 'grey'
      ? getGreyDjinnPrice(invItem.id)
      : getDjinnPrice(invItem.id);

    const totalPrice = pricePerItem * qty;
    this.data.gold = Math.min(99999999, this.data.gold + totalPrice);
    this.rmItem(this.data.inv, idx, qty);

    return { gold: this.data.gold, inv: this.data.inv };
  }

  handleEquip(action) {
    const idx = action.idx;
    if (idx < 0 || idx >= this.data.inv.length) {
      throw new Error('Item not found');
    }

    const invItem = this.data.inv[idx];
    const item = ITEMS[invItem.id];

    if (!item || !item.s) {
      throw new Error('Item cannot be equipped');
    }

    const slot = item.s;

    // Unequip current item if any
    if (this.data.eq[slot]) {
      this.addItem(this.data.inv, this.data.eq[slot], 1);
    }

    // Equip new item
    this.data.eq[slot] = invItem.id;
    this.rmItem(this.data.inv, idx, 1);

    // Recalculate stats
    this.recalculateStats();

    return { eq: this.data.eq, inv: this.data.inv };
  }

  handleUnequip(action) {
    const slot = action.slot;

    if (!this.data.eq[slot]) {
      throw new Error('Slot is empty');
    }

    if (this.data.inv.length >= 30) {
      throw new Error('Inventory full');
    }

    this.addItem(this.data.inv, this.data.eq[slot], 1);
    delete this.data.eq[slot];

    // Recalculate stats
    this.recalculateStats();

    return { eq: this.data.eq, inv: this.data.inv };
  }

  handleUse(action) {
    const idx = action.idx;
    if (idx < 0 || idx >= this.data.inv.length) {
      throw new Error('Item not found');
    }

    const invItem = this.data.inv[idx];
    const item = ITEMS[invItem.id];

    if (!item || (item.t !== 'potion' && item.t !== 'food')) {
      throw new Error('Cannot use this item');
    }

    // Check vocation restrictions
    if (item.vocs && !item.vocs.includes(this.data.voc)) {
      throw new Error('Cannot use this item');
    }

    // Apply effects
    if (item.heal) {
      this.data.hp = Math.min(this.data.mhp, this.data.hp + item.heal);
    }
    if (item.mana) {
      this.data.mp = Math.min(this.data.mmp, this.data.mp + item.mana);
    }

    this.rmItem(this.data.inv, idx, 1);

    return { hp: this.data.hp, mp: this.data.mp, inv: this.data.inv };
  }

  handleQuestAccept(action) {
    const qid = action.qid;
    const questDef = QUEST_DEFS.find(q => q.id === qid);

    if (!questDef) {
      throw new Error('Quest not found');
    }

    if (this.data.lv < questDef.lvl) {
      throw new Error('Level too low');
    }

    if (this.data.quests.find(q => q.id === qid)) {
      throw new Error('Quest already accepted');
    }

    this.data.quests.push({
      id: qid,
      progress: 0,
      done: false,
      doneAt: null
    });

    return { quests: this.data.quests };
  }

  handleQuestCheck(action) {
    const now = Date.now();
    const activeQuests = this.data.quests.filter(q => !q.done);
    let xpGain = 0;
    let goldGain = 0;
    const completedQuestIds = [];

    for (const quest of activeQuests) {
      const questDef = QUEST_DEFS.find(q => q.id === quest.id);
      if (!questDef) continue;

      let isCompleted = false;

      if (questDef.type === 'kill') {
        const killCount = this.data.kills[questDef.target] || 0;
        if (killCount >= questDef.need) {
          isCompleted = true;
        }
      } else if (questDef.type === 'collect') {
        const invItem = this.data.inv.find(item => item.id === questDef.target);
        if (invItem && invItem.q >= questDef.need) {
          isCompleted = true;
        }
      }

      if (isCompleted) {
        quest.done = true;
        quest.doneAt = now;
        completedQuestIds.push(quest.id);
        xpGain += questDef.xp || 0;
        goldGain += questDef.gold || 0;

        // Remove collected items if applicable
        if (questDef.type === 'collect') {
          const idx = this.data.inv.findIndex(item => item.id === questDef.target);
          if (idx !== -1) {
            this.rmItem(this.data.inv, idx, questDef.need);
          }
        }
      }
    }

    // Apply XP and gold
    this.data.xp += xpGain;
    this.data.gold = Math.min(99999999, this.data.gold + goldGain);

    // Check level up
    const oldLv = this.data.lv;
    this.checkLevelUp();

    return {
      quests: this.data.quests,
      xp: xpGain,
      lv: this.data.lv,
      levelUp: this.data.lv > oldLv,
      gold: this.data.gold,
      inv: this.data.inv,
      completed: completedQuestIds
    };
  }

  handleBuyPremium(action) {
    if (this.isPremium()) {
      throw new Error('Already premium');
    }

    if (this.data.gold < PREMIUM_COST) {
      throw new Error('Not enough gold');
    }

    this.data.gold -= PREMIUM_COST;
    const now = Date.now();
    this.data.premium = {
      active: true,
      expiry: now + (30 * 24 * 60 * 60 * 1000) // 30 days
    };

    return { gold: this.data.gold, premium: this.data.premium };
  }

  handleBuyBlessing(action) {
    if (!this.isPremium()) {
      throw new Error('Must be premium');
    }

    if (this.data.gold < BLESSING_COST) {
      throw new Error('Not enough gold');
    }

    const idx = action.idx;
    const blessingId = `blessing_${idx}`;

    if (this.data.blessings.includes(blessingId)) {
      throw new Error('Already have this blessing');
    }

    this.data.gold -= BLESSING_COST;
    this.data.blessings.push(blessingId);

    return { gold: this.data.gold, blessings: this.data.blessings };
  }

  handleDiscard(action) {
    const { idx, qty } = action;

    if (idx < 0 || idx >= this.data.inv.length) {
      throw new Error('Item not found');
    }

    this.rmItem(this.data.inv, idx, qty);

    return { inv: this.data.inv };
  }

  handleMove(action) {
    this.data.x = action.x || this.data.x;
    this.data.y = action.y || this.data.y;
    this.data.dir = action.dir !== undefined ? action.dir : this.data.dir;
    this.data.floor = action.floor || this.data.floor;

    return { ok: 1 };
  }

  // ========== HELPER FUNCTIONS ==========

  addItem(inv, id, q) {
    if (!ITEMS[id]) return;

    // Special case: gold_coin adds directly to gold
    if (id === 'gold_coin') {
      this.data.gold = Math.min(99999999, this.data.gold + q);
      return;
    }

    const item = ITEMS[id];

    // Check if stackable and already in inventory
    if (item.stk) {
      const existing = inv.find(i => i.id === id);
      if (existing) {
        existing.q += q;
        return;
      }
    }

    // Add as new item (max 30)
    if (inv.length < 30) {
      inv.push({ id, q });
    }
  }

  rmItem(inv, idx, q) {
    if (idx < 0 || idx >= inv.length) return;
    inv[idx].q -= q;
    if (inv[idx].q <= 0) {
      inv.splice(idx, 1);
    }
  }

  isPremium() {
    return this.data.premium && this.data.premium.active && Date.now() < this.data.premium.expiry;
  }

  checkLevelUp() {
    const voc = VOCS[this.data.voc];
    if (!voc) return;

    while (this.data.xp >= xpNeeded(this.data.lv)) {
      this.data.xp -= xpNeeded(this.data.lv);
      this.data.lv++;

      // Gain stats
      this.data.mhp += voc.hpL;
      this.data.mmp += voc.mpL;
      this.data.batk += voc.aL;
      this.data.bdef += voc.dL;

      // Heal to full
      this.data.hp = this.data.mhp;
      this.data.mp = this.data.mmp;

      // Learn new spells
      for (const spell of SPELLS) {
        if (spell.lvl === this.data.lv && spell.voc.includes(this.data.voc)) {
          if (!this.data.spells.includes(spell.id)) {
            this.data.spells.push(spell.id);
          }
        }
      }
    }
  }

  checkSkillLevelUp(skill) {
    const skillLv = this.data.skills[skill] || 1;
    const skillXp = this.data.skillXp[skill] || 0;
    const needed = skillXpNeeded(skillLv, this.data.voc, skill);

    if (skillXp >= needed) {
      this.data.skills[skill] = skillLv + 1;
      this.data.skillXp[skill] = 0;
      return true;
    }
    return false;
  }

  recalculateStats() {
    // Recalculate base stats from vocation + equipment
    const voc = VOCS[this.data.voc];
    if (!voc) return;

    let defBonus = 0;
    let atkBonus = 0;

    // Add equipment bonuses
    for (const [slot, itemId] of Object.entries(this.data.eq)) {
      if (itemId && ITEMS[itemId]) {
        defBonus += ITEMS[itemId].def || 0;
        atkBonus += ITEMS[itemId].atk || 0;
      }
    }

    // Store recalculated stats
    this.data.bdef = voc.def + defBonus;
    this.data.batk = voc.atk + atkBonus;
  }

  validatePlayerData(data) {
    // Validate and normalize player data from client
    return {
      charId: data.charId || 'unknown',
      name: (data.name || 'Player').slice(0, 20),
      voc: ['knight', 'paladin', 'mage'].includes(data.voc) ? data.voc : 'knight',
      lv: Math.min(1000, Math.max(1, data.lv || 1)),
      xp: Math.max(0, data.xp || 0),
      hp: Math.max(0, data.hp || 100),
      mhp: Math.max(1, data.mhp || 100),
      mp: Math.max(0, data.mp || 50),
      mmp: Math.max(1, data.mmp || 50),
      batk: Math.max(1, data.batk || 10),
      bdef: Math.max(0, data.bdef || 5),
      gold: Math.min(99999999, Math.max(0, data.gold || 0)),
      x: data.x || 0,
      y: data.y || 0,
      dir: data.dir || 2,
      floor: data.floor || 0,
      inv: Array.isArray(data.inv) ? data.inv.slice(0, 30) : [],
      eq: data.eq || {},
      skills: data.skills || { melee: 10, distance: 10, magic: 10, shielding: 10 },
      skillXp: data.skillXp || { melee: 0, distance: 0, magic: 0, shielding: 0 },
      quests: Array.isArray(data.quests) ? data.quests : [],
      kills: data.kills || {},
      spells: Array.isArray(data.spells) ? data.spells : [],
      premium: data.premium || { active: false, expiry: 0 },
      blessings: Array.isArray(data.blessings) ? data.blessings : [],
      softBootCharges: data.softBootCharges || 0,
      lastSave: Date.now()
    };
  }

  getSanitizedState() {
    // Return state without internal tracking data
    return {
      charId: this.data.charId,
      name: this.data.name,
      voc: this.data.voc,
      lv: this.data.lv,
      xp: this.data.xp,
      hp: this.data.hp,
      mhp: this.data.mhp,
      mp: this.data.mp,
      mmp: this.data.mmp,
      batk: this.data.batk,
      bdef: this.data.bdef,
      gold: this.data.gold,
      x: this.data.x,
      y: this.data.y,
      dir: this.data.dir,
      floor: this.data.floor,
      inv: this.data.inv,
      eq: this.data.eq,
      skills: this.data.skills,
      skillXp: this.data.skillXp,
      quests: this.data.quests,
      kills: this.data.kills,
      spells: this.data.spells,
      premium: this.data.premium,
      blessings: this.data.blessings,
      softBootCharges: this.data.softBootCharges,
      lastSave: this.data.lastSave
    };
  }

  async saveToStorage() {
    if (this.data) {
      this.data.lastSave = Date.now();
      await this.state.storage.put('player', this.data);
    }
  }

  jsonResponse(data, status = 200) {
    return new Response(JSON.stringify(data), {
      status,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      }
    });
  }
}

// ============================================================================
// GAME ROOM DURABLE OBJECT
// ============================================================================

export class GameRoom {
  constructor(state, env) {
    this.state = state;
    this.env = env;
    this.players = new Map(); // ws -> player data
    this.lastCleanup = Date.now();
  }

  async fetch(request) {
    const url = new URL(request.url);
    if (request.headers.get('Upgrade') !== 'websocket') {
      return new Response('Expected WebSocket', { status: 426 });
    }

    const pair = new WebSocketPair();
    const [client, server] = Object.values(pair);

    server.accept();

    const playerId = crypto.randomUUID().slice(0, 8);

    this.players.set(server, {
      id: playerId,
      name: 'Player',
      voc: 'knight',
      lv: 1,
      x: 0,
      y: 0,
      dir: 2,
      lastPing: Date.now()
    });

    // Send existing players to the new connection
    const existing = [];
    for (const [ws, p] of this.players) {
      if (ws !== server && ws.readyState === 1) {
        existing.push(p);
      }
    }
    server.send(JSON.stringify({ t: 'init', id: playerId, players: existing }));

    // Notify others about the new player
    this.broadcast(server, { t: 'j', p: this.players.get(server) });

    server.addEventListener('message', (event) => {
      try {
        const msg = JSON.parse(event.data);
        const player = this.players.get(server);
        if (!player) return;

        switch (msg.t) {
          case 'j': // join with player info
            player.name = (msg.name || 'Player').slice(0, 20);
            player.voc = msg.voc || 'knight';
            player.lv = msg.lv || 1;
            player.x = msg.x || 0;
            player.y = msg.y || 0;
            player.dir = msg.dir || 2;
            player.lastPing = Date.now();
            this.broadcast(server, { t: 'j', p: player });
            break;

          case 'm': // move
            player.x = msg.x;
            player.y = msg.y;
            player.dir = msg.dir !== undefined ? msg.dir : player.dir;
            player.lv = msg.lv || player.lv;
            player.lastPing = Date.now();
            this.broadcast(server, { t: 'm', id: player.id, x: msg.x, y: msg.y, d: player.dir });
            break;

          case 'p': // ping/heartbeat
            player.lastPing = Date.now();
            server.send(JSON.stringify({ t: 'p' }));
            break;

          case 'action': // game action from PlayerState
            // Route to PlayerState DO if needed
            // For now, just broadcast to other players
            this.broadcast(server, { t: 'md', id: player.id, action: msg.action });
            break;
        }
      } catch (e) {
        // Ignore malformed messages
      }
    });

    server.addEventListener('close', () => {
      const player = this.players.get(server);
      if (player) {
        this.broadcast(server, { t: 'l', id: player.id });
        this.players.delete(server);
      }
    });

    server.addEventListener('error', () => {
      const player = this.players.get(server);
      if (player) {
        this.broadcast(server, { t: 'l', id: player.id });
        this.players.delete(server);
      }
    });

    // Periodic cleanup of stale connections (every 30s)
    if (Date.now() - this.lastCleanup > 30000) {
      this.lastCleanup = Date.now();
      this.cleanup();
    }

    return new Response(null, { status: 101, webSocket: client });
  }

  broadcast(sender, msg) {
    const data = JSON.stringify(msg);
    for (const [ws, p] of this.players) {
      if (ws !== sender && ws.readyState === 1) {
        try { ws.send(data); } catch (e) { /* ignore */ }
      }
    }
  }

  cleanup() {
    const now = Date.now();
    for (const [ws, p] of this.players) {
      if (now - p.lastPing > 30000) {
        this.broadcast(ws, { t: 'l', id: p.id });
        this.players.delete(ws);
        try { ws.close(1000, 'Timeout'); } catch (e) { /* ignore */ }
      }
    }
  }
}

// ============================================================================
// MAIN WORKER
// ============================================================================

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // Handle WebSocket connections at /ws?floor=N&charId=X
    if (url.pathname === '/ws') {
      const floor = url.searchParams.get('floor') || '0';
      const roomId = env.GAME_ROOM.idFromName('floor-' + floor);
      const room = env.GAME_ROOM.get(roomId);
      return room.fetch(request);
    }

    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        }
      });
    }

    // Player endpoints
    if (url.pathname === '/player/load' && request.method === 'POST') {
      const charId = url.searchParams.get('charId');
      if (!charId) {
        return new Response(JSON.stringify({ error: 'charId required' }), { status: 400 });
      }
      const psId = env.PLAYER_STATE.idFromName('ps-' + charId);
      const ps = env.PLAYER_STATE.get(psId);
      return ps.fetch(request);
    }

    if (url.pathname === '/player/action' && request.method === 'POST') {
      const charId = url.searchParams.get('charId');
      if (!charId) {
        return new Response(JSON.stringify({ error: 'charId required' }), { status: 400 });
      }
      const psId = env.PLAYER_STATE.idFromName('ps-' + charId);
      const ps = env.PLAYER_STATE.get(psId);
      return ps.fetch(request);
    }

    if (url.pathname === '/player/state' && request.method === 'GET') {
      const charId = url.searchParams.get('charId');
      if (!charId) {
        return new Response(JSON.stringify({ error: 'charId required' }), { status: 400 });
      }
      const psId = env.PLAYER_STATE.idFromName('ps-' + charId);
      const ps = env.PLAYER_STATE.get(psId);
      return ps.fetch(request);
    }

    // Online player count endpoint
    if (url.pathname === '/api/online') {
      return new Response(JSON.stringify({ status: 'ok', online: 0 }), {
        headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
      });
    }

    // Everything else: serve static assets
    return env.ASSETS.fetch(request);
  }
};
