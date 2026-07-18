import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchtower_real/router/router.dart';

class WatchtowerRealApp extends ConsumerWidget {
  const WatchtowerRealApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Watchtower Real',
      debugShowCheckedModeBanner: false,
      theme: FlexThemeData.light(scheme: FlexScheme.deepBlue),
      darkTheme: FlexThemeData.dark(scheme: FlexScheme.deepBlue),
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
