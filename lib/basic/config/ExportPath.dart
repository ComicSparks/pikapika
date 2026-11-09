/// 文件夹选择器的根路径

import 'dart:io';
import 'package:pikapika/i18.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../Cross.dart';
import '../Method.dart';
import 'Platform.dart';

const _propertyName = "exportPath";
late String _exportPath;

Future<dynamic> initExportPath() async {
  _exportPath = await method.loadProperty(_propertyName, "");
  if (_exportPath.isEmpty) {
    if (Platform.isAndroid) {
      try {
        _exportPath = await method.androidDefaultExportsDir();
      } catch (e) {
        _exportPath = "/sdcard/Download/pikapika/exports";
      }
    } else if (Platform.isMacOS || Platform.isLinux) {
      _exportPath = await method.getHomeDir();
      if (Platform.isMacOS) {
        _exportPath = _exportPath + "/Downloads";
      }
    } else if (Platform.isWindows) {
      _exportPath = "exports";
    }
  }
}

Future<String> attachExportPath() async {
  late String path;
  if (Platform.isIOS) {
    path = await method.iosGetDocumentDir();
  } else {
    if (Platform.isAndroid) {
      late bool g;
      if (androidVersion < 30) {
        g = await Permission.storage.request().isGranted;
      }else{
        g = await Permission.manageExternalStorage.request().isGranted;
      }
      if (!g) {
        throw Exception("申请权限被拒绝");
      }
    }
    path = _exportPath;
  }
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    await method.mkdirs(path);
  } else if (Platform.isAndroid) {
    await method.androidMkdirs(path);
  }
  return path;
}

String showExportPath() {
  if (Platform.isIOS) {
    return "\n\n"+tr("settings.export_path.ios_desc") ;
  }
  return "\n\n$_exportPath";
}

Future _setExportPath(String folder) async {
  await method.saveProperty(_propertyName, folder);
  _exportPath = folder;
}

Widget displayExportPathInfo() {
  return StatefulBuilder(
    builder: (BuildContext context, void Function(void Function()) setState) {
      if (Platform.isIOS) {
        return Container(
          margin: const EdgeInsets.all(15),
          padding: const EdgeInsets.all(15),
          color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black)
              .withOpacity(.01),
          child: Text(tr("settings.export_path.ios_desc2")),
        );
      }
      return Column(children: [
        MaterialButton(
          onPressed: () async {
            String? choose = await chooseFolder(context);
            if (choose != null) {
              _setExportPath(choose);
            }
            setState(() {});
          },
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Container(
                width: constraints.maxWidth,
                padding: const EdgeInsets.only(top: 15, bottom: 15),
                color: (Theme.of(context).textTheme.bodyLarge?.color ??
                        Colors.black)
                    .withOpacity(.05),
                child: Text(
                  tr("settings.export_path.export_path_desc") + ":\n"
                  "$_exportPath",
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ),
        ...Platform.isAndroid
            ? [
                Container(height: 15),
                Container(
                  margin: const EdgeInsets.all(15),
                  padding: const EdgeInsets.all(15),
                  color: (Theme.of(context).textTheme.bodyLarge?.color ??
                          Colors.black)
                      .withOpacity(.01),
                  child: Text(
                    tr("settings.export_path.android_desc"),
                  ),
                ),
              ]
            : [],
      ]);
    },
  );
}
