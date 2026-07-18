import 'dart:async';
import 'dart:collection';

/// Token-bucket rate limiter for the remote API server.
///
/// Each client (identified by IP or API key) gets its own bucket of
/// [maxTokens] tokens, refilled at a rate of [maxTokens] per [window].
/// When the bucket is empty the request should be rejected with HTTP 429.
class RateLimiter {
  RateLimiter({
    this.window   = const Duration(minutes: 1),
    this.maxTokens = 60,
  });

  final Duration window;
  final int maxTokens;

  final Map<String, _Bucket> _buckets = HashMap();
  Timer? _cleanupTimer;

  /// Call once to start background cleanup of idle buckets.
  void startCleanup() {
    _cleanupTimer ??= Timer.periodic(
      const Duration(minutes: 5),
      (_) => _cleanup(),
    );
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _buckets.clear();
  }

  /// Returns `true` if the request is allowed, `false` if rate-limited.
  bool allow(String clientKey) {
    final bucket = _buckets.putIfAbsent(
      clientKey,
      () => _Bucket(maxTokens, window),
    );
    return bucket.consume();
  }

  void _cleanup() {
    final cutoff = DateTime.now().subtract(window * 2);
    _buckets.removeWhere((_, b) => b.lastFill.isBefore(cutoff));
  }
}

class _Bucket {
  _Bucket(this._maxTokens, this._window) : tokens = _maxTokens.toDouble();

  final int      _maxTokens;
  final Duration _window;
  double         tokens;
  DateTime       lastFill = DateTime.now();

  bool consume() {
    final now   = DateTime.now();
    final delta = now.difference(lastFill);
    final refill = (delta.inMilliseconds / _window.inMilliseconds) * _maxTokens;
    tokens   = (tokens + refill).clamp(0, _maxTokens.toDouble());
    lastFill = now;
    if (tokens < 1) return false;
    tokens--;
    return true;
  }
}
