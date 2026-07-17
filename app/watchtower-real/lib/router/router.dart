import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/feed/feed_screen.dart';
import '../features/connect/connect_screen.dart';
import '../features/profile/profile_screen.dart';

final router = GoRouter(
  initialLocation: '/',
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
      path: '/connect',
      name: 'connect',
      pageBuilder: (context, state) => const MaterialPage(
        child: ConnectScreen(),
      ),
    ),
  ],
);
