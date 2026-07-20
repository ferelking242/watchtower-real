class FeedItem {
  const FeedItem({
    required this.id,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.title,
    required this.authorUsername,
    required this.authorAvatar,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.bookmarks,
    required this.hashtags,
    required this.soundName,
    this.isFollowing = false,
  });

  final String id;
  final String videoUrl;
  final String thumbnailUrl;
  final String title;
  final String authorUsername;
  final String authorAvatar;
  final int likes;
  final int comments;
  final int shares;
  final int bookmarks;
  final List<String> hashtags;
  final String soundName;
  final bool isFollowing;

  String get formattedLikes => _format(likes);
  String get formattedComments => _format(comments);
  String get formattedShares => _format(shares);
  String get formattedBookmarks => _format(bookmarks);

  static String _format(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
