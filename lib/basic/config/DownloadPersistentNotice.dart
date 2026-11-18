import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pikapika/i18.dart';

import '../DownloadNotice.dart';
import '../Method.dart';

const _propertyName = "downloadPersistentNotice";

late bool _downloadPersistentNotice;

Future initDownloadPersistentNotice() async {
  _downloadPersistentNotice =
      (await method.loadProperty(_propertyName, "true")) == "true";
}

bool downloadPersistentNotice() {
  return _downloadPersistentNotice;
}

Widget downloadPersistentNoticeSetting() {
  if (!Platform.isAndroid) {
    return Container();
  }
  return StatefulBuilder(
    builder: (BuildContext context, void Function(void Function()) setState) {
      return SwitchListTile(
        value: _downloadPersistentNotice,
        title: Text(tr("settings.download_persistent_notice.title")),
        subtitle: Text(tr("settings.download_persistent_notice.subtitle")),
        onChanged: (target) async {
          await method.saveProperty(_propertyName, "$target");
          _downloadPersistentNotice = target;
          setState(() {});
          await syncDownloadNotice();
        },
      );
    },
  );
}
