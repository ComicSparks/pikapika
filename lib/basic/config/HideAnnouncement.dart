import 'package:flutter/material.dart';
import 'package:pikapika/i18.dart';

import '../Common.dart';
import '../Method.dart';
import 'IsPro.dart';

const _propertyName = "hideAnnouncement";

late bool _hideAnnouncement;

bool get hideAnnouncement => _hideAnnouncement;

Future<void> initHideAnnouncement() async {
  _hideAnnouncement = (await method.loadProperty(_propertyName, "false")) == "true";
  if (_hideAnnouncement && !isPro) {
    _hideAnnouncement = false;
    await method.saveProperty(_propertyName, "false");
  }
}

Widget hideAnnouncementSetting() {
  return StatefulBuilder(
    builder: (BuildContext context, void Function(void Function()) setState) {
      return SwitchListTile(
        value: _hideAnnouncement,
        title: Text(
          tr("settings.hide_announcement.title") + (!isPro ? "(${tr("app.pro")})" : ""),
          style: TextStyle(
            color: !isPro ? Colors.grey : null,
          ),
        ),
        onChanged: (target) async {
          if (!isPro) {
            defaultToast(context, tr("app.pro_required"));
            return;
          }
          await method.saveProperty(_propertyName, "$target");
          _hideAnnouncement = target;
          setState(() {});
        },
      );
    },
  );
}
