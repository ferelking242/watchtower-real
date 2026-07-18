import 'dart:async';
import 'package:http/http.dart' as http;

/// Sends push log messages to ntfy.sh so you can watch the app live.
/// Topic: https://ntfy.sh/watchtower-app  (subscribe on your phone)
class NtfyLogger {
  static const _topic = 'https://ntfy.sh/watchtower-app';

  /// Send a debug/info message (low priority).
  static void info(String msg, {String? title}) =>
      _send(msg, title: title ?? '📱 Watchtower', priority: 'low', tags: 'information_source');

  /// Send a warning (remote fallback, etc.).
  static void warn(String msg, {String? title}) =>
      _send(msg, title: title ?? '⚠️ Watchtower', priority: 'default', tags: 'warning');

  /// Send an error (high priority).
  static void error(String msg, {String? title}) =>
      _send(msg, title: title ?? '🔴 Watchtower Error', priority: 'high', tags: 'rotating_light');

  /// Send a success message.
  static void ok(String msg, {String? title}) =>
      _send(msg, title: title ?? '✅ Watchtower', priority: 'low', tags: 'white_check_mark');

  static void _send(String body, {
    required String title,
    required String priority,
    required String tags,
  }) {
    // Fire and forget — never block the UI
    unawaited(
      http.post(
        Uri.parse(_topic),
        headers: {
          'Title': title,
          'Priority': priority,
          'Tags': tags,
        },
        body: body,
      ).timeout(const Duration(seconds: 5)),
    );
  }
}

void unawaited(Future<dynamic> f) => f.catchError((_) {});
