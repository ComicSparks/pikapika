import 'package:pikapika/basic/Method.dart';

import 'always_enter_browser.dart';

const _propertyName = "passed";
late bool _passed;

Future<void> initPassed() async {
  _passed = (await method.loadProperty(_propertyName, "false")) == "true";
}

bool currentPassed() {
  return _passed && !currentAlwaysEnterBrowser();
}

Future<void> firstPassed() async {
  if (currentAlwaysEnterBrowser()) {
    _passed = false;
    return;
  }
  await method.saveProperty(_propertyName, "true");
  _passed = true;
}

Future<void> clearPassed() async {
  await method.saveProperty(_propertyName, "false");
  _passed = false;
}
