#!/usr/bin/env node
// ─────────────────────────────────────────────────────
//  Claude Code Status Monitor
//  HTTP Server on port 4242
//  POST /api/state  ← called by set-state.sh
//  GET  /api/status → { state, lastEvent, sessionId, updatedAt }
//  GET  /*          → static files (index.html, themes/)
// ─────────────────────────────────────────────────────

const http = require('http');
const fs   = require('fs');
const path = require('path');
const os   = require('os');

const PORT        = 4242;
const STATIC_ROOT = path.join(__dirname, '..');

// How long to stay in 'waiting' (yellow) before becoming 'idle' (green)
const IDLE_DELAY_MS = 3_000;

// ── In-memory state ───────────────────────────────────
let state = {
  state:     'idle',
  lastEvent: null,
  sessionId: null,
  updatedAt: Math.floor(Date.now() / 1000),
};
let idleTimer = null;

function scheduleIdle() {
  clearTimeout(idleTimer);
  idleTimer = setTimeout(() => {
    state.state     = 'idle';
    state.updatedAt = Math.floor(Date.now() / 1000);
    idleTimer = null;
  }, IDLE_DELAY_MS);
}

function cancelIdle() {
  clearTimeout(idleTimer);
  idleTimer = null;
}

// persistent=true  → stay yellow indefinitely (waiting for user to answer a question)
// persistent=false → start 3s countdown to green (Claude finished its turn normally)
function applyEvent(newState, lastEvent, sessionId, persistent = false) {
  if (newState === 'busy') {
    cancelIdle();                         // busy cancels any pending idle
    state.state     = 'busy';
    state.lastEvent = lastEvent;
    state.sessionId = sessionId;
    state.updatedAt = Math.floor(Date.now() / 1000);
  } else if (newState === 'waiting') {
    state.state     = 'waiting';
    state.lastEvent = lastEvent;
    state.sessionId = sessionId;
    state.updatedAt = Math.floor(Date.now() / 1000);
    if (persistent) {
      cancelIdle();                       // stay yellow — user must reply first
    } else {
      scheduleIdle();                     // normal Stop: 3s countdown to green
    }
  }
}

// ── MIME types ────────────────────────────────────────
const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js':   'application/javascript',
  '.css':  'text/css',
  '.json': 'application/json',
  '.svg':  'image/svg+xml',
  '.ico':  'image/x-icon',
};

// ── Static file handler ───────────────────────────────
function serveStatic(req, res) {
  let urlPath = req.url.split('?')[0];
  if (urlPath === '/') urlPath = '/index.html';

  const filePath = path.join(STATIC_ROOT, urlPath);
  if (!filePath.startsWith(STATIC_ROOT)) {
    res.writeHead(403); res.end('Forbidden'); return;
  }

  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      res.end('Not found'); return;
    }
    const mime = MIME[path.extname(filePath)] || 'application/octet-stream';
    res.writeHead(200, { 'Content-Type': mime, 'Cache-Control': 'no-cache' });
    res.end(data);
  });
}

// ── HTTP Server ───────────────────────────────────────
const server = http.createServer((req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  // POST /api/state  — called by set-state.sh
  if (req.method === 'POST' && req.url === '/api/state') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      try {
        const { state: s, lastEvent, sessionId, persistent } = JSON.parse(body);
        applyEvent(s, lastEvent || null, sessionId || null, persistent === true);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ ok: true }));
      } catch {
        res.writeHead(400); res.end('Bad request');
      }
    });
    return;
  }

  // GET /api/status — polled by frontend
  if (req.method === 'GET' && (req.url === '/api/status' || req.url.startsWith('/api/status?'))) {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(state));
    return;
  }

  serveStatic(req, res);
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`\n  Claude Status Monitor`);
  console.log(`  ─────────────────────────────────`);
  console.log(`  API   → http://localhost:${PORT}/api/status`);
  console.log(`  Push  → POST http://localhost:${PORT}/api/state`);
  console.log(`  App   → http://localhost:${PORT}`);
  console.log(`\n  Press Ctrl+C to stop\n`);
});

module.exports = { applyEvent };
