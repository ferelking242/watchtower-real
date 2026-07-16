import '../models/feed_item.dart';

/// Données de démonstration (utilisées quand aucun serveur Watchtower n'est configuré).
/// Les vidéos sont des fichiers libres de droits de Google Storage.
/// En production, remplacées par l'API /api/sources/:id/popular + /videos.
const List<FeedItem> mockFeedItems = [
  FeedItem(
    id: '1',
    videoUrl:
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4',
    thumbnailUrl: 'https://picsum.photos/seed/anime1/400/711',
    title: 'Épée du Vent — Épisode 12 🔥 Le combat final approche !',
    authorUsername: '@watchtower_clips',
    authorAvatar: 'https://picsum.photos/seed/avatar1/100/100',
    likes: 52700,
    comments: 1843,
    shares: 3290,
    bookmarks: 912,
    hashtags: ['anime', 'action', 'fyp', 'watchtower'],
    soundName: '♪ Epic Battle Theme — Two Steps From Hell',
  ),
  FeedItem(
    id: '2',
    videoUrl:
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
    thumbnailUrl: 'https://picsum.photos/seed/anime2/400/711',
    title: 'Le roi des démons se réveille après 1000 ans 😱',
    authorUsername: '@animerealm_fr',
    authorAvatar: 'https://picsum.photos/seed/avatar2/100/100',
    likes: 128400,
    comments: 4521,
    shares: 8107,
    bookmarks: 2341,
    hashtags: ['demon', 'isekai', 'manga', 'anime2026'],
    soundName: '♪ Shinzou wo Sasageyo — Linked Horizon',
    isFollowing: true,
  ),
  FeedItem(
    id: '3',
    videoUrl:
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    thumbnailUrl: 'https://picsum.photos/seed/anime3/400/711',
    title: 'Ce twist de fin d\'arc m\'a laissé sans voix 🤯🤯',
    authorUsername: '@nekotv_official',
    authorAvatar: 'https://picsum.photos/seed/avatar3/100/100',
    likes: 89200,
    comments: 7012,
    shares: 5443,
    bookmarks: 1870,
    hashtags: ['twist', 'spoiler', 'onepiece', 'foru'],
    soundName: '♪ We Are — Hiroshi Kitadani',
  ),
  FeedItem(
    id: '4',
    videoUrl:
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    thumbnailUrl: 'https://picsum.photos/seed/anime4/400/711',
    title: 'Meilleure scène de combat de l\'année — Chapter 412',
    authorUsername: '@mangascans_hd',
    authorAvatar: 'https://picsum.photos/seed/avatar4/100/100',
    likes: 214000,
    comments: 9832,
    shares: 14500,
    bookmarks: 5621,
    hashtags: ['combat', 'jujutsu', 'sakuna', 'manga'],
    soundName: '♪ SPECIALZ — King Gnu',
    isFollowing: true,
  ),
  FeedItem(
    id: '5',
    videoUrl:
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    thumbnailUrl: 'https://picsum.photos/seed/anime5/400/711',
    title: 'Cet opening est trop beau pour être réel ✨',
    authorUsername: '@animeops_4ever',
    authorAvatar: 'https://picsum.photos/seed/avatar5/100/100',
    likes: 67300,
    comments: 2100,
    shares: 4780,
    bookmarks: 1230,
    hashtags: ['opening', 'op', 'banger', 'anime'],
    soundName: '♪ Idol — YOASOBI',
  ),
  FeedItem(
    id: '6',
    videoUrl:
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
    thumbnailUrl: 'https://picsum.photos/seed/anime6/400/711',
    title: 'Top 10 des animes oubliés qui méritent une saison 2',
    authorUsername: '@animehistory',
    authorAvatar: 'https://picsum.photos/seed/avatar6/100/100',
    likes: 43100,
    comments: 3450,
    shares: 2100,
    bookmarks: 890,
    hashtags: ['top10', 'retro', 'oldanime', 'saison2'],
    soundName: '♪ Moonlight Densetsu — DALI',
  ),
];
