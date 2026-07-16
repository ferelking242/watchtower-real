import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/feed_item.dart';
import '../data/mock_feed.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Index de la page active (partagé entre FeedScreen et les FeedPage)
// ─────────────────────────────────────────────────────────────────────────────
final currentFeedIndexProvider = StateProvider<int>((ref) => 0);

// ─────────────────────────────────────────────────────────────────────────────
// Tab actif : 0 = "Pour toi", 1 = "Suivis"
// ─────────────────────────────────────────────────────────────────────────────
final feedTabProvider = StateProvider<int>((ref) => 0);

// ─────────────────────────────────────────────────────────────────────────────
// Feed items
// Actuellement : données mock.
// TODO : quand remoteConfigProvider a une URL, fetch /api/sources/:id/popular
// ─────────────────────────────────────────────────────────────────────────────
final feedItemsProvider =
    StateNotifierProvider<FeedNotifier, AsyncValue<List<FeedItem>>>(
  (ref) => FeedNotifier(),
);

class FeedNotifier extends StateNotifier<AsyncValue<List<FeedItem>>> {
  FeedNotifier() : super(const AsyncValue.loading()) {
    _loadMock();
  }

  Future<void> _loadMock() async {
    // Petite pause pour simuler un vrai chargement
    await Future.delayed(const Duration(milliseconds: 600));
    state = AsyncValue.data(List.from(mockFeedItems));
  }

  // TODO : appeler quand le serveur Watchtower est configuré
  // Future<void> loadFromServer(RemoteApiClient client, String sourceId) async {
  //   state = const AsyncValue.loading();
  //   try {
  //     final items = await client.getPopular(sourceId);
  //     state = AsyncValue.data(items.map(_toFeedItem).toList());
  //   } catch (e, s) {
  //     state = AsyncValue.error(e, s);
  //   }
  // }
}
