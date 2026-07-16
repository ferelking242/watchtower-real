# .design — Guide de design Watchtower Real

Référence complète pour reproduire l'UI TikTok dans l'app `watchtower-real`.

## Fichiers

| Fichier | Contenu |
|---|---|
| `SCREENS.md` | Inventaire des 19 écrans avec specs détaillées |
| `TOKENS.md` | Couleurs, typo, espacement, animations |
| `LIBRARIES.md` | Packages Flutter recommandés + pubspec final |
| `ARCHITECTURE.md` | Structure `lib/`, routes, flux de données |
| `COMPONENTS.md` | Specs pixel-perfect de chaque composant |
| `screenshots/` | 19 captures renommées par écran |

## Ordre de développement recommandé

### Phase 1 — Fondations (à faire maintenant)
1. `core/theme/` — tokens + ThemeData
2. `core/widgets/` — Avatar, LiveBadge, VideoThumbnailCard
3. Bottom navigation + routes vides

### Phase 2 — Feed (écran principal)
4. `FeedScreen` avec `PageView.builder` vertical
5. `FeedItem` avec `VideoPlayerController`
6. `FeedSidebar` (like/comment/share)
7. `FeedOverlayBottom` (username/description/son)
8. `FeedHeader` (Suivis/Pour toi)

### Phase 3 — Recherche
9. `SearchScreen` + `SearchSuggestions`
10. `SearchResultsScreen` avec tabs
11. `SearchFiltersSheet`

### Phase 4 — Profil & Inbox
12. `ProfileScreen` + tabs
13. `InboxScreen`

### Phase 5 — Connexion au serveur distant
14. Configurer l'URL du serveur Watchtower (mode distant APK)
15. Brancher `FeedProvider` → `/api/sources/redgift/popular`
16. Brancher `SearchProvider` → `/api/sources/redgift/search`

## Palette de couleurs rapide

```
#EE1D52  ← Rouge brand (CTA, likes, badges)
#69C9D0  ← Cyan brand (loader, accents)
#000000  ← Fond feed
#FFFFFF  ← Fond search/profil
#121212  ← Fond app
#F2F2F2  ← Chips / inputs light
#8A8A8A  ← Texte secondaire
```

## Règles UI critiques

1. **Le feed est toujours plein écran** — aucun padding, aucune margin
2. **Bottom nav transparent sur le feed** — noir opaque sur les autres écrans
3. **Header du feed = flottant** — ne décale pas le contenu vidéo
4. **Sidebar droite = toujours visible** — jamais caché derrière la bottom nav
5. **PageView vertical** — pas de scroll horizontal sur le feed
6. **Un seul VideoPlayerController actif** — les autres sont pausés/disposés
7. **Chips filtres** — actif = bordure noire, inactif = fond gris léger
8. **Grille profil** — exactement 2px de gap entre tiles, pas plus
