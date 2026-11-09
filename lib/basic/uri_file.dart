import 'dart:io';

import 'package:flutter/services.dart';

const MethodChannel _platform = MethodChannel('pikapika/platform');

Future<File> toFile(String uriString) async {
  final uri = Uri.parse(uriString);
  if (uri.scheme == 'content') {
    final path = await _platform.invokeMethod<String>('contentUriToFile', {
      'uri': uriString,
    });
    if (path == null || path.isEmpty) {
      throw Exception('无法读取 $uriString');
    }
    return File(path);
  }
  if (uri.scheme == 'file') {
    return File.fromUri(uri);
  }
  return File(uriString);
}
