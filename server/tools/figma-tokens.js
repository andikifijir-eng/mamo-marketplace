// Ambil design token MAMO dari Figma via sesi Brave (CDP)
const WebSocket = require('ws');

(async () => {
  const tabs = await (await fetch('http://localhost:9222/json')).json();
  const tab = tabs.find((t) => t.url.includes('figma.com') && t.type === 'page');
  if (!tab) return console.log('NO_FIGMA_TAB');

  const ws = new WebSocket(tab.webSocketDebuggerUrl, { origin: 'http://localhost:9222' });
  let mid = 0;
  const pending = new Map();
  ws.on('message', (raw) => {
    const m = JSON.parse(raw);
    if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); }
  });
  const send = (method, params) => new Promise((res) => {
    const id = ++mid; pending.set(id, res);
    ws.send(JSON.stringify({ id, method, params: params || {} }));
  });

  await new Promise((r) => ws.on('open', r));
  await send('Runtime.enable');

  const href = (await send('Runtime.evaluate', { expression: 'window.location.href', returnByValue: true })).result.result.value;
  const key = href.split('/design/')[1].split('/')[0];
  console.log('FILE_KEY:', key);

  // Coba beberapa endpoint
  const endpoints = [
    `https://www.figma.com/api/files/${key}?version=1`,
    `https://www.figma.com/file/${key}`,
  ];
  for (const url of endpoints) {
    const expr = `(async () => { try { const r = await fetch(${JSON.stringify(url)}, {credentials:'include'}); const t = await r.text(); return JSON.stringify({status:r.status,len:t.length,head:t.slice(0,150)}); } catch(e){ return 'ERR '+e.message; } })()`;
    const out = (await send('Runtime.evaluate', { expression: expr, returnByValue: true, awaitPromise: true })).result.result.value;
    console.log(url.slice(0, 60), '=>', out);
  }

  // Ambil LOCAL_VARIABLES / styles dari window Figma internal
  const probe = await send('Runtime.evaluate', {
    expression: `(() => {
      const keys = Object.keys(window).filter(k => /figma|fig|plugin|design/i.test(k)).slice(0,25);
      const info = { href: window.location.href, w: window.innerWidth, h: window.innerHeight, keys };
      return JSON.stringify(info);
    })()`,
    returnByValue: true,
  });
  console.log('PROBE:', probe.result.result.value);

  ws.close();
  process.exit(0);
})();
