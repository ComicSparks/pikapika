/// 全屏操作

import 'package:flutter/material.dart';

import '../Common.dart';
import '../Pica.dart';

enum FullScreenAction {
  CONTROLLER,
  TOUCH_ONCE,
}

late FullScreenAction fullScreenAction;

const _propertyName = "fullScreenAction";

Future<void> initFullScreenAction() async {
  fullScreenAction = _fullScreenActionFromString(await pica.loadProperty(
    _propertyName,
    FullScreenAction.CONTROLLER.toString(),
  ));
}

FullScreenAction _fullScreenActionFromString(String string) {
  for (var value in FullScreenAction.values) {
    if (string == value.toString()) {
      return value;
    }
  }
  return FullScreenAction.CONTROLLER;
}

Map<String, FullScreenAction> fullScreenActionMap = {
  "使用控制器": FullScreenAction.CONTROLLER,
  "点击屏幕一次": FullScreenAction.TOUCH_ONCE,
};

String currentFullScreenActionName() {
  for (var e in fullScreenActionMap.entries) {
    if (e.value == fullScreenAction) {
      return e.key;
    }
  }
  return '';
}

Future<void> chooseFullScreenAction(BuildContext context) async {
  FullScreenAction? result = await chooseMapDialog<FullScreenAction>(
      context, fullScreenActionMap, "选择进入全屏的方式");
  if (result != null) {
    await pica.saveProperty(_propertyName, result.toString());
    fullScreenAction = result;
  }
}
