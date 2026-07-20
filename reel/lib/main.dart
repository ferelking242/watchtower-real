import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:reel/app.dart';
import 'package:reel/utils/log/app_file_logger.dart';
import 'package:reel/remote/app_version.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 1. File logger ──────────────────────────────────────────────────────────
  await AppFileLogger.instance.init();
  logger.log('MAIN', 'App starting…');

  // ── 2. MediaKit (doit être initialisé avant tout Player) ────────────────────
  MediaKit.ensureInitialized();
  logger.log('MAIN', 'MediaKit initialised');

  // ── 3. App version ──────────────────────────────────────────────────────────
  await AppVersion.init();
  logger.log('MAIN', 'Version: ${AppVersion.version}+${AppVersion.buildNumber}');

  // ── 4. Hive ─────────────────────────────────────────────────────────────────
  await Hive.initFlutter();
  logger.log('MAIN', 'Hive initialised');

  // ── 5. Flutter error hooks ──────────────────────────────────────────────────
  FlutterError.onError = (details) {
    logger.error('FLUTTER', details.exception, details.stack);
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, st) {
    logger.error('PLATFORM', error, st);
    return false;
  };

  logger.log('MAIN', 'Launching ProviderScope…');
  runZonedGuarded(
    () => runApp(const ProviderScope(child: ReelApp())),
    (error, st) => logger.error('ZONE', error, st),
  );
}
