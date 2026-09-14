// Servidor estatico minimo, sin dependencias, para las demos de customERP.
// Sirve ./public y responde index.html para cualquier ruta (las demos son SPA de un archivo).
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || 3000;
const ROOT = path.join(__dirname, 'public');

const TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.webp': 'image/webp',
  '.ico': 'image/x-icon',
  '.woff2': 'font/woff2',
};

http.createServer((req, res) => {
  const url = decodeURIComponent((req.url || '/').split('?')[0]);

  if (url === '/healthz') {
    res.writeHead(200, { 'content-type': 'application/json; charset=utf-8' });
    return res.end(JSON.stringify({ ok: true, demo: 'reprogen', at: new Date().toISOString() }));
  }

  const rel = path.normalize(url).replace(/^([/\\])+/, '');
  let file = path.join(ROOT, rel);
  if (!file.startsWith(ROOT)) file = path.join(ROOT, 'index.html');
  if (!path.extname(file) || !fs.existsSync(file)) file = path.join(ROOT, 'index.html');

  fs.readFile(file, (err, buf) => {
    if (err) {
      res.writeHead(500, { 'content-type': 'text/plain; charset=utf-8' });
      return res.end('Error al leer el archivo');
    }
    res.writeHead(200, {
      'content-type': TYPES[path.extname(file)] || 'application/octet-stream',
      'cache-control': path.extname(file) === '.html' ? 'no-cache' : 'public, max-age=3600',
      'x-content-type-options': 'nosniff',
    });
    res.end(buf);
  });
}).listen(PORT, () => console.log('[demo] reprogen escuchando en ' + PORT));
