import 'package:package_info_plus/package_info_plus.dart';
import 'package:reel/utils/log/app_file_logger.dart';

/// Singleton holding the app's version strings.
/// Call [init] once in `main()` before using [version] / [buildNumber].
class AppVersion {
  AppVersion._();

  static String _version = '0.0.0';
  static String _buildNumber = '0';

  static String get version => _version;
  static String get buildNumber => _buildNumber;

  /// Human-readable string sent in the `X-App-Version` header.
  static String get headerValue => '$_version+$_buildNumber';

  static Future<void> init() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _version = info.version;
      _buildNumber = info.buildNumber;
    } catch (e) {
      logger.error('APP_VERSION', e);
    }
  }
}
