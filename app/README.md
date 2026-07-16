# Watchtower Real

TikTok-style vertical content feed powered by the **Watchtower remote API**.

## Architecture

- Connects to a running Watchtower instance (mobile APK or Node.js server) via the remote API (port 4567)
- No embedded JS engine, no Rust, no Isar — pure Flutter + Riverpod + HTTP
- Fast iteration on UI without touching the main Watchtower app
- Once screens are validated, the build workflow assembles the final APK automatically from this repo

## Remote API

The app consumes the Watchtower remote server API:

| Endpoint | Description |
|---|---|
| `GET /api/ping` | Health check |
| `GET /api/sources` | List all sources |
| `GET /api/sources/:id/popular` | Popular content |
| `GET /api/sources/:id/latest` | Latest content |
| `GET /api/sources/:id/search?query=` | Search |
| `GET /api/sources/:id/detail?url=` | Item detail |
| `GET /api/sources/:id/videos?url=` | Video URLs |

Auth: `Authorization: Bearer <api_key>` or `?key=<api_key>`

## Build

GitHub Actions builds an ARM64 profile APK on every push to `main`.
