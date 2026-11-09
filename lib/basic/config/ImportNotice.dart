import 'dart:io';

import 'package:pikapika/i18.dart';
import 'package:flutter/material.dart';

Widget importNotice(BuildContext context) {
  if (Platform.isAndroid) {
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(15),
      color: (Theme
          .of(context)
          .textTheme
          .bodyLarge
          ?.color ?? Colors.black)
          .withOpacity(.01),
      child: Text(
        tr("settings.import_notice.android_desc"),
      ),
    );
  }
  return Container();
}
