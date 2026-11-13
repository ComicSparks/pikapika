import 'dart:async';
import 'dart:io';

import 'package:pikapika/i18.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:pikapika/basic/Common.dart';
import 'package:pikapika/basic/Entities.dart';
import 'package:pikapika/basic/config/AutoFullScreen.dart';
import 'package:pikapika/basic/config/FullScreenUI.dart';
import 'package:pikapika/basic/config/ReaderDirection.dart';
import 'package:pikapika/basic/config/ReaderType.dart';
import 'package:pikapika/basic/Metrics.dart';
import 'package:pikapika/basic/Method.dart';
import '../basic/config/IconLoading.dart';
import 'components/ContentError.dart';
import 'components/ContentLoading.dart';
import 'components/ImageReader.dart';
import 'components/RightClickPop.dart';

// 阅读下载的内容
class PkzReaderScreen extends StatefulWidget {
  final String pkzPath;
  final PkzComic comicInfo;
  late final List<PkzChapter> epList;
  final String currentEpId;
  final int? initPicturePosition;
  final bool noteReadMetric;
  final ReaderType pagerType = currentReaderType();
  final ReaderDirection pagerDirection = gReaderDirection;
  late final bool autoFullScreen;

  PkzReaderScreen({
    Key? key,
    required this.comicInfo,
    required this.currentEpId,
    this.initPicturePosition,
    this.noteReadMetric = true,
    bool? autoFullScreen,
    required this.pkzPath,
  }) : super(key: key) {
    epList = [];
    for (var volume in comicInfo.volumes) {
      for (var chapter in volume.chapters) {
        epList.add(chapter);
      }
    }
    this.autoFullScreen = autoFullScreen ?? currentAutoFullScreen();
  }

  @override
  State<StatefulWidget> createState() => _PkzReaderScreenState();
}

class _PkzReaderScreenState extends State<PkzReaderScreen> {
  late PkzChapter _ep;
  late int _epOrder;
  late bool _fullScreen = false;
  late List<PkzPicture> pictures = [];
  late Future _future = _load();
  int? _lastChangeRank;
  bool _replacement = false;

  @override
  void initState() {
    // EP
    pictures.clear();
    for (var ep in widget.epList) {
      if (ep.id == widget.currentEpId) {
        _ep = ep;
        _epOrder = widget.epList.indexOf(ep);
        pictures.addAll(ep.pictures);
        break;
      }
    }
    if (widget.noteReadMetric && widget.initPicturePosition == null) {
      Metrics.note('read');
    }
    if (widget.autoFullScreen) {
      setState(() {
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: [],
        );
        _fullScreen = true;
      });
    }
    // INIT
    _future = _load();
    super.initState();
  }

  @override
  void dispose() {
    if (!_replacement) {
      switchFullScreenUI();
    }
    super.dispose();
  }

  Future _load() async {
    if (widget.initPicturePosition == null) {
      await method.viewPkzEpAndPicture(
        p.basename(widget.pkzPath),
        widget.pkzPath,
        widget.comicInfo.id,
        widget.comicInfo.title,
        _ep.id,
        _ep.title,
        0,
      );
    }
  }

  Future _onPositionChange(int position) async {
    _lastChangeRank = position;
    await method.viewPkzEpAndPicture(
      p.basename(widget.pkzPath),
      widget.pkzPath,
      widget.comicInfo.id,
      widget.comicInfo.title,
      _ep.id,
      _ep.title,
      position,
    );
    return;
  }

  FutureOr<dynamic> _onDownload() async {
    defaultToast(context, tr("screen.pkz_reader.reading_downloaded_comic"));
  }

  FutureOr<dynamic> _onChangeEp(int epOrder) {
    final ep = widget.epList[epOrder];
    _replacement = true;
    Navigator.of(context).pushReplacement(
      mixRoute(
        builder: (context) => PkzReaderScreen(
          comicInfo: widget.comicInfo,
          pkzPath: widget.pkzPath,
          currentEpId: ep.id,
          noteReadMetric: false,
          autoFullScreen: _fullScreen,
        ),
      ),
    );
  }

  FutureOr<dynamic> _onReloadEp() {
    _replacement = true;
    Navigator.of(context).pushReplacement(
      mixRoute(
        builder: (context) => PkzReaderScreen(
          comicInfo: widget.comicInfo,
          currentEpId: widget.currentEpId,
          initPicturePosition: _lastChangeRank ?? widget.initPicturePosition,
          noteReadMetric: false,
          // maybe null
          autoFullScreen: _fullScreen,
          pkzPath: widget.pkzPath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return rightClickPop(
      child: buildScreen(context),
      context: context,
      canPop: true,
    );
  }

  Widget buildScreen(BuildContext context) {
    return readerKeyboardHolder(_build(context));
  }

  Widget _build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: _fullScreen
                ? null
                : AppBar(
                    title: Text("${_ep.title} - ${widget.comicInfo.title}"),
                  ),
            body: ContentError(
              error: snapshot.error,
              stackTrace: snapshot.stackTrace,
              onRefresh: () async {
                setState(() {
                  _future = _load();
                });
              },
            ),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: _fullScreen
                ? null
                : AppBar(
                    title: Text("${_ep.title} - ${widget.comicInfo.title}"),
                  ),
            body: ContentLoading(label: tr('app.loading')),
          );
        }
        var epNameMap = <int, String>{};
        for (var i = 0; i < widget.epList.length; i++) {
          epNameMap[i] = widget.epList[i].title;
        }
        return Scaffold(
          body: ImageReader(
            ImageReaderStruct(
              images: pictures
                  .map((e) => ReaderImageInfo(
                        "",
                        "",
                        "",
                        e.width,
                        e.height,
                        e.format,
                        0,
                        pkzFile: PkzFile(widget.pkzPath, e.picturePath),
                      ))
                  .toList(),
              fullScreen: _fullScreen,
              onFullScreenChange: _onFullScreenChange,
              onPositionChange: _onPositionChange,
              initPosition: widget.initPicturePosition,
              epOrder: _epOrder,
              epNameMap: epNameMap,
              comicTitle: widget.comicInfo.title,
              onReloadEp: _onReloadEp,
              onChangeEp: _onChangeEp,
              onDownload: _onDownload,
            ),
          ),
        );
      },
    );
  }

  Future _onFullScreenChange(bool fullScreen) async {
    setState(() {
      if (fullScreen) {
        if (Platform.isAndroid || Platform.isIOS) {
          SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual,
            overlays: [],
          );
        }
      } else {
        switchFullScreenUI();
      }
      _fullScreen = fullScreen;
    });
  }
}
