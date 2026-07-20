# Reel

**UI TikTok-style pour le SDK Watchtower** — feed vertical, recherche, live, profil, inbox.

[![APK](https://github.com/ferelking242/watchtower-real/actions/workflows/build-apk.yml/badge.svg)](https://github.com/ferelking242/watchtower-real/actions/workflows/build-apk.yml)
[![IPA](https://github.com/ferelking242/watchtower-real/actions/workflows/build-ipa.yml/badge.svg)](https://github.com/ferelking242/watchtower-real/actions/workflows/build-ipa.yml)

---

## 📦 Télécharger

| Plateforme | Lien |
|---|---|
| **Android APK** (arm64) | [Actions → Build APK](https://github.com/ferelking242/watchtower-real/actions/workflows/build-apk.yml) |
| **iOS IPA** (TrollStore) | [Actions → Build IPA](https://github.com/ferelking242/watchtower-real/actions/workflows/build-ipa.yml) |

---

## 🏗️ Architecture

```
lib/
├── main.dart / app.dart / shell.dart / splash_screen.dart
├── core/
│   ├── theme/tokens.dart     ← Couleurs, espacements, constantes
│   └── widgets/              ← Avatar, badge live, thumbnail vidéo
├── features/
│   ├── feed/                 ← Feed TikTok (PageView + sidebar + header)
│   ├── search/               ← Recherche + filtres + résultats
│   ├── live/                 ← Multi-guest live
│   ├── inbox/                ← Notifications / messages
│   ├── profile/              ← Profil utilisateur
│   ├── friends/              ← Page amis
│   └── connect/              ← Configuration du serveur Watchtower
├── remote/
│   ├── remote_client.dart          ← Client HTTP SDK Watchtower
│   ├── remote_config_provider.dart ← Config serveur (Riverpod)
│   └── app_version.dart            ← Vérif de version
├── router/router.dart        ← Navigation (go_router)
└── utils/log/                ← Logger fichier
```

## ⚙️ Prérequis

- Flutter `^3.10.0` (Dart `^3.10.0`)
- Serveur [Watchtower](https://github.com/ferelking242/watchtower) déployé
- iOS : TrollStore pour installer sans signing

## 🚀 Build local

```bash
flutter pub get
flutter build apk --release --target-platform android-arm64 --split-per-abi
# iOS :
flutter build ios --release --no-codesign
```
