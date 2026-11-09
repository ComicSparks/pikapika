import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

Future<bool> isMobileNetwork() async {
  if (!Platform.isAndroid && !Platform.isIOS) {
    return false;
  }
  final result = await Connectivity().checkConnectivity();
  return result.contains(ConnectivityResult.mobile);
}

Future<void> checkConnectivity() async {
  final isMobile = await isMobileNetwork();
  if (isMobile) {
    print('使用移动网络');
  } else {
    print('非移动网络');
  }
}
