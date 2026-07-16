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

console.log(`[REGISTRY] REPO_URL  = ${REPO_URL}`);
console.log(`[REGISTRY] CACHE_DIR = ${CACHE_DIR}`);
console.log(`[REGISTRY] CACHE_TTL = ${CACHE_TTL}ms`);

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
    const ageMs = Date.now() - stat.mtimeMs;
    if (ageMs > CACHE_TTL) {
      console.log(`[CACHE] Disk stale (${Math.round(ageMs/1000)}s > ${CACHE_TTL/1000}s): ${key.slice(0, 80)}`);
      return null;
    }
    return fs.readFileSync(p, 'utf8');
  } catch (_) { return null; }
}

function diskSet(key, data) {
  ensureCacheDir();
  fs.writeFileSync(diskCachePath(key), data, 'utf8');
}

async function fetchText(url) {
  const mem = cacheGet(url);
  if (mem) {
    console.log(`[CACHE] Memory hit: ${url.slice(0, 80)}`);
    return mem;
  }
  const disk = diskGet(url);
  if (disk) {
    console.log(`[CACHE] Disk hit: ${url.slice(0, 80)}`);
    cacheSet(url, disk);
    return disk;
  }

  console.log(`[FETCH] GET ${url}`);
  const t0 = Date.now();
  const fetch = await getFetch();
  const res = await fetch(url, { timeout: 30000 });
  const ms = Date.now() - t0;
  if (!res.ok) {
    console.error(`[FETCH] FAILED ${res.status} ${url} (${ms}ms)`);
    throw new Error(`HTTP ${res.status} fetching ${url}`);
  }
  const text = await res.text();
  console.log(`[FETCH] OK ${res.status} ${url} — ${text.length} bytes (${ms}ms)`);
  cacheSet(url, text);
  diskSet(url, text);
  return text;
}

// ── Source catalogue ────────────────────────────────────────────────────────────

let _catalogue = null;
let _catalogueTs = 0;

async function getCatalogue() {
  if (_catalogue && Date.now() - _catalogueTs < CACHE_TTL) {
    console.log(`[REGISTRY] Catalogue in memory (${_catalogue.length ?? Object.keys(_catalogue).length} entries)`);
    return _catalogue;
  }
  const url = `${REPO_URL}/watch.json`;
  console.log(`[REGISTRY] Fetching catalogue from ${url}…`);
  const text = await fetchText(url);
  _catalogue = JSON.parse(text);
  _catalogueTs = Date.now();
  const count = Array.isArray(_catalogue) ? _catalogue.length
    : (_catalogue.sources || _catalogue.extensions || []).length;
  console.log(`[REGISTRY] Catalogue loaded — ${count} total entries`);
  return _catalogue;
}

/**
 * Returns an array of source objects (non-NSFW only).
 * Shape: { id, name, lang, iconUrl, baseUrl, sourceCodeUrl, isNsfw, itemType, ... }
 */
async function listSources({ includeNsfw = false } = {}) {
  const cat = await getCatalogue();
  const sources = Array.isArray(cat) ? cat : (cat.sources || cat.extensions || []);
  const filtered = sources.filter(s => includeNsfw || !s.isNsfw);
  console.log(`[REGISTRY] listSources → ${filtered.length} sources (includeNsfw=${includeNsfw})`);
  return filtered;
}

/**
 * Find a single source by id, slug, or name (case-insensitive).
 */
async function findSource(idOrName) {
  console.log(`[REGISTRY] findSource("${idOrName}")…`);
  const sources = await listSources({ includeNsfw: true }); // search all
  const found = sources.find(s =>
    String(s.id) === String(idOrName) ||
    (s.name || '').toLowerCase() === String(idOrName).toLowerCase() ||
    (s.slug || '').toLowerCase() === String(idOrName).toLowerCase()
  ) || null;
  if (found) {
    console.log(`[REGISTRY] findSource("${idOrName}") → id=${found.id} name="${found.name}" lang=${found.lang} type=${found.itemType}`);
  } else {
    console.warn(`[REGISTRY] findSource("${idOrName}") → NOT FOUND`);
    // Log first 5 sources to help debug
    sources.slice(0, 5).forEach(s => console.log(`  candidate: id=${s.id} name="${s.name}"`));
  }
  return found;
}

/**
 * Fetch and return the JS source code for a given source.
 */
async function getSourceJs(source) {
  if (!source.sourceCodeUrl) throw new Error(`Source ${source.name} has no sourceCodeUrl`);
  const url = source.sourceCodeUrl.startsWith('http')
    ? source.sourceCodeUrl
    : `${REPO_URL}/${source.sourceCodeUrl}`;
  console.log(`[REGISTRY] getSourceJs for "${source.name}" from ${url}`);
  return fetchText(url);
}

module.exports = { listSources, findSource, getSourceJs, getCatalogue };
