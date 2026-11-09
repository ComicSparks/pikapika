import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:pikapika/basic/Entities.dart';
import 'package:pikapika/basic/Method.dart';
import 'package:pikapika/screens/components/ContentBuilder.dart';
import 'package:pikapika/screens/components/PkzComicInfoCard.dart';
import '../basic/Common.dart';
import '../basic/Navigator.dart';
import '../basic/config/IconLoading.dart';
import '../basic/config/Platform.dart';
import 'PkzComicInfoScreen.dart';
import 'components/ListView.dart';

class PkzArchiveScreen extends StatefulWidget {
  final bool holdPkz;
  final String pkzPath;

  const PkzArchiveScreen({
    Key? key,
    required this.pkzPath,
    this.holdPkz = false,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PkzArchiveScreenState();
}

class _PkzArchiveScreenState extends State<PkzArchiveScreen> with RouteAware {
  Map<String, PkzComicViewLog> _logMap = {};
  late String _fileName;
  late Future _future;
  late Key _key;
  late PkzArchive _info;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    if (widget.holdPkz) {
      _linkSubscription = linkSubscript(context);
    }
    _fileName = p.basename(widget.pkzPath);
    _future = _load();
    _key = UniqueKey();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    () async {
      var a = await method.pkzComicViewLogs(_fileName, widget.pkzPath);
      for (var value in a) {
        _logMap[value.lastViewComicId] = value;
      }
      setState(() {});
    }();
  }

  Future _load() async {
    await method.viewPkz(_fileName, widget.pkzPath);
    if (Platform.isAndroid) {
      late bool g;
      if (androidVersion < 30) {
        g = await Permission.storage.request().isGranted;
      }else{
        g = await Permission.manageExternalStorage.request().isGranted;
      }
      if (!g) {
        throw 'error permission';
      }
    }
    _info = await method.pkzInfo(widget.pkzPath);
    if (_info.comics.length == 1) {
      Navigator.of(context).pushReplacement(mixRoute(
        builder: (BuildContext context) => PkzComicInfoScreen(
          pkzPath: widget.pkzPath,
          pkzComic: _info.comics.first,
          holdPkz: widget.holdPkz,
        ),
      ));
    }
    var a = await method.pkzComicViewLogs(_fileName, widget.pkzPath);
    for (var value in a) {
      _logMap[value.lastViewComicId] = value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_fileName),
      ),
      body: ContentBuilder(
        key: _key,
        future: _future,
        onRefresh: () async {
          setState(() {
            _future = _load();
            _key = UniqueKey();
          });
        },
        successBuilder: (
          BuildContext context,
          AsyncSnapshot snapshot,
        ) {
          return PikaListView(children: [
            ..._info.comics
                .map((e) => GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        Navigator.of(context).push(mixRoute(
                          builder: (BuildContext context) {
                            return PkzComicInfoScreen(
                              pkzComic: e,
                              pkzPath: widget.pkzPath,
                            );
                          },
                        ));
                      },
                      child: PkzComicInfoCard(
                        info: e,
                        pkzPath: widget.pkzPath,
                        displayViewLog: _logMap[e.id],
                      ),
                    ))
                .toList(),
          ]);
        },
      ),
    );
  }
}
