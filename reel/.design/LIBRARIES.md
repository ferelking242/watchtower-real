# Librairies recommandées

Versions vérifiées compatibles Flutter 3.38.x / Dart ^3.10.0

---

## Déjà dans pubspec.yaml

| Package | Version | Usage |
|---|---|---|
| `flutter_riverpod` | ^3.1.0 | State management global |
| `hooks_riverpod` | ^3.1.0 | Hooks + Riverpod |
| `flutter_hooks` | ^0.21.0 | useState, useEffect, etc. |
| `go_router` | ^17.2.0 | Navigation |
| `http` | ^1.6.0 | Appels API remote |
| `shared_preferences` | ^2.3.5 | Config locale (URL serveur, clé API) |
| `hive` + `hive_flutter` | ^2.2.3 | Cache local (historique, favoris) |
| `flex_color_scheme` | ^8.3.1 | Thème Material 3 |
| `cached_network_image` | ^3.4.1 | Thumbnails avec cache |
| `skeletonizer` | ^2.1.0 | Loading skeletons |
| `cupertino_icons` | ^1.0.9 | Icônes iOS de base |

---

## À ajouter dans pubspec.yaml

### Vidéo
```yaml
video_player: ^2.9.2
```
- Player natif Android/iOS/Web
- Utilisé pour chaque page du `PageView` vertical
- **Pourquoi pas `chewie` ?** — chewie ajoute des contrôles inutiles pour TikTok-style (on gère les contrôles custom manuellement)

### Icônes
```yaml
lucide_icons: ^0.484.0
```
- Set moderne (Figma-like) — correspond le mieux aux icônes TikTok
- Icônes clés utilisées :
  - `LucideIcons.heart` / `LucideIcons.heartFilled`
  - `LucideIcons.messageCircle`
  - `LucideIcons.bookmark`
  - `LucideIcons.share2`
  - `LucideIcons.search`
  - `LucideIcons.plus`
  - `LucideIcons.music`
  - `LucideIcons.user`
  - `LucideIcons.home`
  - `LucideIcons.x`
  - `LucideIcons.mic`
  - `LucideIcons.settings`

### Animations
```yaml
lottie: ^3.1.0
```
- Pour le spinner splash (2 dots rotatifs)
- Pour l'animation like (cœur rouge burst)
- Alternative : animation custom avec `AnimationController` (plus léger)

### Vertical feed scroll
```yaml
# Pas de package externe nécessaire
# Standard Flutter : PageView.builder(scrollDirection: Axis.vertical)
```

### Marquee (texte défilant — nom du son)
```yaml
marquee: ^2.2.3
```
- Déjà dans watchtower principal → même version
- Usage : nom du son en bas du feed

### Shimmer loading (alternative à skeletonizer)
```yaml
shimmer: ^3.0.0
```
- Plus léger que skeletonizer pour les cas simples
- Usage : thumbnails grille profil

### Pull to refresh
```yaml
# Standard Flutter : RefreshIndicator widget
# Pas de package externe
```

---

## Packages à NE PAS ajouter

| Package | Raison |
|---|---|
| `media_kit` | Requiert Rust/NDK, trop lourd pour ce projet UI |
| `better_player` | Abandonné |
| `flutter_vlc_player` | Requiert compilation native lourde |
| `chewie` | Contrôles inutiles, ajoute du poids |
| `isar` | ORM natif, pas nécessaire pour UI |
| `flutter_qjs` | Engine JS, uniquement dans watchtower principal |

---

## Récapitulatif pubspec.yaml final

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # State
  flutter_riverpod: ^3.1.0
  riverpod_annotation: ^4.0.0
  riverpod: ^3.1.0
  hooks_riverpod: ^3.1.0
  flutter_hooks: ^0.21.0

  # Navigation
  go_router: ^17.2.0

  # Réseau
  http: ^1.6.0

  # Stockage
  shared_preferences: ^2.3.5
  hive: ^2.2.3
  hive_flutter: ^1.1.0

  # UI
  flex_color_scheme: ^8.3.1
  cached_network_image: ^3.4.1
  skeletonizer: ^2.1.0+1
  cupertino_icons: ^1.0.9

  # À ajouter
  video_player: ^2.9.2
  lucide_icons: ^0.484.0
  lottie: ^3.1.0
  marquee: ^2.2.3
  shimmer: ^3.0.0
```
