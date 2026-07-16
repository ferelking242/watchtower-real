'use strict';
const express = require('express');
const { rateLimiterMiddleware } = require('./rate-limiter');
const registry = require('./extension-registry');
const { createRuntime } = require('./js-runtime');

const app = express();
app.use(express.json());

// ── Auth middleware ───────────────────────────────────────────────────────────
const API_KEY = process.env.API_KEY || '';

function requireAuth(req, res, next) {
  if (!API_KEY) return next(); // no key configured → open
  const key = req.headers['x-api-key'] ||
              (req.headers['authorization'] || '').replace(/^Bearer\s+/i, '');
  if (key !== API_KEY) return res.status(401).json({ error: 'Missing or invalid API key' });
  next();
}

// ── NSFW guard ────────────────────────────────────────────────────────────────
function nsfwBlocked(source) {
  return source && source.isNsfw === true;
}

// ── Response helpers ──────────────────────────────────────────────────────────
const json  = (res, data, status = 200) => res.status(status).json(data);
const error = (res, msg, status = 500)  => json(res, { error: msg }, status);

// ── Extension service cache (one runtime per source) ─────────────────────────
const _runtimes = new Map();

async function getRuntimeForSource(source) {
  const key = String(source.id || source.name);
  if (_runtimes.has(key)) return _runtimes.get(key);

  const sourceJs = await registry.getSourceJs(source);
  const runtime  = createRuntime(source);

  // Evaluate the extension JS
  runtime.evaluate(sourceJs);
  // Instantiate the extension (convention: `const extention = new ClassName()`)
  // The extension JS should define `extention` itself; if not, try to infer.
  const hasExtention = await runtime.evaluateAsync('typeof extention');
  if (hasExtention.stringResult === '"undefined"') {
    // Fallback: look for a class that extends MProvider and instantiate it
    await runtime.evaluateAsync(`
      (function() {
        const names = Object.getOwnPropertyNames(globalThis)
          .filter(n => {
            try { return globalThis[n] && globalThis[n].prototype instanceof MProvider; }
            catch(_) { return false; }
          });
        if (names.length > 0) { globalThis.extention = new globalThis[names[0]](); }
      })();
    `);
  }

  _runtimes.set(key, runtime);
  return runtime;
}

async function callExtension(runtime, call) {
  const result = await runtime.handlePromise(
    await runtime.evaluateAsync(`jsonStringify(() => extention.${call})`)
  );
  if (result.isError) throw new Error(result.stringResult);
  if (!result.stringResult) throw new Error('Extension returned empty result');
  return JSON.parse(result.stringResult);
}

// ── Public routes ─────────────────────────────────────────────────────────────

// Ping — no auth required
app.get('/api/ping', (req, res) => json(res, { status: 'ok', version: '0.1.0' }));

// Everything else requires auth + rate limiting
app.use('/api', requireAuth, rateLimiterMiddleware);

// GET /api/sources — list all non-NSFW sources
app.get('/api/sources', async (req, res) => {
  try {
    const sources = await registry.listSources({ includeNsfw: false });
    json(res, { sources });
  } catch (e) { error(res, e.message); }
});

// GET /api/sources/:id — single source info
app.get('/api/sources/:id', async (req, res) => {
  try {
    const source = await registry.findSource(req.params.id);
    if (!source) return error(res, 'Source not found', 404);
    if (nsfwBlocked(source)) return error(res, 'Source not available via API', 403);
    json(res, source);
  } catch (e) { error(res, e.message); }
});

// GET /api/sources/:id/popular?page=1
app.get('/api/sources/:id/popular', async (req, res) => {
  try {
    const source = await registry.findSource(req.params.id);
    if (!source) return error(res, 'Source not found', 404);
    if (nsfwBlocked(source)) return error(res, 'Source not available via API', 403);
    const page = parseInt(req.query.page || '1', 10);
    const runtime = await getRuntimeForSource(source);
    const data = await callExtension(runtime, `getPopular(${page})`);
    json(res, { mangas: data?.list ?? data ?? [], hasNextPage: data?.hasNextPage ?? false });
  } catch (e) { error(res, e.message); }
});

