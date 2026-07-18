import 'dart:async';
import 'package:http/http.dart' as http;
import 'ntfy_config.dart';

/// Envoie des logs push vers ntfy.sh en fire-and-forget.
/// Topic : [NtfyConfig.topic]  →  https://ntfy.sh/watchtower-real
class NtfyLogger {
  static void info(String msg, {String? title}) => _send(
        msg,
        title: title ?? '📱 ${NtfyConfig.appName}',
        priority: 'low',
        tags: 'information_source',
      );

  static void warn(String msg, {String? title}) => _send(
        msg,
        title: title ?? '⚠️ ${NtfyConfig.appName}',
        priority: 'default',
        tags: 'warning',
      );

  static void error(String msg, {String? title}) => _send(
        msg,
        title: title ?? '🔴 ${NtfyConfig.appName} Error',
        priority: 'high',
        tags: 'rotating_light',
      );

  static void ok(String msg, {String? title}) => _send(
        msg,
        title: title ?? '✅ ${NtfyConfig.appName}',
        priority: 'low',
        tags: 'white_check_mark',
      );

  static void _send(String body, {
    required String title,
    required String priority,
    required String tags,
  }) {
    // Fire and forget — ne bloque jamais l'UI
    _unawaited(
      http.post(
        Uri.parse(NtfyConfig.topic),
        headers: {
          'Title':    title,
          'Priority': priority,
          'Tags':     tags,
        },
        body: body,
      ).timeout(const Duration(seconds: 5)),
    );
  }
}

void _unawaited(Future<dynamic> f) => f.catchError((_) {});
