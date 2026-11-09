import 'dart:async';
import 'dart:io';

import 'package:pikapika/i18.dart';
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:pikapika/screens/AccessKeyReplaceScreen.dart';
import 'package:app_links/app_links.dart';
import 'uri_file.dart';

import '../screens/ComicInfoScreen.dart';
import '../screens/DownloadOnlyImportScreen.dart';
import '../screens/PkzArchiveScreen.dart';
import 'config/IconLoading.dart';
import 'config/TimeOffsetHour.dart';

/// 默认的图片尺寸
double coverWidth = 210;
double coverHeight = 315;

String categoryTitle(String? categoryTitle) {
  return categoryTitle ?? tr('categories.all');
}

/// 显示一个toast
void defaultToast(BuildContext context, String title) {
  showToast(
    title,
    context: context,
    position: StyledToastPosition.center,
    animation: StyledToastAnimation.scale,
    reverseAnimation: StyledToastAnimation.fade,
    duration: const Duration(seconds: 4),
    animDuration: const Duration(seconds: 1),
    curve: Curves.elasticOut,
    reverseCurve: Curves.linear,
  );
}

/// 显示一个确认框, 用户关闭弹窗以及选择否都会返回false, 仅当用户选择确定时返回true
Future<bool> confirmDialog(
    BuildContext context, String title, String content) async {
  return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text(title),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: <Widget>[Text(content)],
                  ),
                ),
                actions: <Widget>[
                  MaterialButton(
                    child: Text(tr('app.cancel')),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                  ),
                  MaterialButton(
                    child: Text(tr('app.confirm')),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                  ),
                ],
              )) ??
      false;
}

/// 显示一个消息提示框
Future alertDialog(BuildContext context, String title, String content) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text(content),
          ],
        ),
      ),
      actions: <Widget>[
        MaterialButton(
          child: Text(tr('app.confirm')),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    ),
  );
}

/// stream-filter的替代方法
List<T> filteredList<T>(List<T> list, bool Function(T) filter) {
  List<T> result = [];
  for (var element in list) {
    if (filter(element)) {
      result.add(element);
    }
  }
  return result;
}

/// 创建一个单选对话框, 用户取消选择返回null, 否则返回所选内容
Future<T?> chooseListDialog<T>(
    BuildContext context, String title, List<T> items,
    {String? tips}) async {
  return showDialog<T>(
    context: context,
    builder: (BuildContext context) {
      return SimpleDialog(
        title: Text(title),
        children: [
          ...items.map((e) => SimpleDialogOption(
                onPressed: () {
                  Navigator.of(context).pop(e);
                },
                child: Text('$e'),
              )),
          ...tips != null
              ? [
                  Container(
                    padding: const EdgeInsets.fromLTRB(15, 5, 15, 15),
                    child: Text(tips),
                  ),
                ]
              : [],
        ],
      );
    },
  );
}

/// 创建一个单选对话框, 用户取消选择返回null, 否则返回所选内容(value)
Future<T?> chooseMapDialog<T>(
    BuildContext buildContext, Map<String, T> values, String title) async {
  return await showDialog<T>(
    context: buildContext,
    builder: (BuildContext context) {
      return SimpleDialog(
        title: Text(title),
        children: values.entries
            .map((e) => SimpleDialogOption(
                  child: Text(e.key),
                  onPressed: () {
                    Navigator.of(context).pop(e.value);
                  },
                ))
            .toList(),
      );
    },
  );
}

/// 输入对话框1

var _controller =
    TextEditingController.fromValue(const TextEditingValue(text: ''));

Future<String?> displayTextInputDialog(BuildContext context,
    {String? title,
    String src = "",
    String? hint,
    String? desc,
    bool isPasswd = false}) {
  _controller.text = src;
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: title == null ? null : Text(title),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              TextField(
                controller: _controller,
                decoration: InputDecoration(hintText: hint),
                obscureText: isPasswd,
                obscuringCharacter: '\u2022',
              ),
              ...(desc == null
                  ? []
                  : [
                      Container(
                        padding: const EdgeInsets.only(top: 20, bottom: 10),
                        child: Text(
                          desc,
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.color
                                  ?.withOpacity(.5)),
                        ),
                      )
                    ]),
            ],
          ),
        ),
        actions: <Widget>[
          MaterialButton(
            child: Text(tr('app.cancel')),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          MaterialButton(
            child: Text(tr('app.confirm')),
            onPressed: () {
              Navigator.of(context).pop(_controller.text);
            },
          ),
        ],
      );
    },
  );
}

