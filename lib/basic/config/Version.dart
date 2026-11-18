import 'dart:async' show Future;
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pikapika/basic/Common.dart';
import 'package:pikapika/basic/Cross.dart';
import 'package:pikapika/i18.dart';

import '../Method.dart';
import 'HideAnnouncement.dart';
import 'IgnoreUpgradeConfirm.dart';

const _versionAssets = 'lib/assets/version.txt';

late String _version;
String? _latestVersion;
String? _latestVersionInfo;
String? _downloadUrl;
String _announcement = "";

Future initVersion() async {
  // 当前版本
  try {
    _version = (await rootBundle.loadString(_versionAssets)).trim();
  } catch (e) {
    _version = "dirty";
  }
}

var versionEvent = Event<EventArgs>();

String currentVersion() {
  return _version;
}

String? latestVersion() {
  return _latestVersion;
}

String? latestVersionInfo() {
  return _latestVersionInfo;
}

String? downloadUrl() {
  return _downloadUrl;
}

Future autoCheckNewVersion() {
  // if (!isPro) {
  //   return Future.value();
  // }
  return _versionCheck();
}

Future manualCheckNewVersion(BuildContext context) async {
  try {
    defaultToast(context, "检查更新中");
    await _versionCheck();
    defaultToast(context, "检查更新成功");
  } catch (e) {
    defaultToast(context, "检查更新失败 : $e");
  }
}

bool dirtyVersion() {
  return "dirty" == _version;
}

// maybe exception
Future _versionCheck() async {
  if (!dirtyVersion()) {
    var config = await method.appConfig();
    _announcement = config.announcement;
    if (config.latestVersion.isNotEmpty) {
      String latestVersion = config.latestVersion;
      if (latestVersion != _version && _isServerNewer(_version, latestVersion)) {
        _latestVersion = latestVersion;
        _latestVersionInfo = config.changeLog;
        _downloadUrl = config.downloadUrl;
      } else {
        _latestVersion = null;
        _latestVersionInfo = null;
        _downloadUrl = null;
      }
    } else {
      _latestVersion = null;
      _latestVersionInfo = null;
      _downloadUrl = null;
    }
  } // else dirtyVersion
  versionEvent.broadcast();
}

bool _isServerNewer(String current, String latest) {
  final c = _SemVer.parse(current);
  final l = _SemVer.parse(latest);
  if (c == null || l == null) return false;
  if (l.major != c.major) return l.major > c.major;
  if (l.minor != c.minor) return l.minor > c.minor;
  return l.patch > c.patch;
}

var _display = true;
var _versionGate = false;
var _announcementBusy = false;
var _announcementDone = false;

void versionPop(BuildContext context) {
  if (_versionGate) return;
  final latest = latestVersion();
  final force = latest != null && _isForceUpgrade(currentVersion(), latest);
  final showForce = latest != null && _display && force && !ignoreUpgradeConfirm;
  if (showForce) {
    _display = false;
    _versionGate = true;
    _announcementPop(context).whenComplete(() {
      if (!context.mounted) return;
      TopConfirm.topConfirm(
        context,
        "发现新版本",
        "发现新版本 $latest，请立即更新后继续使用",
        force: true,
        primaryText: "去下载",
        onPrimary: () async {
          _openRelease(context);
        },
      );
    });
    return;
  }
  _announcementPop(context);
}

Future<void> _announcementPop(BuildContext context) async {
  if (hideAnnouncement || _announcementDone || _announcementBusy) return;
  final text = _announcement.trim();
  if (text.isEmpty) return;
  _announcementBusy = true;
  try {
    final hash = sha256.convert(utf8.encode(text)).toString();
    final saved = await method.loadProperty("announcement_read", "");
    if (!context.mounted) return;
    if (saved == hash) {
      _announcementDone = true;
      return;
    }
    _announcementDone = true;
    final remember = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: Text(tr("screen.pro.announcement")),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
          child: SingleChildScrollView(child: Text(text)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(tr("screen.pro.announcement_close")),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(tr("screen.pro.announcement_dismiss")),
          ),
        ],
      ),
    );
    if (remember == true) {
      await method.saveProperty("announcement_read", hash);
    }
  } catch (_) {
  } finally {
    _announcementBusy = false;
  }
}

class _SemVer {
  final int major;
  final int minor;
  final int patch;

  const _SemVer(this.major, this.minor, this.patch);

  static _SemVer? parse(String input) {
    // todo remove first v
    if (input.startsWith('v')) {
      input = input.substring(1);
    }
    final regExp = RegExp(r'^(\d+)\.(\d+)\.(\d+)$');
    final m = regExp.firstMatch(input);
    if (m == null) return null;
    return _SemVer(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
    );
  }

  @override
  String toString() {
    return '$major.$minor.$patch'; 
  }
}

bool _isForceUpgrade(String current, String latest) {
  print("checking force upgrade...");
  print("current version string: $current, latest version string: $latest");
  final c = _SemVer.parse(current);
  final l = _SemVer.parse(latest);
  print("current version: $c, latest version: $l");
  if (c == null || l == null) return false;

  if (l.major != c.major) return true;
  if (l.minor != c.minor) return true;
  return false;
}

Future<void> _openRelease(BuildContext context) async {
  try {
    if (_downloadUrl != null && _downloadUrl!.isNotEmpty) {
      await openUrl(_downloadUrl!);
    }
  } catch (_) {
    defaultToast(context, "下载失败");
  }
}

class TopConfirm {
  static topConfirm(BuildContext context, String title, String message,
      {bool force = false,
      String primaryText = "朕知道了",
      Future<void> Function()? onPrimary,
      Function()? afterIKnown}) {
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(builder: (BuildContext context) {
      return LayoutBuilder(
        builder: (
          BuildContext context,
          BoxConstraints constraints,
        ) {
          var mq = MediaQuery.of(context).size.width - 30;
          return Material(
            color: Colors.transparent,
            child: Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(.35),
              ),
              child: Column(
                children: [
                  Expanded(child: Container()),
                  Container(
                    width: mq,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Container(height: 30),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 28,
                          ),
                        ),
                        Container(height: 15),
                        Text(
                          message,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                        Container(height: 25),
                        MaterialButton(
                          elevation: 0,
                          color: Colors.black.withOpacity(.1),
                          onPressed: () {
                            if (onPrimary != null) {
                              onPrimary();
                            }
                            if (!force) {
                              overlayEntry.remove();
                            }
                            afterIKnown?.call();
                          },
                          child: Text(primaryText),
                        ),
                        Container(height: 30),
                      ],
                    ),
                  ),
                  Expanded(child: Container()),
                ],
              ),
            ),
          );
        },
      );
    });
    final overlay = Overlay.of(context);
    overlay?.insert(overlayEntry);
  }
}
