// MegaRealms Multiplayer Worker — Durable Objects + WebSocket
// Each floor has its own GameRoom Durable Object instance

export class GameRoom {
  constructor(state, env) {
    this.state = state;
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

// Main Worker fetch handler
export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // Handle WebSocket connections at /ws?floor=N
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

    // Player count endpoint
    if (url.pathname === '/api/online') {
      return new Response(JSON.stringify({ status: 'ok' }), {
        headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
      });
    }

    // Everything else: let Cloudflare serve static assets (index.html, etc.)
    return env.ASSETS.fetch(request);
  }
};
