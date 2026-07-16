'use strict';
// Loads the extension catalogue from the Watchtower extensions repo
// and caches individual extension JS files in memory + on disk.

const fs = require('fs');
const path = require('path');

let _fetch;
async function getFetch() {
  if (!_fetch) { const m = await import('node-fetch'); _fetch = m.default; }
  return _fetch;
}

const REPO_URL  = process.env.EXTENSIONS_REPO_URL ||
                  'https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main';
const CACHE_DIR = process.env.CACHE_DIR || path.join(__dirname, '../../data/cache');
const CACHE_TTL = parseInt(process.env.CACHE_TTL_MS || '300000', 10); // 5 min default

const _memCache = new Map(); // key → { data, ts }

function cacheGet(key) {
  const e = _memCache.get(key);
  if (!e) return null;
  if (Date.now() - e.ts > CACHE_TTL) { _memCache.delete(key); return null; }
  return e.data;
}

function cacheSet(key, data) {
  _memCache.set(key, { data, ts: Date.now() });
}

function ensureCacheDir() {
  if (!fs.existsSync(CACHE_DIR)) fs.mkdirSync(CACHE_DIR, { recursive: true });
}

function diskCachePath(key) {
  const safe = key.replace(/[^a-z0-9_.-]/gi, '_');
  return path.join(CACHE_DIR, safe);
}

function diskGet(key) {
  const p = diskCachePath(key);
  try {
    const stat = fs.statSync(p);
    if (Date.now() - stat.mtimeMs > CACHE_TTL) return null;
    return fs.readFileSync(p, 'utf8');
  } catch (_) { return null; }
}

function diskSet(key, data) {
  ensureCacheDir();
  fs.writeFileSync(diskCachePath(key), data, 'utf8');
}

async function fetchText(url) {
  const mem = cacheGet(url);
  if (mem) return mem;
  const disk = diskGet(url);
  if (disk) { cacheSet(url, disk); return disk; }
  const fetch = await getFetch();
  const res = await fetch(url);
  if (!res.ok) throw new Error(`HTTP ${res.status} fetching ${url}`);
  const text = await res.text();
  cacheSet(url, text);
  diskSet(url, text);
  return text;
}

// ── Source catalogue ──────────────────────────────────────────────────────────

let _catalogue = null;
let _catalogueTs = 0;

async function getCatalogue() {
  if (_catalogue && Date.now() - _catalogueTs < CACHE_TTL) return _catalogue;
  const url = `${REPO_URL}/watch.json`;
  const text = await fetchText(url);
  _catalogue = JSON.parse(text);
  _catalogueTs = Date.now();
  return _catalogue;
}

/**
 * Returns an array of source objects (non-NSFW only).
 * Shape: { id, name, lang, iconUrl, baseUrl, sourceCodeUrl, isNsfw, itemType, ... }
 */
async function listSources({ includeNsfw = false } = {}) {
  const cat = await getCatalogue();
  const sources = Array.isArray(cat) ? cat : (cat.sources || cat.extensions || []);
  return sources.filter(s => includeNsfw || !s.isNsfw);
}

/**
 * Find a single source by id or name.
 */
async function findSource(idOrName) {
  const sources = await listSources({ includeNsfw: true }); // search all
  return sources.find(s =>
    String(s.id) === String(idOrName) ||
    (s.name || '').toLowerCase() === String(idOrName).toLowerCase()
  ) || null;
}

/**
 * Fetch and return the JS source code for a given source.
 */
async function getSourceJs(source) {
  if (!source.sourceCodeUrl) throw new Error(`Source ${source.name} has no sourceCodeUrl`);
  const url = source.sourceCodeUrl.startsWith('http')
    ? source.sourceCodeUrl
    : `${REPO_URL}/${source.sourceCodeUrl}`;
  return fetchText(url);
}

module.exports = { listSources, findSource, getSourceJs, getCatalogue };
