# Architecture des écrans

## Structure lib/

```
lib/
├── core/
│   ├── theme/
│   │   ├── tokens.dart          ← couleurs, typo, spacing (voir TOKENS.md)
│   │   ├── app_theme.dart       ← ThemeData light + dark
│   │   └── text_styles.dart     ← TextStyles nommés
│   └── widgets/
│       ├── avatar.dart          ← Avatar circulaire réutilisable
│       ├── live_badge.dart      ← Badge LIVE rouge pulsant
│       ├── video_thumbnail.dart ← Thumbnail avec overlay play+count
│       └── follow_button.dart   ← Bouton Suivre/Suivi
│
├── remote/
│   ├── remote_client.dart       ← ✅ déjà créé
│   └── remote_config_provider.dart ← ✅ déjà créé
│
├── features/
│   ├── feed/
│   │   ├── feed_screen.dart         ← PageView vertical plein écran
│   │   ├── feed_item.dart           ← Un item du feed (vidéo + overlays)
│   │   ├── feed_sidebar.dart        ← Colonne droite (like/comment/share)
│   │   ├── feed_overlay_bottom.dart ← Overlay bas-gauche (user/desc/son)
│   │   ├── feed_header.dart         ← Header flottant (Suivis|Pour toi)
│   │   ├── live_stories_row.dart    ← Row stories LIVE en haut
│   │   └── providers/
│   │       └── feed_provider.dart   ← fetch popular depuis API remote
│   │
│   ├── search/
│   │   ├── search_screen.dart           ← Conteneur (switche entre états)
│   │   ├── search_suggestions.dart      ← Historique + tendances
│   │   ├── search_voice.dart            ← Saisie vocale + animation
│   │   ├── search_results_screen.dart   ← Tabs Top/Vidéos/Utilisateurs/Sons/LIVE/Hashtags
│   │   ├── tabs/
│   │   │   ├── results_top_tab.dart
│   │   │   ├── results_videos_tab.dart
│   │   │   ├── results_users_tab.dart
│   │   │   └── results_hashtags_tab.dart
│   │   ├── search_filters_sheet.dart    ← Bottom sheet filtres
│   │   └── providers/
│   │       └── search_provider.dart
│   │
│   ├── profile/
│   │   ├── profile_screen.dart          ← Profil avec tabs
│   │   ├── profile_header.dart          ← Avatar + stats + boutons
│   │   ├── profile_tabs.dart            ← 5 tabs (vidéos/privé/repost/sauvegardé/aimés)
│   │   ├── profile_grid.dart            ← Grille 3 colonnes réutilisable
│   │   ├── profile_settings_sheet.dart  ← Menu bottom sheet
│   │   └── providers/
│   │       └── profile_provider.dart
│   │
│   ├── inbox/
│   │   ├── inbox_screen.dart            ← Boîte de réception
│   │   └── providers/
│   │       └── inbox_provider.dart
│   │
│   └── live/
│       ├── live_multi_screen.dart       ← Vue LIVE multi-invités
│       └── providers/
│           └── live_provider.dart
│
├── router/
│   └── router.dart                      ← ✅ déjà créé (à étoffer)
│
├── app.dart                             ← ✅ déjà créé
└── main.dart                            ← ✅ déjà créé
```

---

## Routes (GoRouter)

```
/                     → FeedScreen
/search               → SearchScreen
/search/results       → SearchResultsScreen (query params: q=, tab=)
/profile              → ProfileScreen (propre profil)
/profile/:userId      → ProfileScreen (autre utilisateur)
/inbox                → InboxScreen
/live/:hostId         → LiveMultiScreen
```

---

## Flux de données (Riverpod)

```
RemoteConfigProvider (URL + API key)
    ↓
RemoteClientProvider (instancie RemoteApiClient)
    ↓
FeedProvider         → GET /api/sources/:id/popular?page=N
SearchProvider       → GET /api/sources/:id/search?query=&page=N
ProfileProvider      → données locales (pas dans l'API remote pour l'instant)
```

---

## Gestion de l'état du feed

```
FeedState {
  items: List<FeedItem>
  currentIndex: int
  isLoading: bool
  hasMore: bool
  sourceId: String      ← ex: "redgift" ou autre
}

FeedItem {
  id: String
  videoUrl: String      ← de /api/sources/:id/videos
  thumbnailUrl: String
  title: String
  author: String
  authorAvatar: String
  likes: int
  comments: int
  shares: int
  hashtags: List<String>
  soundName: String
}
```

**Pré-chargement** : quand `currentIndex >= items.length - 3`, fetch page suivante.

---

## Widget Feed (PageView) — logique clé

```dart
// Chaque page = 1 vidéo
// Le VideoPlayerController est pré-initialisé pour page N+1
// Dispose automatique à N-2

class FeedItem extends HookConsumerWidget {
  // useEffect: init controller au mount, pause quand index != current
  // Controller lifecycle: init → play → pause → dispose
}
```

---

## Bottom Navigation

```dart
// 5 items, bouton central (Create) = modal plein écran
// Badge rouge sur Inbox (compteur non-lus)
// Background: noir avec blur sur le feed, blanc sur search/profile
```
