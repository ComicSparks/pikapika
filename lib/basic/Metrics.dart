import 'package:pikapika/basic/config/Version.dart';
import 'package:pikapika/src/rust/api/metrics.dart' as api;

/// 只记动作名。账号、版本、语言和发电状态由 Rust 按小时合成一批。
class Metrics {
  Metrics._();

  static bool _appNoted = false;
  static bool _versionSent = false;

  static void note(String name) {
    try {
      api.metricsNote(name: name);
    } catch (_) {}
  }

  static void noteApp() {
    if (_appNoted) return;
    _appNoted = true;
    note('app');
  }

  static Future<void> syncVersion() async {
    if (_versionSent) return;
    try {
      api.metricsSetVersion(version: currentVersion());
      _versionSent = true;
    } catch (_) {}
  }

  static void syncLocale(String locale) {
    try {
      final code = locale.trim();
      if (code.isNotEmpty) {
        api.metricsSetLocale(locale: code);
      }
    } catch (_) {}
  }

  static void flush() {
    api.metricsFlush().catchError((_) {});
  }
}