/// 将字符串前面加0直至满足len位
String add0(int num, int len) {
  var rsp = "$num";
  while (rsp.length < len) {
    rsp = "0$rsp";
  }
  return rsp;
}

/// 格式化时间 2012-34-56
String formatTimeToDate(String str) {
  try {
    var c = DateTime.parse(str).add(Duration(hours: currentTimeOffsetHour()));
    return "${add0(c.year, 4)}-${add0(c.month, 2)}-${add0(c.day, 2)}";
  } catch (e) {
    return "-";
  }
}

/// 格式化时间 2012-34-56 12:34:56
String formatTimeToDateTime(String str) {
  try {
    var c = DateTime.parse(str).add(Duration(hours: currentTimeOffsetHour()));
    return "${add0(c.year, 4)}-${add0(c.month, 2)}-${add0(c.day, 2)} ${add0(c.hour, 2)}:${add0(c.minute, 2)}";
  } catch (e) {
    return "-";
  }
}

/// 输入对话框2

final TextEditingController _textEditController =
    TextEditingController(text: '');

Future<String?> inputString(BuildContext context, String title,
    {String hint = "", String? defaultValue}) async {
  if (defaultValue != null) {
    _textEditController.text = defaultValue;
  } else {
    _textEditController.clear();
  }
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        content: Card(
          child: SingleChildScrollView(
            child: ListBody(
              children: [
                Text(title),
                TextField(
                  controller: _textEditController,
                  decoration: InputDecoration(
                    labelText: hint,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          MaterialButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(tr('app.cancel')),
          ),
          MaterialButton(
            onPressed: () {
              Navigator.pop(context, _textEditController.text);
            },
            child: Text(tr('app.confirm')),
          ),
        ],
      );
    },
  );
}

StreamSubscription<Uri> linkSubscript(BuildContext context) {
  return AppLinks().uriLinkStream.listen((uri) async {
    final raw = uri.toString();
    var parsed = uri;
    if (RegExp(r"^pika://access_key/([0-9A-z:\-]+)/$").allMatches(raw).isNotEmpty) {
      String accessKey = RegExp(r"^pika://access_key/([0-9A-z:\-]+)/$")
          .allMatches(raw)
          .first
          .group(1)!;
      Navigator.of(context).push(
        mixRoute(
          builder: (BuildContext context) => AccessKeyReplaceScreen(accessKey: accessKey),
        ),
      );
    } else if (RegExp(r"^pika://comic/([0-9A-z]+)/$").allMatches(raw).isNotEmpty) {
      String comicId = RegExp(r"^pika://comic/([0-9A-z]+)/$")
          .allMatches(raw)
          .first
          .group(1)!;
      Navigator.of(context).push(
        mixRoute(
          builder: (BuildContext context) => ComicInfoScreen(comicId: comicId),
        ),
      );
    } else if (RegExp(r"^https?://pika/comic/([0-9A-z]+)/$").allMatches(raw).isNotEmpty) {
      String comicId = RegExp(r"^https?://pika/comic/([0-9A-z]+)/$")
          .allMatches(raw)
          .first
          .group(1)!;
      Navigator.of(context).push(
        mixRoute(
          builder: (BuildContext context) => ComicInfoScreen(comicId: comicId),
        ),
      );
    } else if (RegExp(r"^.*\.pkz$").allMatches(parsed.path).isNotEmpty) {
      File file = await toFile(raw);
      Navigator.of(context).push(
        mixRoute(
          builder: (BuildContext context) =>
              PkzArchiveScreen(pkzPath: file.path),
        ),
      );
    } else if (RegExp(r"^.*\.((pki)|(zip))$").allMatches(parsed.path).isNotEmpty) {
      File file = await toFile(raw);
      Navigator.of(context).push(
        mixRoute(
          builder: (BuildContext context) =>
              DownloadOnlyImportScreen(path: file.path),
        ),
      );
    }
  });
}
