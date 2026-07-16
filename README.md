<p align="center">
  <img src="app/watchtower/assets/app_icons/icon-red.png" width="120" alt="Watchtower logo"/>
</p>

<h1 align="center">Watchtower</h1>

<p align="center">
  <b>Manga · Anime · Movies · Music — all in one open-source app</b><br/>
  TikTok-style feed · Headless server · Cross-platform builds
</p>

<p align="center">
  <!-- CI badges -->
  <a href="https://github.com/ferelking242/watchtower-real/actions/workflows/build-apk.yml">
    <img src="https://github.com/ferelking242/watchtower-real/actions/workflows/build-apk.yml/badge.svg" alt="Build APK"/>
  </a>
  <a href="https://github.com/ferelking242/watchtower-real/actions/workflows/build-ipa.yml">
    <img src="https://github.com/ferelking242/watchtower-real/actions/workflows/build-ipa.yml/badge.svg" alt="Build IPA"/>
  </a>
  <a href="https://github.com/ferelking242/watchtower-real/actions/workflows/build-server.yml">
    <img src="https://github.com/ferelking242/watchtower-real/actions/workflows/build-server.yml/badge.svg" alt="Build Server"/>
  </a>
</p>

---

## 📦 Download

| Platform | Link |
|---|---|
| **Android APK** (arm64) | [Latest release → Actions → apk-arm64-v8a](https://github.com/ferelking242/watchtower-real/actions/workflows/build-apk.yml) |
| **iOS IPA** (TrollStore) | [Latest release → Actions → ipa-trollstore](https://github.com/ferelking242/watchtower-real/actions/workflows/build-ipa.yml) |
| **Docker image** | `ghcr.io/ferelking242/watchtower-server:latest` |

---

## 🏗️ Architecture

```
watchtower-real/
├── app/
│   ├── watchtower-real/      ← Flutter app (TikTok feed UI)
│   │   └── lib/              ← Pure Flutter + Riverpod, no native deps
│   └── watchtower/           ← Full Flutter app (Mangayomi fork)
│       ├── lib/              ← Rust + Go + QuickJS embedded
│       └── server/           ← Node.js headless server ← deploy this
└── .github/workflows/
    ├── build-apk.yml
    ├── build-ipa.yml
    └── build-server.yml
```

The **Flutter app** (`watchtower-real`) connects to a running **Watchtower server** via REST API on port `8080`. The server runs JS extensions in a sandboxed Node.js VM and exposes:

| Endpoint | Description |
|---|---|
| `GET /api/ping` | Health check |
| `GET /api/sources` | List all sources |
| `GET /api/sources/:id/popular` | Popular content |
| `GET /api/sources/:id/latest` | Latest updates |
| `GET /api/sources/:id/search?q=` | Search |
| `GET /api/sources/:id/detail?url=` | Item detail |
| `GET /api/sources/:id/videos?url=` | Video stream URLs |
| `GET /api/sources/:id/pages?url=` | Manga page images |

Auth: `X-Api-Key: <key>` or `Authorization: Bearer <key>`

---

## 🚀 Deploy the Server

Pick your platform — all options run the **same server code** from `app/watchtower/server/`.

### ☁️ One-click cloud deploys

| Platform | Button |
|---|---|
| **Railway** | [![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/template/watchtower?referralCode=ferelking) |
| **Render** | [![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/ferelking242/watchtower-real) |
| **Hugging Face Spaces** | [![Open in HF Spaces](https://huggingface.co/datasets/huggingface/badges/resolve/main/open-in-hf-spaces-sm-dark.svg)](https://huggingface.co/spaces) |
| **Google Colab** | [![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/ferelking242/watchtower-real/blob/main/colab_deploy.ipynb) |

> **Railway** and **Render** give you a persistent HTTPS server in minutes — recommended for production use.  
> **Colab** and **HF Spaces** are free but sessions expire; use them for testing.

---

### 🐳 Docker (local or VPS)

```bash
# Clone the repo
git clone https://github.com/ferelking242/watchtower-real.git
cd watchtower-real/app/watchtower/server

# Configure
cp .env.example .env
# Edit .env → set API_KEY=yoursecretkey

# Start
docker compose up -d

# Check
curl http://localhost:8080/api/ping
# → {"status":"ok","version":"0.1.0"}
```

The server runs on port `8080` by default. Data persists in a named Docker volume.

---

### 🟢 Node.js directly

```bash
git clone https://github.com/ferelking242/watchtower-real.git
cd watchtower-real/app/watchtower/server

npm install
API_KEY=mysecretkey PORT=8080 node server.js
```

Requires Node.js 20+.

---

### 🛤️ Railway (manual)

1. Fork this repo
2. Create a new Railway project → **Deploy from GitHub repo**
3. Set root directory: `app/watchtower/server`
4. Add env vars: `API_KEY`, `PORT=8080`
5. Deploy → Railway gives you a public HTTPS URL

Or use the one-click button above (sets root directory automatically).

---

### 🎨 Render (manual)

1. Fork this repo
2. New → **Web Service** → connect your fork
3. Root directory: `app/watchtower/server`
4. Build command: `npm ci`
5. Start command: `node server.js`
6. Add env var `API_KEY`
7. Deploy

The `render.yaml` at the root of this repo pre-fills all settings if you use the button above.

---

### 🤗 Hugging Face Spaces

1. Create a new Space → **Docker** runtime
2. Copy contents of `app/watchtower/server/` into your Space
3. The included `Dockerfile` is already HF-compatible
4. Add `API_KEY` in Space Secrets
5. Space URL becomes your server endpoint

---

### ⚗️ Google Colab (free, session-based)

Open [`colab_deploy.ipynb`](colab_deploy.ipynb) in Colab.  
The notebook installs Node.js, starts the server, and exposes it via `ngrok` (free tunnel).  
Copy the generated URL into the app settings → works until the Colab session ends.

---

### 🏃 RunPod

1. Create a pod with the **Node.js 20** template (or any Linux pod)
2. In the terminal:
```bash
git clone https://github.com/ferelking242/watchtower-real.git
cd watchtower-real/app/watchtower/server
npm ci
API_KEY=yourkey PORT=8080 node server.js &
```
3. Expose port `8080` in the pod settings

---

## 📱 Connect the App to Your Server

Once your server is running, open the Watchtower app:

1. Go to **Settings → Remote Server**
2. Enter your server URL (e.g. `https://your-app.railway.app`)
3. Enter your `API_KEY`
4. Tap **Connect** → sources load automatically

---

## 🔧 Environment Variables

| Variable | Default | Description |
|---|---|---|
| `PORT` | `8080` | HTTP listening port |
| `API_KEY` | _(empty = open)_ | Auth key for all `/api/*` routes |
| `EXTENSIONS_REPO_URL` | mangayomi-extensions/main | Extensions catalogue base URL |
| `CACHE_TTL_MS` | `300000` | Extension cache TTL (5 min) |
| `CACHE_DIR` | `/data/cache` | On-disk cache directory |
| `PREFS_DIR` | `/data/prefs` | Per-source preferences directory |
| `RATE_WINDOW_MS` | `60000` | Rate limit window (1 min) |
| `RATE_MAX_TOKENS` | `60` | Max requests per window |

---

## 🛠️ Build the App Locally

### Prerequisites

- Flutter SDK 3.38+
- Java 17 (for Android)
- Xcode 15+ (for iOS, macOS only)

```bash
git clone https://github.com/ferelking242/watchtower-real.git
cd watchtower-real/app/watchtower-real

flutter pub get
flutter run          # on connected device or emulator
flutter build apk --release --target-platform android-arm64 --split-per-abi
```

---

## 📄 License

Apache 2.0 — see [LICENSE](app/watchtower/LICENSE).
