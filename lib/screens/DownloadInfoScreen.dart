import 'dart:convert';

import 'package:pikapika/i18.dart';
import 'package:flutter/material.dart';
import 'package:pikapika/basic/Entities.dart';
import 'package:pikapika/basic/Navigator.dart';
import 'package:pikapika/basic/Method.dart';
import '../basic/config/ContentConvert.dart';
import '../basic/config/IconLoading.dart';
import '../basic/config/ShowCommentAtDownload.dart';
import 'ComicInfoScreen.dart';
import 'DownloadExportToFileScreen.dart';
import 'DownloadReaderScreen.dart';
import 'components/ComicDescriptionCard.dart';
import 'components/ComicTagsCard.dart';
import 'components/CommentList.dart';
import 'components/CommentMainType.dart';
import 'components/ContentError.dart';
import 'components/ContentLoading.dart';
import 'components/ContinueReadButton.dart';
import 'components/DownloadInfoCard.dart';
import 'components/ListView.dart';
import 'components/Recommendation.dart';

// 下载详情
class DownloadInfoScreen extends StatefulWidget {
  final String comicId;
  final String comicTitle;

  const DownloadInfoScreen({
    required this.comicId,
    required this.comicTitle,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DownloadInfoScreenState();
}

class _DownloadInfoScreenState extends State<DownloadInfoScreen>
    with RouteAware {
  late Future<ViewLog?> _viewFuture = _loadViewLog();
  late DownloadComic _task;
  late List<DownloadEp> _epList = [];
  late Future _future = _load();

  Future _load() async {
    final task = await method.loadDownloadComic(widget.comicId);
    if (task == null) {
      throw StateError("找不到下载记录");
    }
    _task = task;
    _epList = await method.downloadEpList(widget.comicId);
  }

  Future<ViewLog?> _loadViewLog() {
    return method.loadView(widget.comicId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    setState(() {
      _viewFuture = _loadViewLog();
    });
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CcText(widget.comicTitle),
        actions: [
          IconButton(
            onPressed: () async {
              Navigator.push(
                context,
                mixRoute(
                  builder: (context) => DownloadExportToFileScreen(
                    comicId: widget.comicId,
                    comicTitle: widget.comicTitle,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add_to_home_screen),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                mixRoute(
                  builder: (context) => ComicInfoScreen(
                    comicId: widget.comicId,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.settings_ethernet_outlined),
          ),
        ],
      ),
      body: FutureBuilder(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasError) {
            return ContentError(
                error: snapshot.error,
                stackTrace: snapshot.stackTrace,
                onRefresh: () async {
                  setState(() {
                    _future = _load();
                  });
                });
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return ContentLoading(label: tr("screen.download_info.loading"));
          }
          List<dynamic> tagsDynamic = json.decode(_task.tags);
          List<String> tags = tagsDynamic.map((e) => "$e").toList();
          var list = PikaListView(
            children: [
              DownloadInfoCard(task: _task, linkItem: true),
              ComicTagsCard(tags),
              ComicDescriptionCard(description: _task.description),
              Container(height: 5),
              _bottom(),
            ],
          );
          // todo only pika task
          if (showCommentAtDownload()) {
            return DefaultTabController(
              length: 3,
              child: list,
            );
          }
          return list;
        },
      ),
    );
  }

  var _tabIndex = 0;

  Widget _bottom() {
    // todo only pika task
    if (showCommentAtDownload()) {
      final theme = Theme.of(context);
      var _tabs = <Widget>[
        Tab(text: tr("screen.download_info.chapter") + " (${_epList.length})"),
        Tab(text: tr("screen.download_info.comment")),
        Tab(text: tr("screen.download_info.recommend")),
      ];
      var _views = <Widget>[
        _chapters(),
        CommentList(CommentMainType.COMIC, widget.comicId),
        Recommendation(comicId: widget.comicId),
      ];
      return Column(children: [
        Container(
          height: 40,
          color: theme.colorScheme.secondary.withOpacity(.025),
          child: TabBar(
            tabs: _tabs,
            indicatorColor: theme.colorScheme.secondary,
            labelColor: theme.colorScheme.secondary,
            onTap: (val) async {
              setState(() {
                _tabIndex = val;
              });
            },
          ),
        ),
        Container(height: 15),
        _views[_tabIndex],
        Container(height: 5),
      ]);
    }
    return _chapters();
  }

  Widget _chapters() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.spaceAround,
      children: [
        ContinueReadButton(
          viewFuture: _viewFuture,
          onChoose: (int? epOrder, int? pictureRank) {
            if (epOrder != null && pictureRank != null) {
              for (var i in _epList) {
                if (i.epOrder == epOrder) {
                  _push(_task, _epList, epOrder, pictureRank);
                  return;
                }
              }
            } else {
              _push(_task, _epList, _epList.first.epOrder, null);
            }
          },
        ),
        ..._epList.reversed.map((e) {
          return MaterialButton(
            onPressed: () {
              _push(_task, _epList, e.epOrder, null);
            },
            color: Colors.white,
            child: CcText(e.title, style: const TextStyle(color: Colors.black)),
          );
        }),
      ],
    );
  }

  void _push(
    DownloadComic task,
    List<DownloadEp> epList,
    int epOrder,
    int? rank,
  ) {
    Navigator.push(
      context,
      mixRoute(
        builder: (context) => DownloadReaderScreen(
          comicInfo: _task,
          epList: _epList,
          currentEpOrder: epOrder,
          initPicturePosition: rank,
        ),
      ),
    );
  }
}
