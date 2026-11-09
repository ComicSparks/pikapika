import 'dart:async';

import 'package:pikapika/src/rust/api/simple.dart';
import 'package:pikapika/src/rust/events.dart';

export 'package:pikapika/src/rust/events.dart';

Map<void Function(AppEvent event), String> _eventMap = {};
StreamSubscription<AppEvent>? _eventListen;

void registerEvent(void Function(AppEvent event) eventHandler, String eventName) {
  if (_eventMap.containsKey(eventHandler)) {
    throw 'once register';
  }
  _eventMap[eventHandler] = eventName;
  if (_eventMap.length == 1) {
    _eventListen = events().listen(_onEvent);
  }
}

void unregisterEvent(void Function(AppEvent event) eventHandler) {
  if (!_eventMap.containsKey(eventHandler)) {
    throw 'no register';
  }
  _eventMap.remove(eventHandler);
  if (_eventMap.isEmpty) {
    _eventListen?.cancel();
    _eventListen = null;
  }
}

void _onEvent(AppEvent event) {
  final name = switch (event) {
    AppEvent_Download() => 'DOWNLOAD',
    AppEvent_Export() => 'EXPORT',
  };
  _eventMap.forEach((key, value) {
    if (value == name) {
      key(event);
    }
  });
}
