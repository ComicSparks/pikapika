import 'dart:async';

import 'package:pikapika/i18.dart';
import 'package:flutter/material.dart';
import 'package:pikapika/basic/Channels.dart';
import 'package:pikapika/basic/Method.dart';
import 'package:pikapika/screens/components/FitButton.dart';
import 'components/ContentLoading.dart';
import 'components/RightClickPop.dart';

// 清理
class CleanScreen extends StatefulWidget {
  const CleanScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CleanScreenState();
}

class _CleanScreenState extends State<CleanScreen> {
  late bool _cleaning = false;
  late String _cleaningMessage = tr('screen.clean.cleaning');
  late String _cleanResult = "";

  @override
  void initState() {
    registerEvent(_onMessageChange, "EXPORT");
    super.initState();
  }

  @override
  void dispose() {
    unregisterEvent(_onMessageChange);
    super.dispose();
  }

  void _onMessageChange(AppEvent event) {
    if (event case AppEvent_Export(:final message)) {
      setState(() {
        _cleaningMessage = message;
      });
    }
  }

  @override
  Widget build(BuildContext context){
    return rightClickPop(
      child: buildScreen(context),
      context: context,
      canPop: true,
    );
  }

  Widget buildScreen(BuildContext context) {
    if (_cleaning) {
      return Scaffold(
        body: ContentLoading(label: _cleaningMessage),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('screen.clean.title')),
      ),
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            child: _cleanResult != "" ? Text(_cleanResult) : Container(),
          ),
          SizedBox(
            height: 50,
            child: FitButton(
              text: tr('screen.clean.clean_network_cache'),
              onPressed: () {
                processCleanAction(method.cleanNetworkCache);
              },
            ),
          ),
          SizedBox(
            height: 50,
            child: FitButton(
              text: tr('screen.clean.clean_image_cache'),
              onPressed: () {
                processCleanAction(method.cleanImageCache);
              },
            ),
          ),
          SizedBox(
            height: 50,
            child: FitButton(
              text: tr('screen.clean.clean_all_cache'),
              onPressed: () {
                processCleanAction(method.clean);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future processCleanAction(Future Function() action) async {
    try {
      setState(() {
        _cleaning = true;
      });
      await action();
      setState(() {
        _cleanResult = tr('screen.clean.clean_success');
      });
    } catch (e) {
      setState(() {
        _cleanResult = tr('screen.clean.clean_failed') + " $e";
      });
    } finally {
      setState(() {
        _cleaning = false;
      });
    }
  }
}
