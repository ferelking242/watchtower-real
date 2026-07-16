class FeedItem {
  const FeedItem({
    required this.id,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.author,
    required this.authorAvatar,
    required this.description,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.bookmarks,
    required this.song,
    required this.hashtags,
    this.isLive = false,
    this.isPhoto = false,
    this.photoUrls = const [],
  });

  final String id;
  final String videoUrl;
  final String thumbnailUrl;
  final String author;
  final String authorAvatar;
  final String description;
  final int likes;
  final int comments;
  final int shares;
  final int bookmarks;
  final String song;
  final List<String> hashtags;
  final bool isLive;
  final bool isPhoto;
  final List<String> photoUrls;
}

/// Format count TikTok style: 263 → "263" · 5919 → "5.9K" · 256000 → "256K" · 1.1M → "1.1M"
String formatCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 10000) return '${(n / 1000).toStringAsFixed(0)}K';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return n.toString();
}

final kMockFeed = [
  // ── Video posts ────────────────────────────────────────────────────────────
  const FeedItem(
    id: '1',
    videoUrl: 'https://www.w3schools.com/html/mov_bbb.mp4',
    thumbnailUrl: 'https://picsum.photos/seed/feed1/400/700',
    author: '@urban_explorer',
    authorAvatar: 'https://i.pravatar.cc/150?img=1',
    description: 'Découverte urbaine au coucher du soleil 🌇',
    likes: 124500, comments: 3210, shares: 872, bookmarks: 4400,
    song: '♪ Blinding Lights — The Weeknd',
    hashtags: ['#urban', '#explore', '#sunset', '#citylife'],
  ),
  const FeedItem(
    id: '2',
    videoUrl: 'https://www.w3schools.com/html/movie.mp4',
    thumbnailUrl: 'https://picsum.photos/seed/feed2/400/700',
    author: '@nature_vibes',
    authorAvatar: 'https://i.pravatar.cc/150?img=2',
    description: 'La forêt après la pluie 🌧️🌿 quelque chose de magique',
    likes: 89200, comments: 1540, shares: 620, bookmarks: 3100,
    song: '♪ Forest Rain — Ambient Nature',
    hashtags: ['#nature', '#forest', '#rain', '#peaceful'],
  ),

  // ── Photo (single image) ──────────────────────────────────────────────────
  const FeedItem(
    id: '3',
    videoUrl: '',
    thumbnailUrl: 'https://picsum.photos/seed/photo1/400/700',
    author: '@MZZ🌸',
    authorAvatar: 'https://i.pravatar.cc/150?img=3',
    description: 'Petite douceur du soir 🌙✨',
    likes: 1090, comments: 9, shares: 52, bookmarks: 263,
    song: '',
    hashtags: ['#latina', '#trend', '#fyp', '#pourtoii'],
    isPhoto: true,
    photoUrls: ['https://picsum.photos/seed/photo1/400/700'],
  ),

  // ── Photo collection (3 images) ───────────────────────────────────────────
  const FeedItem(
    id: '4',
    videoUrl: '',
    thumbnailUrl: 'https://picsum.photos/seed/col1a/400/700',
    author: '@travel_with_me',
    authorAvatar: 'https://i.pravatar.cc/150?img=4',
    description: 'Santorini en 3 photos ☀️🇬🇷 la vue était incroyable',
    likes: 5919, comments: 263, shares: 135, bookmarks: 301,
    song: '♪ Mediterranean Summer — Instrumental',
    hashtags: ['#travel', '#greece', '#santorini'],
    isPhoto: true,
    photoUrls: [
      'https://picsum.photos/seed/col1a/400/700',
      'https://picsum.photos/seed/col1b/400/700',
      'https://picsum.photos/seed/col1c/400/700',
    ],
  ),

  const FeedItem(
    id: '5',
    videoUrl: 'https://www.w3schools.com/html/mov_bbb.mp4',
    thumbnailUrl: 'https://picsum.photos/seed/feed5/400/700',
    author: '@food_art',
    authorAvatar: 'https://i.pravatar.cc/150?img=5',
    description: 'Recette en 60s : pasta carbonara parfaite 🍝',
    likes: 256000, comments: 8900, shares: 3400, bookmarks: 12000,
    song: '♪ Cooking Jazz — Lo-fi Beats',
    hashtags: ['#food', '#pasta', '#recipe', '#cooking'],
  ),
  const FeedItem(
    id: '6',
    videoUrl: 'https://www.w3schools.com/html/movie.mp4',
    thumbnailUrl: 'https://picsum.photos/seed/feed6/400/700',
    author: '@dance_crew',
    authorAvatar: 'https://i.pravatar.cc/150?img=6',
    description: 'LIVE ce soir 21h ! On danse ensemble 💃🕺',
    likes: 445000, comments: 14200, shares: 8700, bookmarks: 22000,
    song: '♪ Levitating — Dua Lipa',
    hashtags: ['#dance', '#crew', '#fyp', '#viral'],
    isLive: true,
  ),

  // ── Photo collection (5 images) ───────────────────────────────────────────
  const FeedItem(
    id: '7',
    videoUrl: '',
    thumbnailUrl: 'https://picsum.photos/seed/col2a/400/700',
    author: '@photo_diary',
    authorAvatar: 'https://i.pravatar.cc/150?img=7',
    description: 'Week-end à Paris 📸 mes 5 meilleurs shots',
    likes: 12300, comments: 547, shares: 891, bookmarks: 2100,
    song: '',
    hashtags: ['#paris', '#photography', '#weekend', '#france'],
    isPhoto: true,
    photoUrls: [
      'https://picsum.photos/seed/col2a/400/700',
      'https://picsum.photos/seed/col2b/400/700',
      'https://picsum.photos/seed/col2c/400/700',
      'https://picsum.photos/seed/col2d/400/700',
      'https://picsum.photos/seed/col2e/400/700',
    ],
  ),
];