// GET /api/sources/:id/latest?page=1
app.get('/api/sources/:id/latest', async (req, res) => {
  try {
    const source = await registry.findSource(req.params.id);
    if (!source) return error(res, 'Source not found', 404);
    if (nsfwBlocked(source)) return error(res, 'Source not available via API', 403);
    const page = parseInt(req.query.page || '1', 10);
    const runtime = await getRuntimeForSource(source);
    const data = await callExtension(runtime, `getLatestUpdates(${page})`);
    json(res, { mangas: data?.list ?? data ?? [], hasNextPage: data?.hasNextPage ?? false });
  } catch (e) { error(res, e.message); }
});

// GET /api/sources/:id/search?q=...&page=1
app.get('/api/sources/:id/search', async (req, res) => {
  try {
    const source = await registry.findSource(req.params.id);
    if (!source) return error(res, 'Source not found', 404);
    if (nsfwBlocked(source)) return error(res, 'Source not available via API', 403);
    const q    = (req.query.q || '').replace(/'/g, "\\'");
    const page = parseInt(req.query.page || '1', 10);
    const runtime = await getRuntimeForSource(source);
    const data = await callExtension(runtime, `search('${q}', ${page}, [])`);
    json(res, { mangas: data?.list ?? data ?? [], hasNextPage: data?.hasNextPage ?? false });
  } catch (e) { error(res, e.message); }
});

// GET /api/sources/:id/detail?url=...
app.get('/api/sources/:id/detail', async (req, res) => {
  try {
    const source = await registry.findSource(req.params.id);
    if (!source) return error(res, 'Source not found', 404);
    if (nsfwBlocked(source)) return error(res, 'Source not available via API', 403);
    const url = (req.query.url || '').replace(/'/g, "\\'");
    if (!url) return error(res, 'url query param required', 400);
    const runtime = await getRuntimeForSource(source);
    const data = await callExtension(runtime, `getDetail('${url}')`);
    json(res, data || {});
  } catch (e) { error(res, e.message); }
});

// GET /api/sources/:id/videos?url=...
app.get('/api/sources/:id/videos', async (req, res) => {
  try {
    const source = await registry.findSource(req.params.id);
    if (!source) return error(res, 'Source not found', 404);
    if (nsfwBlocked(source)) return error(res, 'Source not available via API', 403);
    const url = (req.query.url || '').replace(/'/g, "\\'");
    if (!url) return error(res, 'url query param required', 400);
    const runtime = await getRuntimeForSource(source);
    const data = await callExtension(runtime, `getVideoList('${url}')`);
    json(res, { videos: Array.isArray(data) ? data : [] });
  } catch (e) { error(res, e.message); }
});

// GET /api/sources/:id/filters
app.get('/api/sources/:id/filters', async (req, res) => {
  try {
    const source = await registry.findSource(req.params.id);
    if (!source) return error(res, 'Source not found', 404);
    if (nsfwBlocked(source)) return error(res, 'Source not available via API', 403);
    const runtime = await getRuntimeForSource(source);
    const data = await callExtension(runtime, 'getFilterList()');
    json(res, { filters: Array.isArray(data) ? data : [] });
  } catch (e) { error(res, e.message); }
});

// GET /api/sources/:id/pages?url=...
app.get('/api/sources/:id/pages', async (req, res) => {
  try {
    const source = await registry.findSource(req.params.id);
    if (!source) return error(res, 'Source not found', 404);
    if (nsfwBlocked(source)) return error(res, 'Source not available via API', 403);
    const url = (req.query.url || '').replace(/'/g, "\\'");
    if (!url) return error(res, 'url query param required', 400);
    const runtime = await getRuntimeForSource(source);
    const data = await callExtension(runtime, `getPageList('${url}')`);
    json(res, { pages: Array.isArray(data) ? data : [] });
  } catch (e) { error(res, e.message); }
});

// 404 catch-all
app.use((req, res) => error(res, 'Not found', 404));

// Error handler
app.use((err, req, res, next) => {
  console.error('[API] Unhandled error:', err);
  error(res, err.message || 'Internal server error');
});

module.exports = app;
