import 'dart:async';
import 'dart:io';

import 'package:pikapika/i18.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pikapika/basic/Entities.dart';
import 'package:pikapika/basic/Metrics.dart';
import 'package:pikapika/basic/Method.dart';
import 'package:pikapika/basic/config/ContentConvert.dart';
import 'package:pikapika/basic/config/AutoFullScreen.dart';
import 'package:pikapika/basic/config/FullScreenUI.dart';
import 'package:pikapika/basic/config/Quality.dart';
import 'package:pikapika/screens/components/ContentError.dart';
import 'package:pikapika/screens/components/ContentLoading.dart';
import '../basic/config/IconLoading.dart';
import 'DownloadConfirmScreen.dart';
import 'components/ImageReader.dart';
import 'components/RightClickPop.dart';

// 在线阅读漫画
class ComicReaderScreen extends StatefulWidget {
  final ComicInfo comicInfo;
  final List<Ep> epList;
  final int currentEpOrder;
  final int? initPicturePosition;
  final bool noteReadMetric;
  late final bool autoFullScreen;

  ComicReaderScreen({
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
  State<StatefulWidget> createState() => _ComicReaderScreenState();
}

class _ComicReaderScreenState extends State<ComicReaderScreen> {
  late Ep _ep;
  late bool _fullScreen = false;
  late Future<List<RemoteImageInfo>> _future;
  int? _lastChangeRank;
  bool _replacement = false;

  Future<List<RemoteImageInfo>> _load() async {
    if (widget.initPicturePosition == null) {
      await method.storeViewEp(widget.comicInfo.id, _ep.order, _ep.title, 0);
    }
    List<RemoteImageInfo> list = [];
    var _needLoadPage = 0;
    late PicturePage page;
    do {
      page = await method.comicPicturePageWithQuality(
        widget.comicInfo.id,
        widget.currentEpOrder,
        ++_needLoadPage,
        currentQualityCode(),
      );
      list.addAll(page.docs.map((element) => element.media));
    } while (page.pages > page.page);
    if (widget.autoFullScreen) {
      setState(() {
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: [],
        );
        _fullScreen = true;
      });
    }
    return list;
  }

  Future _onPositionChange(int position) async {
    _lastChangeRank = position;
    return method.storeViewEp(
        widget.comicInfo.id, _ep.order, _ep.title, position);
  }

  FutureOr<dynamic> _onChangeEp(int epOrder) {
    var orderMap = <int, Ep>{};
    for (var element in widget.epList) {
      orderMap[element.order] = element;
    }
    if (orderMap.containsKey(epOrder)) {
      _replacement = true;
      Navigator.of(context).pushReplacement(
        mixRoute(
          builder: (context) => ComicReaderScreen(
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
    Navigator.of(context).pushReplacement(mixRoute(
      builder: (context) => ComicReaderScreen(
        comicInfo: widget.comicInfo,
        epList: widget.epList,
        currentEpOrder: widget.currentEpOrder,
        initPicturePosition: _lastChangeRank ?? widget.initPicturePosition,
        noteReadMetric: false,
        // maybe null
        autoFullScreen: _fullScreen,
      ),
    ));
  }

  FutureOr<dynamic> _onDownload() {
    Navigator.push(
      context,
      mixRoute(
        builder: (context) => DownloadConfirmScreen(
          comicInfo: widget.comicInfo,
          epList: widget.epList.reversed.toList(),
        ),
      ),
    );
  }

  @override
  void initState() {
    // EP
    for (var element in widget.epList) {
      if (element.order == widget.currentEpOrder) {
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
      builder: (BuildContext context,
          AsyncSnapshot<List<RemoteImageInfo>> snapshot) {
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
            body: ContentLoading(label: tr('app.loading')),
          );
        }
        var epNameMap = <int, String>{};
        for (var element in widget.epList) {
          epNameMap[element.order] = element.title;
        }
        return Scaffold(
          body: ImageReader(
            ImageReaderStruct(
              images: snapshot.data!
                  .map((e) => ReaderImageInfo(
                        e.fileServer,
                        e.path,
                        null,
                        null,
                        null,
                        null,
                        null,
                      ))
                  .toList(),
              fullScreen: _fullScreen,
              onFullScreenChange: _onFullScreenChange,
              onPositionChange: _onPositionChange,
              initPosition: widget.initPicturePosition,
              epNameMap: epNameMap,
              epOrder: _ep.order,
              comicTitle: widget.comicInfo.title,
              onChangeEp: _onChangeEp,
              onReloadEp: _onReloadEp,
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
