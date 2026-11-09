import 'package:flutter/material.dart';
import 'package:pikapika/basic/Common.dart';
import 'package:pikapika/basic/Method.dart';
import 'package:pikapika/i18.dart';

import 'passed.dart';

const _propertyName = "alwaysEnterBrowser";
late bool _alwaysEnterBrowser;

Future<void> initAlwaysEnterBrowser() async {
  _alwaysEnterBrowser =
      (await method.loadProperty(_propertyName, "false")) == "true";
}

bool currentAlwaysEnterBrowser() {
  return _alwaysEnterBrowser;
}

Widget alwaysEnterBrowserSetting() {
  return StatefulBuilder(
    builder: (BuildContext context, void Function(void Function()) setState) {
      return SwitchListTile(
        title: Text(tr("settings.always_enter_browser")),
        subtitle: Text(
          _alwaysEnterBrowser
              ? tr("settings.always_enter_browser_on")
              : tr("settings.always_enter_browser_off"),
        ),
        value: _alwaysEnterBrowser,
        onChanged: (value) async {
          await method.saveProperty(_propertyName, "$value");
          _alwaysEnterBrowser = value;
          if (value) {
            await clearPassed();
          }
          setState(() {});
        },
      );
    },
  );
}

Widget resetBrowserTile(BuildContext context) {
  return ListTile(
    title: Text(tr("settings.reset_browser")),
    onTap: () async {
      final confirmed = await confirmDialog(
        context,
        tr("settings.reset_browser"),
        tr("settings.reset_browser_confirm"),
      );
      if (!confirmed) {
        return;
      }
      try {
        await clearPassed();
        if (context.mounted) {
          defaultToast(context, tr("settings.reset_browser_success"));
        }
      } catch (e) {
        if (context.mounted) {
          defaultToast(context, "${tr("settings.reset_browser_failed")} : $e");
        }
      }
    },
  );
}
