import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pikapika/basic/Common.dart';
import 'package:pikapika/basic/Entities.dart';
import 'package:pikapika/basic/config/ContentConvert.dart';
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
class DownloadReaderScreen extends StatefulWidget {
  final DownloadComic comicInfo;
  final List<DownloadEp> epList;
  final int currentEpOrder;
  final int? initPicturePosition;
  final bool noteReadMetric;
  final ReaderType pagerType = currentReaderType();
  final ReaderDirection pagerDirection = gReaderDirection;
  late final bool autoFullScreen;

  DownloadReaderScreen({
    Key? key,
    required this.comicInfo,
    required this.epList,
    required this.currentEpOrder,
    this.initPicturePosition,
    this.noteReadMetric = true,
    bool? autoFullScreen,
  }) : super(key: key) {
    this.autoFullScreen = autoFullScreen ?? currentAutoFullScreen();
  }

  @override
  State<StatefulWidget> createState() => _DownloadReaderScreenState();
}

class _DownloadReaderScreenState extends State<DownloadReaderScreen> {
  late DownloadEp _ep;
  late bool _fullScreen = false;
  late List<DownloadPicture> pictures = [];
  late Future _future = _load();
  int? _lastChangeRank;
  bool _replacement = false;

  Future _load() async {
    if (widget.initPicturePosition == null) {
      await method.storeViewEp(widget.comicInfo.id, _ep.epOrder, _ep.title, 0);
    }
    pictures.clear();
    for (var ep in widget.epList) {
      if (ep.epOrder == widget.currentEpOrder) {
        pictures.addAll((await method.downloadPicturesByEpId(ep.id)));
      }
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
  }

  Future _onPositionChange(int position) async {
    _lastChangeRank = position;
    return method.storeViewEp(
        widget.comicInfo.id, _ep.epOrder, _ep.title, position);
  }

  FutureOr<dynamic> _onDownload() async {
    defaultToast(context, "您阅读的是下载漫画");
  }

  FutureOr<dynamic> _onChangeEp(int epOrder) {
    var orderMap = <int, DownloadEp>{};
    for (var element in widget.epList) {
      orderMap[element.epOrder] = element;
    }
    if (orderMap.containsKey(epOrder)) {
      _replacement = true;
      Navigator.of(context).pushReplacement(
        mixRoute(
          builder: (context) => DownloadReaderScreen(
            comicInfo: widget.comicInfo,
            epList: widget.epList,
            currentEpOrder: epOrder,
            noteReadMetric: false,
            autoFullScreen: _fullScreen,
          ),
        ),
      );
    }
  }

  FutureOr<dynamic> _onReloadEp() {
    _replacement = true;
    Navigator.of(context).pushReplacement(
      mixRoute(
        builder: (context) => DownloadReaderScreen(
          comicInfo: widget.comicInfo,
          epList: widget.epList,
          currentEpOrder: widget.currentEpOrder,
          initPicturePosition: _lastChangeRank ?? widget.initPicturePosition,
          noteReadMetric: false,
          // maybe null
          autoFullScreen: _fullScreen,
        ),
      ),
    );
  }

  @override
  void initState() {
    // EP
    for (var element in widget.epList) {
      if (element.epOrder == widget.currentEpOrder) {
        _ep = element;
      }
    }
    if (widget.noteReadMetric && widget.initPicturePosition == null) {
      Metrics.note('read');
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

  @override
  Widget build(BuildContext context){
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
                    title: CcText("${_ep.title} - ${widget.comicInfo.title}"),
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
                    title: CcText("${_ep.title} - ${widget.comicInfo.title}"),
                  ),
            body: const ContentLoading(label: '加载中'),
          );
        }
        var epNameMap = <int, String>{};
        for (var element in widget.epList) {
          epNameMap[element.epOrder] = element.title;
        }
        return Scaffold(
          body: ImageReader(
            ImageReaderStruct(
              images: pictures
                  .map((e) => ReaderImageInfo(e.fileServer, e.path, e.localPath,
                      e.width, e.height, e.format, e.fileSize))
                  .toList(),
              fullScreen: _fullScreen,
              onFullScreenChange: _onFullScreenChange,
              onPositionChange: _onPositionChange,
              initPosition: widget.initPicturePosition,
              epOrder: _ep.epOrder,
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
