// Static server sederhana untuk Flutter web build (SPA fallback ke index.html)
const http = require('http');
const fs = require('fs');
const path = require('path');

const root = process.argv[2] || path.join(__dirname, '..', 'build', 'web');
const port = parseInt(process.argv[3] || '8080');

const MIME = {
  '.html': 'text/html', '.js': 'application/javascript', '.css': 'text/css',
  '.json': 'application/json', '.png': 'image/png', '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml', '.ttf': 'font/ttf', '.otf': 'font/otf',
  '.wasm': 'application/wasm', '.ico': 'image/x-icon', '.map': 'application/json',
};

http.createServer((req, res) => {
  let p = decodeURIComponent(req.url.split('?')[0]);
  if (p === '/') p = '/index.html';
  let file = path.join(root, p);

  if (!fs.existsSync(file) || fs.statSync(file).isDirectory()) {
    // SPA fallback
    file = path.join(root, 'index.html');
    if (!fs.existsSync(file)) {
      res.writeHead(404).end('Not found');
      return;
    }
  }

  const ext = path.extname(file).toLowerCase();
  res.writeHead(200, {
    'Content-Type': MIME[ext] || 'application/octet-stream',
    'Cache-Control': 'no-store',
  });
  fs.createReadStream(file).pipe(res);
}).listen(port, () => console.log(`[static] serving ${root} at http://localhost:${port}`));
