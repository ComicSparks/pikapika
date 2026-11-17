import 'dart:io';

import 'package:flutter/material.dart';

import '../../basic/Metrics.dart';
import '../../basic/config/Authentication.dart';
import '../../basic/config/TimeoutLock.dart';

class TimeoutLock extends StatefulWidget {
  final Widget child;

  const TimeoutLock({required this.child, Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TimeoutLockState();
}

class _TimeoutLockState extends State<TimeoutLock> with WidgetsBindingObserver {
  DateTime? _appLostFocusTimestamp;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      Metrics.flush();
    }
    if (!currentAuthentication() || timeoutLock == 0) return;
    print("_locked: $_locked");
    if (_locked) {
      return;
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_appLostFocusTimestamp != null) {
        return;
      }
      _appLostFocusTimestamp = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_appLostFocusTimestamp == null) {
        return;
      }
      final currentTimeStamp = DateTime.now();
      final difference = currentTimeStamp.difference(_appLostFocusTimestamp!);
      _appLostFocusTimestamp = null;
      if (difference.inSeconds > timeoutLock) {
        _locked = true;
        Navigator.of(context)
            .push(MaterialPageRoute(
          builder: (context) => const TimeoutScreen(),
        ))
            .then((value) {
          _locked = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class TimeoutScreen extends StatelessWidget {
  const TimeoutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MaterialButton(
                onPressed: () async {
                  if (true == await verifyAuthentication(context)) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('您离开APP很久了，请验点击证身份'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
