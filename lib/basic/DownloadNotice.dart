import 'dart:async';
import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:pikapika/i18.dart';

import 'Channels.dart';
import 'Entities.dart';
import 'Method.dart';
import 'config/DownloadPersistentNotice.dart';

DownloadComic? _current;
bool _started = false;
bool _visible = false;
bool _permissionAsked = false;
bool _syncing = false;
bool _syncAgain = false;
String? _shownKey;

Future<void> startDownloadNotice() async {
  if (!Platform.isAndroid || _started) {
    return;
  }
  _started = true;
  registerEvent(_onDownload, "DOWNLOAD");
  Timer.periodic(const Duration(seconds: 3), (_) {
    syncDownloadNotice();
  });
  await syncDownloadNotice();
}

void _onDownload(AppEvent event) {
  if (event case AppEvent_Download(:final comic)) {
    _current = comic;
    syncDownloadNotice();
  }
}

Future<void> syncDownloadNotice() async {
  if (!Platform.isAndroid) {
    return;
  }
  if (_syncing) {
    _syncAgain = true;
    return;
  }
  _syncing = true;
  try {
    do {
      _syncAgain = false;
      await _syncOnce();
    } while (_syncAgain);
  } finally {
    _syncing = false;
  }
}

Future<void> _syncOnce() async {
  if (!downloadPersistentNotice()) {
    await _cancel();
    return;
  }
  try {
    final list = await method.allDownloads("");
    final unfinished =
        list.where((item) => !item.downloadFinished && !item.deleting).toList();
    if (unfinished.isEmpty) {
      _current = null;
      await _cancel();
      return;
    }
    final title = tr("settings.download_persistent_notice.notification_title");
    final count = "${unfinished.length}";
    final running = await method.downloadRunning();
    final active = unfinished.where((item) => !item.downloadFailed).toList();
    final String body;
    if (running && active.isNotEmpty) {
      final current = _pickCurrent(active);
      _current = current;
      body = tr("settings.download_persistent_notice.notification_body_current")
          .replaceAll("{title}", current.title)
          .replaceAll("{done}", "${current.downloadPictureCount}")
          .replaceAll("{total}", "${current.selectedPictureCount}")
          .replaceAll("{count}", count);
    } else {
      body = tr("settings.download_persistent_notice.notification_body")
          .replaceAll("{count}", count);
    }
    final key = "$title\n$body";
    if (_visible && key == _shownKey) {
      return;
    }
    if (!await _ensurePermission() || !downloadPersistentNotice()) {
      return;
    }
    await method.showDownloadNotice(title, body);
    _shownKey = key;
    _visible = true;
  } catch (_) {}
}

DownloadComic _pickCurrent(List<DownloadComic> active) {
  final current = _current;
  if (current != null) {
    for (final item in active) {
      if (item.id == current.id) {
        return item;
      }
    }
  }
  return active.first;
}

Future<bool> _ensurePermission() async {
  final status = await Permission.notification.status;
  if (status.isGranted) {
    return true;
  }
  if (_permissionAsked || status.isPermanentlyDenied) {
    _permissionAsked = true;
    return false;
  }
  _permissionAsked = true;
  final result = await Permission.notification.request();
  return result.isGranted;
}

Future<void> _cancel() async {
  _shownKey = null;
  if (!_visible) {
    return;
  }
  _visible = false;
  try {
    await method.cancelDownloadNotice();
  } catch (_) {}
}
