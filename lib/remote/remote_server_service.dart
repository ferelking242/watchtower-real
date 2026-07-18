import 'dart:async';
  import 'dart:convert';
  import 'dart:io' if (dart.library.js_interop) 'package:watchtower/utils/io_stub.dart';
  import 'dart:math';
  import 'package:flutter/foundation.dart';
  import 'package:hive/hive.dart';
  import 'package:shelf/shelf.dart';
  import 'package:shelf/shelf_io.dart' as shelf_io;
  import 'package:shelf_router/shelf_router.dart';
  import 'package:watchtower/remote/rate_limiter.dart';
  import 'package:watchtower/remote/remote_api_handler.dart';
  import 'package:watchtower/remote/tunnel_service.dart';
  import 'package:watchtower/utils/log/logger.dart';

  void _slog(String msg) => AppLogger.log('[SERVER] $msg', tag: 'REMOTE');
  void _slogErr(String msg) => AppLogger.log('[SERVER] $msg', tag: 'REMOTE', logLevel: LogLevel.error);

  class RemoteServerService {
    RemoteServerService._();
    static final RemoteServerService instance = RemoteServerService._();

    Object? _server;
    TunnelService? _tunnel;
    bool _running = false;
    String? _localUrl;
    String? _tunnelUrl;
    String? _tunnelError;
    double? _downloadProgress;
    String? _apiKey;
    final _rateLimiter = RateLimiter();

    bool get isRunning => _running;
    String? get localUrl => _localUrl;
    String? get tunnelUrl => _tunnelUrl;
    String? get tunnelError => _tunnelError;
    double? get downloadProgress => _downloadProgress;
    String? get apiKey => _apiKey;

    // ── API key ──────────────────────────────────────────────────────────
    // Required (as `?key=` or `Authorization: Bearer <key>`) on every
    // `/api/*` route except `/api/ping` — this server can be reached by
    // any third-party app, local or via the public tunnel, so it must not
    // be wide open. Persisted so it survives toggling the server off/on.
    static const _kBox = 'remote_mode';
    static const _kApiKey = 'api_key';

    Future<String> _loadOrCreateApiKey() async {
      final box = await Hive.openBox(_kBox);
      final existing = box.get(_kApiKey) as String?;
      if (existing != null && existing.isNotEmpty) return existing;
      final key = _generateApiKey();
      await box.put(_kApiKey, key);
      return key;
    }

    String _generateApiKey() {
      final rnd = Random.secure();
      const chars =
          'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
      return List.generate(32, (_) => chars[rnd.nextInt(chars.length)]).join();
    }

    Future<void> regenerateApiKey() async {
      final box = await Hive.openBox(_kBox);
      final key = _generateApiKey();
      await box.put(_kApiKey, key);
      _apiKey = key;
      _notify();
    }

    final List<VoidCallback> _listeners = [];
    void addListener(VoidCallback cb) => _listeners.add(cb);
    void removeListener(VoidCallback cb) => _listeners.remove(cb);
    void _notify() { for (final cb in _listeners) cb(); }

    // Page HTML doc API — placeholders: {{LAN}}, {{TUNNEL_SECTION}}, {{API_KEY}}
    static const _htmlTemplate = '''<!DOCTYPE html>
  <html lang="fr">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Watchtower API</title>
    <style>
      *{box-sizing:border-box;margin:0;padding:0}
      :root{--bg:#0d0d1a;--card:#161627;--border:#ffffff12;--purple:#7c3aed;
            --pl:#a78bfa;--green:#4ade80;--gbg:#052e16;--gbr:#16a34a;
            --red:#f87171;--rbg:#2d0a0a;--rbr:#dc2626;
            --ybg:#1c1700;--ybr:#ca8a04;--text:#e0e0ff;--muted:#94a3b8;--code:#818cf8}
      body{font-family:system-ui,-apple-system,sans-serif;background:var(--bg);color:var(--text);min-height:100vh}
      a{color:var(--pl);text-decoration:none}a:hover{text-decoration:underline}
      .sb{position:fixed;top:0;left:0;width:210px;height:100vh;background:#0a0a15;
          border-right:1px solid var(--border);overflow-y:auto;padding:14px 0;z-index:100}
      .main{margin-left:210px;padding:30px 36px;max-width:860px}
      @media(max-width:720px){.sb{display:none}.main{margin-left:0;padding:18px 14px}}
      .brand{display:flex;align-items:center;gap:10px;padding:0 14px 14px;border-bottom:1px solid var(--border);margin-bottom:10px}
      .bicon{width:32px;height:32px;background:var(--purple);border-radius:8px;display:flex;align-items:center;justify-content:center;font-size:1rem;flex-shrink:0}
      .bname{font-size:.88rem;font-weight:700;color:var(--pl)}.bver{font-size:.6rem;color:var(--muted);margin-top:1px}
      .ng{padding:3px 0}.nl{font-size:.58rem;text-transform:uppercase;letter-spacing:.08em;color:var(--muted);padding:5px 14px 2px;font-weight:600}
      .ni{display:block;padding:5px 14px;font-size:.78rem;color:var(--muted);cursor:pointer}
      .ni:hover{color:var(--text);background:#ffffff06}
      .mb{font-size:.58rem;font-weight:700;padding:1px 5px;border-radius:3px;margin-right:5px;font-family:monospace}
      .get{background:#0ea5e922;color:#38bdf8}
      .ph{display:flex;align-items:flex-start;justify-content:space-between;flex-wrap:wrap;gap:10px;margin-bottom:24px}
      .pt{font-size:1.5rem;font-weight:700;color:var(--pl)}.ps{color:var(--muted);font-size:.85rem;margin-top:3px}
      .sb2{display:inline-flex;align-items:center;gap:5px;background:var(--gbg);color:var(--green);border:1px solid var(--gbr);border-radius:99px;padding:3px 10px;font-size:.78rem;font-weight:600}
      .dot{width:6px;height:6px;background:var(--green);border-radius:50%;animation:pulse 2s infinite}
      @keyframes pulse{0%,100%{opacity:1}50%{opacity:.4}}
      .card{background:var(--card);border:1px solid var(--border);border-radius:10px;padding:16px 18px;margin-bottom:12px}
      .card.green{background:var(--gbg);border-color:var(--gbr)}.card.red{background:var(--rbg);border-color:var(--rbr)}
      .card.yellow{background:var(--ybg);border-color:var(--ybr)}
      .cl{font-size:.62rem;text-transform:uppercase;letter-spacing:.07em;color:var(--muted);margin-bottom:7px;font-weight:600}
      .cr{display:flex;align-items:center;gap:8px;flex-wrap:wrap}
      .ut{font-family:monospace;font-size:.88rem;color:var(--code);word-break:break-all}
      .ht{font-size:.73rem;color:var(--muted);margin-top:4px}
      .et{font-size:.8rem;color:var(--red);margin-top:4px;word-break:break-word}
      .sp{width:15px;height:15px;border:2px solid var(--ybr)44;border-top-color:var(--ybr);border-radius:50%;animation:spin 1s linear infinite;margin-top:7px}
      @keyframes spin{to{transform:rotate(360deg)}}
      .kb{display:flex;align-items:center;gap:8px;flex-wrap:wrap}
      .kv{font-family:monospace;font-size:.85rem;background:#0a0a15;border:1px solid var(--border);border-radius:7px;padding:7px 11px;flex:1;min-width:0;word-break:break-all;color:var(--code)}
      .cbtn{background:var(--purple);color:#fff;border:none;border-radius:6px;padding:6px 12px;font-size:.75rem;cursor:pointer;white-space:nowrap;font-weight:600;transition:background .15s}
      .cbtn:hover{background:#6d28d9}.cbtn.ok{background:#16a34a}
      .abtn{display:inline-block;background:var(--purple);color:#fff;border-radius:6px;padding:6px 12px;font-size:.75rem;font-weight:600;text-decoration:none}
      .abtn:hover{background:#6d28d9;text-decoration:none}
      h2{font-size:1rem;font-weight:700;color:var(--text);margin:28px 0 12px;padding-bottom:5px;border-bottom:1px solid var(--border)}
      .ep{background:var(--card);border:1px solid var(--border);border-radius:9px;margin-bottom:9px;overflow:hidden}
      .eph{display:flex;align-items:center;gap:8px;padding:12px 14px;cursor:pointer;user-select:none;justify-content:space-between}
      .eph:hover{background:#ffffff04}
      .epl{display:flex;align-items:center;gap:8px;min-width:0}
      .epp{font-family:monospace;font-size:.83rem;color:var(--text);word-break:break-all}
      .epd{font-size:.75rem;color:var(--muted);padding-left:8px;white-space:nowrap}
      .chv{color:var(--muted);font-size:.65rem;transition:transform .2s;flex-shrink:0}
      .ep.open .chv{transform:rotate(90deg)}
      .epb{display:none;padding:0 14px 14px;border-top:1px solid var(--border)}
      .ep.open .epb{display:block}
      .pt2{width:100%;border-collapse:collapse;margin:10px 0;font-size:.78rem}
      .pt2 th{text-align:left;padding:5px 9px;background:#0a0a15;color:var(--muted);font-weight:600;font-size:.67rem;text-transform:uppercase;letter-spacing:.05em}
      .pt2 td{padding:6px 9px;border-top:1px solid var(--border)}
      .pt2 code,.ic{font-family:monospace;color:var(--code);background:#7c3aed15;padding:1px 5px;border-radius:3px}
      .req{color:var(--red);font-size:.62rem;font-weight:700}.opt{color:var(--muted);font-size:.62rem}
      .cb{background:#0a0a15;border:1px solid var(--border);border-radius:7px;padding:11px 13px;margin-top:9px;position:relative}
      .cbl{font-size:.58rem;text-transform:uppercase;color:var(--muted);letter-spacing:.06em;margin-bottom:5px}
      .cbc{font-family:monospace;font-size:.76rem;color:#a78bfa;white-space:pre-wrap;word-break:break-all;line-height:1.5}
      .tb{position:absolute;top:9px;right:9px;background:#7c3aed22;color:var(--pl);border:1px solid #7c3aed44;border-radius:5px;padding:3px 9px;font-size:.7rem;cursor:pointer;font-weight:600}
      .tb:hover{background:#7c3aed44}
      .rl{font-size:.67rem;text-transform:uppercase;color:var(--muted);letter-spacing:.06em;margin:9px 0 4px}
      .rb{background:#0a0a15;border:1px solid var(--border);border-radius:7px;padding:11px 13px;font-family:monospace;font-size:.76rem;color:#86efac;white-space:pre-wrap;overflow-x:auto}
      .am{display:grid;grid-template-columns:1fr 1fr;gap:9px;margin-top:9px}
      @media(max-width:480px){.am{grid-template-columns:1fr}}
      .am-card{background:#0a0a15;border:1px solid var(--border);border-radius:7px;padding:11px}
      .am-card h4{font-size:.75rem;font-weight:700;color:var(--pl);margin-bottom:5px}
      .am-card code{font-family:monospace;font-size:.72rem;color:var(--code);display:block;background:#7c3aed0d;padding:5px 8px;border-radius:4px;margin-top:4px;word-break:break-all}
      .rg{display:grid;grid-template-columns:repeat(3,1fr);gap:9px;margin-top:9px}
      @media(max-width:480px){.rg{grid-template-columns:1fr}}
      .rs{background:#0a0a15;border:1px solid var(--border);border-radius:7px;padding:11px;text-align:center}
      .rv{font-size:1.3rem;font-weight:800;color:var(--pl)}.rk{font-size:.67rem;color:var(--muted);margin-top:2px}
      .toast{position:fixed;bottom:18px;right:18px;background:#16a34a;color:#fff;padding:9px 16px;border-radius:8px;font-size:.8rem;font-weight:600;display:none;z-index:9999;box-shadow:0 4px 18px #00000066}
      .toast.show{display:block}
    </style>
  </head>
  <body>
  <div class="toast" id="toast">Copie !</div>

  <nav class="sb">
    <div class="brand">
      <div class="bicon">&#128316;</div>
      <div><div class="bname">Watchtower</div><div class="bver">API v1 &bull; Port 4567</div></div>
    </div>
    <div class="ng">
      <div class="nl">Connexion</div>
      <a class="ni" onclick="goto('s-conn')">Statut &amp; URLs</a>
      <a class="ni" onclick="goto('s-auth')">Auth &amp; Cle API</a>
      <a class="ni" onclick="goto('s-rate')">Rate Limiting</a>
    </div>
    <div class="ng">
      <div class="nl">Endpoints</div>
      <a class="ni" onclick="goto('s-util')"><span class="mb get">GET</span>/api/ping</a>
      <a class="ni" onclick="goto('s-src')"><span class="mb get">GET</span>/api/sources</a>
      <a class="ni" onclick="goto('s-content')"><span class="mb get">GET</span>Popular / Latest</a>
      <a class="ni" onclick="goto('s-search')"><span class="mb get">GET</span>Recherche</a>
      <a class="ni" onclick="goto('s-manga')"><span class="mb get">GET</span>Manga / Chapitres</a>
      <a class="ni" onclick="goto('s-media')"><span class="mb get">GET</span>Videos / Pages</a>
      <a class="ni" onclick="goto('s-lib')"><span class="mb get">GET</span>Librairie</a>
    </div>
  </nav>

  <div class="main">
    <div class="ph">
      <div>
        <div class="pt">Watchtower &mdash; API Reference</div>
        <div class="ps">Serveur dans l&apos;APK &bull; Port <strong>4567</strong> &bull; Activer via <em>Parametres &rarr; Mode Distant</em></div>
      </div>
      <div class="sb2"><span class="dot"></span> Serveur actif</div>
    </div>

    <h2 id="s-conn">Connexion</h2>

    <div class="card">
      <div class="cl">API Key (requise sur toutes les routes sauf /api/ping)</div>
      <div class="kb">
        <div class="kv" id="kv">{{API_KEY}}</div>
        <button class="cbtn" onclick="cpKey()">Copier</button>
      </div>
      <div class="ht">60 requetes/min &bull; Passe dans le header ou en ?key= &bull; Regener depuis l&apos;app</div>
    </div>

    <div class="card">
      <div class="cl">URL locale (meme reseau Wi-Fi)</div>
      <div class="cr">
        <span class="ut">{{LAN}}</span>
        <button class="cbtn" onclick="cp('{{LAN}}')">Copier</button>
        <a class="abtn" href="{{LAN}}/api/ping" target="_blank">Ping</a>
      </div>
      <div class="ht">Accessible uniquement depuis le meme Wi-Fi &bull; Si dispo, utiliser le lien public ci-dessous</div>
    </div>

    {{TUNNEL_SECTION}}

    <h2 id="s-auth">Authentification</h2>
    <div class="card">
      <div class="cl">Deux methodes acceptees (equivalentes)</div>
      <div class="am">
        <div class="am-card">
          <h4>&#128273; Header Bearer (recommande)</h4>
          <div class="ht">Ne passe pas dans les logs du navigateur</div>
          <code>Authorization: Bearer {{API_KEY}}</code>
        </div>
        <div class="am-card">
          <h4>&#128279; Query param ?key=</h4>
          <div class="ht">Pratique pour tester depuis le navigateur</div>
          <code>GET /api/sources?key={{API_KEY}}</code>
        </div>
      </div>
      <div class="ht" style="margin-top:10px">Reponse 401 si cle absente ou incorrecte &bull; Reponse 429 si rate limit depasse</div>
    </div>

    <h2 id="s-rate">Rate Limiting</h2>
    <div class="card">
      <div class="rg">
        <div class="rs"><div class="rv">60</div><div class="rk">req / minute</div></div>
        <div class="rs"><div class="rv">429</div><div class="rk">code HTTP si depasse</div></div>
        <div class="rs"><div class="rv">60s</div><div class="rk">fenetre glissante</div></div>
      </div>
      <div class="ht" style="margin-top:10px">Compte par cle API. Corps 429 : <span class="ic">{"error":"Rate limit exceeded"}</span></div>
    </div>

    <h2 id="s-util">Utilitaires</h2>

    <div class="ep open">
      <div class="eph" onclick="tog(this)">
        <div class="epl"><span class="mb get">GET</span><span class="epp">/api/ping</span></div>
        <span class="epd">Health check &mdash; pas d&apos;auth</span>
        <span class="chv">&#9654;</span>
      </div>
      <div class="epb">
        <div class="cb">
          <div class="cbl">Exemple</div>
          <div class="cbc">curl {{LAN}}/api/ping</div>
          <button class="tb" onclick="open2('{{LAN}}/api/ping')">Tester</button>
        </div>
        <div class="rl">Reponse 200</div>
        <div class="rb">{"ok": true, "app": "Watchtower"}</div>
      </div>
    </div>

    <div class="ep">
      <div class="eph" onclick="tog(this)">
        <div class="epl"><span class="mb get">GET</span><span class="epp">/api/proxy</span></div>
        <span class="epd">Proxy image (contourne les referrer)</span>
        <span class="chv">&#9654;</span>
      </div>
      <div class="epb">
        <table class="pt2">
          <tr><th>Param</th><th>Type</th><th>Description</th></tr>
          <tr><td><code>url</code> <span class="req">requis</span></td><td>string</td><td>URL de l&apos;image (URL-encode)</td></tr>
        </table>
        <div class="cb">
          <div class="cbl">Exemple</div>
          <div class="cbc">curl -H "Authorization: Bearer {{API_KEY}}" \
  "{{LAN}}/api/proxy?url=https%3A%2F%2Fcdn.example.com%2Fcover.jpg" --output cover.jpg</div>
        </div>
      </div>
    </div>

    <h2 id="s-src">Sources</h2>

    <div class="ep open">
      <div class="eph" onclick="tog(this)">
        <div class="epl"><span class="mb get">GET</span><span class="epp">/api/sources</span></div>
        <span class="epd">Toutes les sources (NSFW masque)</span>
        <span class="chv">&#9654;</span>
      </div>
      <div class="epb">
        <div class="cb">
          <div class="cbl">Exemple</div>
          <div class="cbc">curl -H "Authorization: Bearer {{API_KEY}}" {{LAN}}/api/sources</div>
          <button class="tb" onclick="open2('{{LAN}}/api/sources?key={{API_KEY}}')">Tester</button>
        </div>
        <div class="rl">Reponse 200</div>
        <div class="rb">{"sources":[{"id":"crunchyroll","name":"Crunchyroll","lang":"fr","types":["anime"],"isNsfw":false}]}</div>
      </div>
    </div>

    <div class="ep">
      <div class="eph" onclick="tog(this)">
        <div class="epl"><span class="mb get">GET</span><span class="epp">/api/source/:id/filters</span></div>
        <span class="epd">Filtres dispo d&apos;une source</span>
        <span class="chv">&#9654;</span>
      </div>
      <div class="epb">
        <table class="pt2">
          <tr><th>Param</th><th>Type</th><th>Description</th></tr>
          <tr><td><code>:id</code> <span class="req">requis</span></td><td>string</td><td>ID de la source (cf /api/sources)</td></tr>
        </table>
        <div class="cb">
          <div class="cbl">Exemple</div>
          <div class="cbc">curl -H "Authorization: Bearer {{API_KEY}}" {{LAN}}/api/source/crunchyroll/filters</div>
        </div>
        <div class="rl">Reponse 200</div>
        <div class="rb">{"filters":[{"name":"Genre","type":"select","values":["Action","Romance"]}]}</div>
      </div>
    </div>

    <h2 id="s-content">Contenu</h2>

    <div class="ep">
      <div class="eph" onclick="tog(this)">
        <div class="epl"><span class="mb get">GET</span><span class="epp">/api/source/:id/popular</span></div>
        <span class="epd">Contenus populaires</span>
        <span class="chv">&#9654;</span>
      </div>
      <div class="epb">
        <table class="pt2">
          <tr><th>Param</th><th>Type</th><th>Description</th></tr>
          <tr><td><code>:id</code> <span class="req">requis</span></td><td>string</td><td>ID de la source</td></tr>
          <tr><td><code>page</code> <span class="opt">optionnel</span></td><td>int</td><td>Numero de page (defaut : 1)</td></tr>
        </table>
        <div class="cb">
          <div class="cbl">Exemple</div>
          <div class="cbc">curl -H "Authorization: Bearer {{API_KEY}}" \
  "{{LAN}}/api/source/crunchyroll/popular?page=1"</div>
        </div>
        <div class="rl">Reponse 200</div>
        <div class="rb">{"items":[...],"hasNextPage":true,"currentPage":1}</div>
      </div>
    </div>

    <div class="ep">
      <div class="eph" onclick="tog(this)">
        <div class="epl"><span class="mb get">GET</span><span class="epp">/api/source/:id/latest</span></div>
        <span class="epd">Derniers ajouts</span>
        <span class="chv">&#9654;</span>
      </div>
      <div class="epb">
        <table class="pt2">
          <tr><th>Param</th><th>Type</th><th>Description</th></tr>
          <tr><td><code>:id</code> <span class="req">requis</span></td><td>string</td><td>ID de la source</td></tr>
          <tr><td><code>page</code> <span class="opt">optionnel</span></td><td>int</td><td>Page (defaut : 1)</td></tr>
        </table>
        <div class="cb">
          <div class="cbl">Exemple</div>
          <div class="cbc">curl -H "Authorization: Bearer {{API_KEY}}" \
  "{{LAN}}/api/source/crunchyroll/latest?page=1"</div>
        </div>
        <div class="rl">Reponse 200</div>
        <div class="rb">{"items":[...],"hasNextPage":true,"currentPage":1}</div>
      </div>
    </div>

    <h2 id="s-search">Recherche</h2>

    <div class="ep">
      <div class="eph" onclick="tog(this)">
        <div class="epl"><span class="mb get">GET</span><span class="epp">/api/source/:id/search</span></div>
        <span class="epd">Recherche dans une source</span>
        <span class="chv">&#9654;</span>
      </div>
      <div class="epb">
        <table class="pt2">
          <tr><th>Param</th><th>Type</th><th>Description</th></tr>
          <tr><td><code>:id</code> <span class="req">requis</span></td><td>string</td><td>ID de la source</td></tr>
          <tr><td><code>query</code> <span class="req">requis</span></td><td>string</td><td>Terme de recherche (URL-encode)</td></tr>
          <tr><td><code>page</code> <span class="opt">optionnel</span></td><td>int</td><td>Page (defaut : 1)</td></tr>
        </table>
        <div class="cb">
          <div class="cbl">Exemple</div>
          <div class="cbc">curl -H "Authorization: Bearer {{API_KEY}}" \
  "{{LAN}}/api/source/crunchyroll/search?query=one+piece&page=1"</div>
        </div>
        <div class="rl">Reponse 200</div>
        <div class="rb">{"items":[...],"hasNextPage":false,"currentPage":1}</div>
      </div>
    </div>

    <h2 id="s-manga">Manga &amp; Chapitres</h2>

    <div class="ep">
      <div class="eph" onclick="tog(this)">
        <div class="epl"><span class="mb get">GET</span><span class="epp">/api/manga/:sourceId/:mangaId</span></div>
        <span class="epd">Detail d&apos;un titre</span>
        <span class="chv">&#9654;</span>
      </div>
      <div class="epb">
        <div class="cb">
          <div class="cbl">Exemple</div>
          <div class="cbc">curl -H "Authorization: Bearer {{API_KEY}}" \
  "{{LAN}}/api/manga/crunchyroll/one-piece"</div>
        </div>
        <div class="rl">Reponse 200</div>
        <div class="rb">{"id":"one-piece","title":"One Piece","description":"...","cover":"...","genres":[...],"status":"ongoing"}</div>
      </div>
    </div>

    <div class="ep">
      <div class="eph" onclick="tog(this)">
        <div class="epl"><span class="mb get">GET</span><span class="epp">/api/manga/:sourceId/:mangaId/chapters</span></div>
        <span class="epd">Liste des chapitres / episodes</span>
        <span class="chv">&#9654;</span>
      </div>
      <div class="epb">
        <div class="cb">
          <div class="cbl">Exemple</div>
          <div class="cbc">curl -H "Authorization: Bearer {{API_KEY}}" \
  "{{LAN}}/api/manga/crunchyroll/one-piece/chapters"</div>
        </div>
        <div class="rl">Reponse 200</div>
        <div class="rb">{"chapters":[{"id":"ep-1000","title":"Episode 1000","number":1000,"date":"2024-01-15"}]}</div>
      </div>
    </div>

    <h2 id="s-media">Videos &amp; Pages manga</h2>

    <div class="ep">
      <div class="eph" onclick="tog(this)">
        <div class="epl"><span class="mb get">GET</span><span class="epp">/api/source/:id/videos</span></div>
        <span class="epd">Liens video d&apos;un episode</span>
        <span class="chv">&#9654;</span>
      </div>
      <div class="epb">
        <table class="pt2">
          <tr><th>Param</th><th>Type</th><th>Description</th></tr>
          <tr><td><code>:id</code> <span class="req">requis</span></td><td>string</td><td>ID de la source</td></tr>
          <tr><td><code>url</code> <span class="req">requis</span></td><td>string</td><td>URL de l&apos;episode (URL-encode)</td></tr>
        </table>
        <div class="cb">
          <div class="cbl">Exemple</div>
          <div class="cbc">curl -H "Authorization: Bearer {{API_KEY}}" \
  "{{LAN}}/api/source/crunchyroll/videos?url=https%3A%2F%2Fcrunchyroll.com%2Fwatch%2FEP1000"</div>
        </div>
        <div class="rl">Reponse 200</div>
        <div class="rb">{"videos":[{"url":"https://...","quality":"1080p","server":"Crunchyroll"}]}</div>
      </div>
    </div>

    <div class="ep">
      <div class="eph" onclick="tog(this)">
        <div class="epl"><span class="mb get">GET</span><span class="epp">/api/chapter/:chapterId/pages</span></div>
        <span class="epd">Pages d&apos;un chapitre manga</span>
        <span class="chv">&#9654;</span>
      </div>
      <div class="epb">
        <table class="pt2">
          <tr><th>Param</th><th>Type</th><th>Description</th></tr>
          <tr><td><code>:chapterId</code> <span class="req">requis</span></td><td>string</td><td>ID du chapitre</td></tr>
        </table>
        <div class="cb">
          <div class="cbl">Exemple</div>
          <div class="cbc">curl -H "Authorization: Bearer {{API_KEY}}" \
  "{{LAN}}/api/chapter/chapter-1000/pages"</div>
        </div>
        <div class="rl">Reponse 200</div>
        <div class="rb">{"pages":["https://cdn.../p1.jpg","https://cdn.../p2.jpg"]}</div>
      </div>
    </div>

    <h2 id="s-lib">Librairie &amp; Historique</h2>

    <div class="ep">
      <div class="eph" onclick="tog(this)">
        <div class="epl"><span class="mb get">GET</span><span class="epp">/api/library</span></div>
        <span class="epd">Contenu sauvegarde sur l&apos;appareil</span>
        <span class="chv">&#9654;</span>
      </div>
      <div class="epb">
        <div class="cb">
          <div class="cbl">Exemple</div>
          <div class="cbc">curl -H "Authorization: Bearer {{API_KEY}}" {{LAN}}/api/library</div>
          <button class="tb" onclick="open2('{{LAN}}/api/library?key={{API_KEY}}')">Tester</button>
        </div>
      </div>
    </div>

    <div class="ep">
      <div class="eph" onclick="tog(this)">
        <div class="epl"><span class="mb get">GET</span><span class="epp">/api/history</span></div>
        <span class="epd">Historique de lecture</span>
        <span class="chv">&#9654;</span>
      </div>
      <div class="epb">
        <div class="cb">
          <div class="cbl">Exemple</div>
          <div class="cbc">curl -H "Authorization: Bearer {{API_KEY}}" {{LAN}}/api/history</div>
          <button class="tb" onclick="open2('{{LAN}}/api/history?key={{API_KEY}}')">Tester</button>
        </div>
      </div>
    </div>

    <div style="margin-top:36px;padding-top:18px;border-top:1px solid var(--border);font-size:.72rem;color:var(--muted);text-align:center">
      Watchtower API &bull; Port 4567 &bull; NSFW bloque &bull; 60 req/min par cle API
    </div>
  </div>

  <script>
    function tog(h){h.closest(".ep").classList.toggle("open")}
    function goto(id){var e=document.getElementById(id);if(e)e.scrollIntoView({behavior:"smooth",block:"start"})}
    function cp(t){navigator.clipboard.writeText(t).then(toast)}
    function cpKey(){cp(document.getElementById("kv").textContent.trim())}
    function open2(u){window.open(u,"_blank")}
    function toast(){var t=document.getElementById("toast");t.classList.add("show");setTimeout(function(){t.classList.remove("show")},1600)}
    if(!document.querySelector(".card.green"))setTimeout(function(){location.reload()},6000);
  </script>
  </body>
  </html>''';

    String _buildHomePage() {
      final lan = _localUrl ?? '?';

      final String tunnelSection;
      if (_tunnelUrl != null) {
        final url = _tunnelUrl!;
        tunnelSection =
            '<div class="card green">'
            '<div class="label">Lien public (relay Replit)</div>'
            '<a href="' + url + '" class="url-text">' + url + '</a>'
            '<div class="hint">Utilisez ce lien depuis n&apos;importe ou</div>'
            '</div>';
      } else if (_tunnelError != null) {
        tunnelSection =
            '<div class="card red">'
            '<div class="label">Tunnel indisponible</div>'
            '<div class="err">' + (_tunnelError ?? '') + '</div>'
            '</div>';
      } else {
        tunnelSection =
            '<div class="card yellow">'
            '<div class="label">Relay Replit</div>'
            '<div class="hint">Demarrage en cours...</div>'
            '<div class="spinner"></div>'
            '</div>';
      }

      return _htmlTemplate
          .replaceAll('{{LAN}}', lan)
          .replaceAll('{{TUNNEL_SECTION}}', tunnelSection)
          .replaceAll('{{API_KEY}}', _apiKey ?? '');
    }

    Future<void> start(RemoteApiHandler handler) async {
      if (kIsWeb) return;
      if (_running) return;

      _slog('Demarrage HTTP port 4567...');
      _apiKey = await _loadOrCreateApiKey();
      _rateLimiter.startCleanup();
      final router = Router();

      Response cors(Response r) => r.change(headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      });
      Response optionsH(Request r) => Response.ok('', headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      });

      // Every /api/* route (besides /api/ping) requires the API key shown
      // in the Mode Distant screen, passed as `?key=` or a Bearer token.
      Middleware requireApiKey() => (Handler inner) => (Request req) async {
            final path = req.url.path;
            if (!path.startsWith('api/') || path == 'api/ping') {
              return inner(req);
            }
            final auth = req.headers['authorization'];
            final headerKey = (auth != null && auth.startsWith('Bearer '))
                ? auth.substring(7)
                : null;
            final key = req.url.queryParameters['key'] ?? headerKey;
            if (key == null || key != _apiKey) {
              return cors(_unauthorized());
            }
            if (!_rateLimiter.allow(key)) {
              return cors(Response(429,
                body: jsonEncode({"error": "Rate limit exceeded — retry in 60s"}),
                headers: {"Content-Type": "application/json"}));
            }
            return inner(req);
          };

      router.get('/', (Request req) async =>
          cors(Response.ok(_buildHomePage(),
              headers: {'Content-Type': 'text/html; charset=utf-8'})));

      router.get('/api/ping', (_) async =>
          cors(Response.ok(jsonEncode({'ok': true, 'app': 'Watchtower'}),
              headers: {'Content-Type': 'application/json'})));
      router.get('/api/sources', (Request req) async => cors(await handler.getSources(req)));
      router.get('/api/source/<sourceId>/popular', (Request req, String sourceId) async =>
          cors(await handler.getPopular(req, sourceId)));
      router.get('/api/source/<sourceId>/latest', (Request req, String sourceId) async =>
          cors(await handler.getLatest(req, sourceId)));
      router.get('/api/source/<sourceId>/search', (Request req, String sourceId) async =>
          cors(await handler.search(req, sourceId)));
      router.get('/api/source/<sourceId>/filters', (Request req, String sourceId) async =>
          cors(await handler.getFilters(req, sourceId)));
      router.get('/api/source/<sourceId>/videos', (Request req, String sourceId) async =>
          cors(await handler.getVideos(req, sourceId)));
      router.get('/api/manga/<sourceId>/<mangaId>', (Request req, String sourceId, String mangaId) async =>
          cors(await handler.getMangaDetail(req, sourceId, mangaId)));
      router.get('/api/manga/<sourceId>/<mangaId>/chapters', (Request req, String sourceId, String mangaId) async =>
          cors(await handler.getMangaChapters(req, sourceId, mangaId)));
      router.get('/api/chapter/<chapterId>/pages', (Request req, String chapterId) async =>
          cors(await handler.getChapterPages(req, chapterId)));
      router.get('/api/library', (Request req) async => cors(await handler.getLibrary(req)));
      router.get('/api/history', (Request req) async => cors(await handler.getHistory(req)));
      router.get('/api/proxy', (Request req) async => cors(await handler.proxyImage(req)));
      router.add('OPTIONS', '/<path|.*>', optionsH);

      final pipeline = const Pipeline()
          .addMiddleware(requireApiKey())
          .addHandler(router.call);
      _server = await shelf_io.serve(pipeline, InternetAddress.anyIPv4, 4567);
      _localUrl = 'http://' + (await _getLanIp()) + ':4567';
      _running = true;
      _tunnelError = null;
      _downloadProgress = null;
      _slog('Serveur actif sur $_localUrl');
      _notify();

      _tunnel = TunnelService();
      _tunnel!.onUrlChanged = (url) {
        _slog('Tunnel URL : $url');
        _tunnelUrl = url;
        _downloadProgress = null;
        _notify();
      };
      _tunnel!.onError = (err) {
        _slogErr('Tunnel erreur : $err');
        _tunnelError = err;
        _downloadProgress = null;
        _notify();
      };
      _tunnel!.onDownloadProgress = (p) {
        _downloadProgress = p;
        _notify();
      };
      await _tunnel!.start();
    }

    Response _unauthorized() => Response(
          401,
          body: jsonEncode({'error': 'Missing or invalid API key'}),
          headers: {'Content-Type': 'application/json'},
        );

    Future<String> _getLanIp() async {
      try {
        final interfaces = await NetworkInterface.list(
          includeLoopback: false,
          type: InternetAddressType.IPv4,
        );
        for (final iface in interfaces) {
          for (final addr in iface.addresses) {
            if (!addr.isLoopback) return addr.address;
          }
        }
      } catch (_) {}
      return 'localhost';
    }

    Future<void> stop() async {
      _slog('Arret serveur');
      _rateLimiter.dispose();
      _tunnel?.stop();
      _tunnel = null;
      if (_server != null) {
        await (_server as dynamic).close(force: true);
      }
      _server = null;
      _running = false;
      _localUrl = null;
      _tunnelUrl = null;
      _tunnelError = null;
      _downloadProgress = null;
      _notify();
    }
  }
  