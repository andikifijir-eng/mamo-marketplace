const WebSocket = require('ws');

(async () => {
  try {
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
      const handler = (data) => {
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

    const pageInfo = await send('Runtime.evaluate', {
      expression: '({ title: document.title, url: window.location.href })',
      returnByValue: true
    });
    console.log('PAGE_INFO:', JSON.stringify(pageInfo.result.value));

    // Check Figma internal objects or DOM tree
    const domInfo = await send('Runtime.evaluate', {
      expression: `(() => {
        const canvases = document.querySelectorAll('canvas');
        const layers = Array.from(document.querySelectorAll('[data-testid], [class*="layer"], [class*="panel"], [class*="left_panel"]')).map(el => el.getAttribute('aria-label') || el.innerText || el.className).filter(Boolean).slice(0, 50);
        return {
          title: document.title,
          canvasCount: canvases.length,
          canvasWidth: canvases[0] ? canvases[0].width : null,
          canvasHeight: canvases[0] ? canvases[0].height : null,
          bodyTextSample: document.body.innerText ? document.body.innerText.slice(0, 300) : ''
        };
      })()`,
      returnByValue: true
    });
    console.log('DOM_INFO:', JSON.stringify(domInfo.result.value));

    const targets = [
      { name: 'home', id: '19-2' },
      { name: 'detail', id: '63-1066' },
      { name: 'search', id: '55-326' },
      { name: 'chat-seller', id: '63-1442' },
      { name: 'profile', id: '21-205' },
      { name: 'sell', id: '95-2' },
      { name: 'listing', id: '103-31' },
      { name: 'settings', id: '103-287' },
      { name: 'onboarding1', id: '3-1454' },
      { name: 'splash', id: '3-1450' }
    ];

    const fs = require('fs');
    await send('Page.enable');

    for (const t of targets) {
      console.log(`Loading ${t.name} (node-id: ${t.id})...`);
      await send('Page.navigate', {
        url: `https://www.figma.com/design/sCjI7KHjXKO7riLBc50FW2/MAMO?node-id=${t.id}`
      });

      // Wait for progress bar to finish and canvas to draw
      for (let i = 0; i < 20; i++) {
        await new Promise(r => setTimeout(r, 1000));
        const status = await send('Runtime.evaluate', {
          expression: `({
            progressBar: !!document.querySelector('[class*="progress"]'),
            canvas: !!document.querySelector('canvas')
          })`,
          returnByValue: true
        });
        if (!status.result.value.progressBar && status.result.value.canvas && i >= 4) {
          break;
        }
      }
      await new Promise(r => setTimeout(r, 2000));
      const shot = await send('Page.captureScreenshot', { format: 'png' });
      fs.writeFileSync(`d:/MAMO/preview/figma-screen-${t.name}.png`, Buffer.from(shot.data, 'base64'));
      console.log(`Saved figma-screen-${t.name}.png (${shot.data.length} bytes)`);
    }

    ws.close();
  } catch (err) {
    console.error('ERROR:', err);
  }
})();
