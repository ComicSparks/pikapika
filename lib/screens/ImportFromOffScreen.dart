import 'package:pikapika/i18.dart';
import 'package:flutter/material.dart';
import 'package:pikapika/basic/Method.dart';

import '../basic/Channels.dart';
import 'components/ContentLoading.dart';
import 'components/ListView.dart';
import 'components/RightClickPop.dart';

class ImportFromOffScreen extends StatefulWidget {
  final String dbPath;

  const ImportFromOffScreen({Key? key, required this.dbPath}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ImportFromOffScreenState();
}

class _ImportFromOffScreenState extends State<ImportFromOffScreen> {
  bool _importing = false;
  String _importMessage = "";

  @override
  void initState() {
    registerEvent(_onMessageChange, "EXPORT");
    _process();
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
        _importMessage = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return rightClickPop(
      child: buildScreen(context),
      context: context,
      canPop: !_importing,
    );
  }

  Widget buildScreen(BuildContext context) {
    if (_importing) {
      return Scaffold(
        body: ContentLoading(label: _importMessage),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('screen.import_from_off.title')),
      ),
      body: PikaListView(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            child: Text(_importMessage),
          ),
        ],
      ),
    );
  }

  _process() async {
    try {
      setState(() {
        _importing = true;
      });
      await method.importComicViewFormOff(widget.dbPath);
      setState(() {
        _importMessage = tr("screen.import_from_off.import_success");
      });
    } catch (e) {
      setState(() {
        _importMessage = "${tr('screen.import_from_off.import_failed')} $e";
      });
    } finally {
      setState(() {
        _importing = false;
      });
    }
  }
}
