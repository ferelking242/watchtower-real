import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:watchtower_real/features/connect/connect_screen.dart';
import 'package:watchtower_real/features/feed/feed_screen.dart';
import 'package:watchtower_real/features/inbox/inbox_screen.dart';
import 'package:watchtower_real/features/live/live_multi_screen.dart';
import 'package:watchtower_real/features/profile/profile_screen.dart';
import 'package:watchtower_real/features/search/search_screen.dart';
import 'package:watchtower_real/remote/remote_config_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      // If navigating to connect screen, let it through
      if (state.matchedLocation == '/connect') return null;

      // Check if configured — allow unconfigured (demo mode passes through)
      // Only hard-redirect to /connect on first launch (no saved config at all)
      final config = ref.read(remoteConfigProvider);

      // While config is loading, go to feed — it handles demo mode
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const FeedScreen(),
      ),
      GoRoute(
        path: '/connect',
        builder: (context, state) => const ConnectScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/inbox',
        builder: (context, state) => const InboxScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/:userId',
        builder: (context, state) => ProfileScreen(
          userId: state.pathParameters['userId'],
        ),
      ),
      GoRoute(
        path: '/live',
        builder: (context, state) => const LiveMultiScreen(),
      ),
      GoRoute(
        path: '/live/:hostId',
        builder: (context, state) => LiveMultiScreen(
          hostId: state.pathParameters['hostId'],
        ),
      ),
    ],
  );
});
