# Watchtower Real — UI TikTok

Feed vertical TikTok-style pour **[Watchtower](https://github.com/ferelking242/watchtower)**.

> **UI-only.** Serveur, extensions, DB, Rust, Go → dans [ferelking242/watchtower](https://github.com/ferelking242/watchtower).  
> Développé séparément pour itérer vite. À la fin, le code fusionne dans `watchtower/lib/ui/tiktok/`.

---

## Stack identique à watchtower

Même packages, mêmes versions → fusion sans conflit.

| Package | Version |
|---|---|
| `flutter_riverpod` | `^3.1.0` |
| `media_kit` (+ video + libs) | git — kodjodevf fork |
| `hive` + `hive_flutter` | `^2.2.3` |
| `flex_color_scheme` | `^8.3.1` |
| `go_router` | `^17.2.0` |

---

## Architecture UI dans watchtower (après fusion)

```
watchtower/lib/
├── modules/          ← features existants (anime, manga, music, player…)
├── ui/               ← shells UI — nouveau dossier
│   ├── netflix/      ← UI actuelle : grille de cartes, bibliothèque, navigation classique
│   │   └── shell.dart
│   └── tiktok/       ← ce repo : feed vertical plein-écran  ← ICI
│       ├── feed_screen.dart
│       ├── feed_page.dart        ← Player media_kit, pool preload
│       ├── providers/
│       │   └── feed_provider.dart
│       ├── models/
│       │   └── feed_item.dart
│       └── widgets/
│           ├── feed_header.dart
│           ├── feed_sidebar.dart
│           └── feed_overlay_bottom.dart
├── eval/             ← moteur d'extensions JS/Dart (partagé)
├── remote/           ← serveur embarqué shelf (partagé)
└── services/         ← réseau, DB, downloads (partagé)
```

**Logique de switch UI** — dans `watchtower/lib/router/` :
- Un `StateProvider<UiShell>` (netflix | tiktok) persisté dans Hive
- Le routeur choisit le shell selon la préférence
- Les deux shells lisent la même Isar DB, les mêmes providers, le même cache

**Au moment de la fusion :**
- `lib/features/feed/` → `lib/ui/tiktok/`
- Remplace `RemoteApiClient` par les providers Isar/eval existants
- Supprime `hive` standalone → utilise les boxes Hive de watchtower
- Supprime `shared_preferences` → utilise les prefs Hive de watchtower

---

## Preloading (implémenté)

`FeedScreen` maintient un pool de `Player` (media_kit) :
- Fenêtre : `[index-1, index, index+1]`
- Page active : `player.play()`
- Pages adjacentes : `player.open(url, play: false)` (buffering en avance)
- Pages hors fenêtre : `player.dispose()`

→ Zéro latence au scroll entre les vidéos.

---

## Build

```bash
git clone https://github.com/ferelking242/watchtower-real.git
cd watchtower-real/app/watchtower-real
flutter pub get
flutter run
```

CI build APK + IPA sur chaque push sur `main`.

---

## Structure actuelle du code

```
lib/
├── main.dart                  ← MediaKit.ensureInitialized() + Hive + Riverpod
├── app.dart                   ← MaterialApp.router
├── router/router.dart         ← GoRouter
├── core/theme/                ← tokens, thème dark
├── remote/                    ← RemoteApiClient HTTP → serveur watchtower
├── utils/log/                 ← logger fichier
└── features/
    └── feed/
        ├── feed_screen.dart   ← PageView vertical + pool Players
        ├── models/feed_item.dart
        ├── providers/feed_provider.dart
        └── widgets/
            ├── feed_page.dart         ← media_kit Video + thumbnail fallback
            ├── feed_header.dart
            ├── feed_sidebar.dart      ← like, comment, share, bookmark
            └── feed_overlay_bottom.dart
```
