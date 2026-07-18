import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/feed/feed_screen.dart';
import '../features/connect/connect_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/friends/friends_screen.dart';
import '../features/inbox/inbox_screen.dart';

final router = GoRouter(
  initialLocation: '/connect',
  debugLogDiagnostics: false,
  routes: [
    GoRoute(
      path: '/',
      name: 'feed',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: FeedScreen(),
      ),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      pageBuilder: (context, state) => const MaterialPage(
        child: ProfileScreen(),
      ),
    ),
    GoRoute(
      path: '/friends',
      name: 'friends',
      pageBuilder: (context, state) => const MaterialPage(
        child: FriendsScreen(),
      ),
    ),
    GoRoute(
      path: '/inbox',
      name: 'inbox',
      pageBuilder: (context, state) => const MaterialPage(
        child: InboxScreen(),
      ),
    ),
    GoRoute(
      path: '/connect',
      name: 'connect',
      pageBuilder: (context, state) => const MaterialPage(
        child: ConnectScreen(),
      ),
    ),
  ],
);
