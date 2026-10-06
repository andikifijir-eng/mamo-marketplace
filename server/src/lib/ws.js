const { WebSocketServer } = require('ws');
const { verifyToken } = require('./jwt');
const prisma = require('./prisma');

// userId -> Set<ws>
const clients = new Map();

function addClient(userId, ws) {
  if (!clients.has(userId)) clients.set(userId, new Set());
  clients.get(userId).add(ws);
}

function removeClient(userId, ws) {
  const set = clients.get(userId);
  if (set) {
    set.delete(ws);
    if (set.size === 0) clients.delete(userId);
  }
}

function sendToUser(userId, payload) {
  const set = clients.get(userId);
  if (!set) return;
  const data = JSON.stringify(payload);
  for (const ws of set) {
    if (ws.readyState === ws.OPEN) ws.send(data);
  }
}

function setupWebSocket(server) {
  const wss = new WebSocketServer({ server, path: '/ws' });

  wss.on('connection', (ws, req) => {
    try {
      const url = new URL(req.url, 'http://localhost');
      const token = url.searchParams.get('token');
      const payload = verifyToken(token);
      ws.userId = payload.sub;
      addClient(ws.userId, ws);

      ws.on('message', async (raw) => {
        let msg;
        try { msg = JSON.parse(raw.toString()); } catch { return; }
        if (msg.type === 'ping') {
          ws.send(JSON.stringify({ type: 'pong' }));
        }
        if (msg.type === 'read') {
          await prisma.message.updateMany({
            where: { conversationId: msg.conversationId, isRead: false, NOT: { senderId: ws.userId } },
            data: { isRead: true },
          }).catch(() => {});
        }
      });

      ws.on('close', () => removeClient(ws.userId, ws));
    } catch {
      ws.close(4001, 'unauthorized');
    }
  });

  console.log('[mamo-server] websocket ready at /ws');
}

module.exports = { setupWebSocket, sendToUser };
