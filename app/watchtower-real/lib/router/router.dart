import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/feed/feed_screen.dart';

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
    // TODO : ajouter les routes au fur et à mesure
    // GoRoute(path: '/search', name: 'search', ...),
    // GoRoute(path: '/profile', name: 'profile', ...),
    // GoRoute(path: '/inbox', name: 'inbox', ...),
  ],
);
