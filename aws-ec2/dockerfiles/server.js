const express = require('express');
const path = require('path');
const { createProxyMiddleware } = require('http-proxy-middleware');

const app = express();
const port = 8080;

const upstreamEnv = process.env.API_UPSTREAMS || '';
const upstreams = upstreamEnv
  .split(',')
  .map(s => s.trim())
  .filter(Boolean);

if (upstreams.length === 0) {
  console.error('[frontend] API_UPSTREAMS não definido. Ex.: API_UPSTREAMS=10.0.2.203:8080,10.0.3.46:8080');
  process.exit(1);
}

let rrIndex = 0;
const pickTarget = () => {
  const targetHost = upstreams[rrIndex % upstreams.length];
  rrIndex += 1;
  return `http://${targetHost}`;
};

// Static files (Vite build)
const distDir = path.join(__dirname, 'dist');
app.use(express.static(distDir));

// Proxy /api para os backends, mantendo o prefixo /api
app.use('/api', createProxyMiddleware({
  changeOrigin: true,
  // target é obrigatório; usa o primeiro apenas como placeholder, o router escolhe de fato
  target: `http://${upstreams[0]}`,
  router: () => pickTarget(),
  onProxyReq: (proxyReq) => {
    // garante conexão keep-alive/upgrade quando necessário
    proxyReq.setHeader('Connection', 'keep-alive');
  },
}));

// SPA fallback
app.get('*', (_req, res) => {
  res.sendFile(path.join(distDir, 'index.html'));
});

app.listen(port, () => {
  console.log(`[frontend] Servindo em http://0.0.0.0:${port} | UPSTREAMS: ${upstreams.join(', ')}`);
});


