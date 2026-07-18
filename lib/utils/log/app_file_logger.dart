import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Singleton file logger.
/// Writes timestamped entries to `<app-documents>/watchtower_debug.log`.
/// Also mirrors every entry to [debugPrint] so they appear in the IDE/Logcat.
class AppFileLogger {
  AppFileLogger._();
  static final AppFileLogger instance = AppFileLogger._();

  IOSink? _sink;
  File? _logFile;
  bool _initializing = false;
  bool _ready = false;

  /// Call once in `main()` before `runApp()`.
  Future<void> init() async {
    if (_ready || _initializing) return;
    _initializing = true;
    try {
      final dir = await getApplicationDocumentsDirectory();
      _logFile = File('${dir.path}/watchtower_debug.log');
      _sink = _logFile!.openWrite(mode: FileMode.append);
      _ready = true;
      _write('══════════════════════════════════════════');
      _write('Watchtower logger init — ${DateTime.now().toIso8601String()}');
      _write('Log path: ${_logFile!.path}');
    } catch (e) {
      debugPrint('[FileLogger] init failed: $e');
    } finally {
      _initializing = false;
    }
  }

  void _write(String line) {
    final entry = '[${DateTime.now().toIso8601String()}] $line';
    debugPrint(entry);
    try {
      _sink?.writeln(entry);
    } catch (_) {}
  }

  /// General log entry.
  void log(String tag, String message) => _write('[$tag] $message');

  /// Error entry (includes stack trace if provided).
  void error(String tag, Object error, [StackTrace? st]) {
    _write('[$tag][ERROR] $error');
    if (st != null) _write('[$tag][STACK] $st');
  }

  /// Flush and close the log file (call on app terminate if needed).
  Future<void> close() async {
    try {
      await _sink?.flush();
      await _sink?.close();
    } catch (_) {}
    _ready = false;
  }

  /// Returns the last [maxLines] lines from the log file, or null if unavailable.
  Future<String?> tail({int maxLines = 200}) async {
    if (_logFile == null || !_logFile!.existsSync()) return null;
    try {
      final lines = await _logFile!.readAsLines();
      final slice = lines.length <= maxLines
          ? lines
          : lines.sublist(lines.length - maxLines);
      return slice.join('\n');
    } catch (e) {
      return 'Error reading log: $e';
    }
  }
}

/// Convenience shortcut.
final logger = AppFileLogger.instance;
