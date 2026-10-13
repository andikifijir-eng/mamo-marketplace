const WebSocket = require('ws');

(async () => {
  try {
    // Get the debugging tab for the open Figma page
    const tabs = await (await fetch('http://localhost:9222/json')).json();
    const tab = tabs.find(t => t.url.includes('figma.com'));
    if (!tab) {
      console.log('NO_FIGMA_TAB');
      return;
    }
    const ws = new WebSocket(tab.webSocketDebuggerUrl, { headers: { Host: 'localhost:9222' } });
    let id = 0;
    const send = (method, params = {}) => new Promise((resolve, reject) => {
      const msgId = ++id;
      const timeout = setTimeout(() => reject(new Error('Timeout ' + method)), 15000);
      const handler = data => {
        const msg = JSON.parse(data.toString());
        if (msg.id === msgId) {
          clearTimeout(timeout);
          ws.off('message', handler);
          resolve(msg.result);
        }
      };
      ws.on('message', handler);
      ws.send(JSON.stringify({ id: msgId, method, params }));
    });

    await new Promise(r => ws.on('open', r));
    console.log('Connected to Figma WebSocket!');

    // Open the main file (no node‑id) so the sidebar with all frames loads
    const baseUrl = 'https://www.figma.com/file/sCjI7KHjXKO7riLBc50FW2/MAMO';
    await send('Page.enable');
    await send('Page.navigate', { url: baseUrl });

    // Wait up to 60 seconds for the left panel (frame list) to appear
    for (let i = 0; i < 60; i++) {
      await new Promise(r => setTimeout(r, 1000));
      const panelResp = await send('Runtime.evaluate', {
        expression: `({panel: !!document.querySelector('[data-testid=\"left_panel\"]')})`,
        returnByValue: true
      });
      const panelObj = panelResp.result?.value;
      if (panelObj && panelObj.panel) break;
    }

    // Expand the Pages section if a button exists (some Figma versions hide it)
    await send('Runtime.evaluate', {
      expression: `(function(){
        const pagesBtn = document.querySelector('[data-testid=\"pages_button\"]');
        if(pagesBtn) pagesBtn.click();
      })();`,
      returnByValue: true
    });

    // Minor pause for lazy‑loaded items
    await new Promise(r => setTimeout(r, 3000));

    // Extract all <a> elements that contain a node-id in their href
    const nodesResp = await send('Runtime.evaluate', {
      expression: `Array.from(document.querySelectorAll('a')).filter(a=>a.href && a.href.includes('node-id')).map(a=>({
        name: a.textContent.trim(),
        id: a.href.split('node-id=')[1].split('&')[0]
      }))`,
      returnByValue: true
    });
    const nodes = nodesResp.result?.value || [];
    console.log('ALL_NODES:', JSON.stringify(nodes, null, 2));

    ws.close();
  } catch (err) {
    console.error('ERROR:', err);
  }
})();
