import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:pikapika/basic/Entities.dart';
import 'package:pikapika/basic/Method.dart';
import 'package:pikapika/screens/PkzReaderScreen.dart';

import '../basic/Common.dart';
import '../basic/Navigator.dart';
import '../basic/config/ContentConvert.dart';
import '../basic/config/IconLoading.dart';
import 'components/ListView.dart';
import 'components/PkzComicInfoCard.dart';

class PkzComicInfoScreen extends StatefulWidget {
  final bool holdPkz;
  final String pkzPath;
  final PkzComic pkzComic;

  const PkzComicInfoScreen({
    Key? key,
    required this.pkzPath,
    required this.pkzComic,
    this.holdPkz = false,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PkzComicInfoScreenState();
}

class _PkzComicInfoScreenState extends State<PkzComicInfoScreen>
    with RouteAware {
  PkzComicViewLog? _log;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    if (widget.holdPkz) {
      _linkSubscription = linkSubscript(context);
    }
    _load();
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
      _log = await method.pkzComicViewLogByPkzNameAndId(
        p.basename(widget.pkzPath),
        widget.pkzComic.id,
      );
      setState(() {});
    }();
  }

  _load() async {
    await method.viewPkzComic(
      p.basename(widget.pkzPath),
      widget.pkzPath,
      widget.pkzComic.id,
      widget.pkzComic.title,
    );
    _log = await method.pkzComicViewLogByPkzNameAndId(
      p.basename(widget.pkzPath),
      widget.pkzComic.id,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> chapterButtons = [];
    for (var volume in widget.pkzComic.volumes) {
      for (var chapter in volume.chapters) {
        chapterButtons.add(MaterialButton(
          onPressed: () {
            Navigator.of(context).push(mixRoute(
              builder: (BuildContext context) {
                return PkzReaderScreen(
                  comicInfo: widget.pkzComic,
                  currentEpId: chapter.id,
                  pkzPath: widget.pkzPath,
                );
              },
            ));
          },
          color: Colors.white,
          child: CcText(
            chapter.title,
            style: const TextStyle(color: Colors.black),
          ),
        ));
      }
    }

    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: CcText(
          widget.pkzComic.title,
        ),
      ),
      body: PikaListView(children: [
        PkzComicInfoCard(info: widget.pkzComic, pkzPath: widget.pkzPath),
        Container(
          padding: const EdgeInsets.only(top: 5, bottom: 5),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor,
              ),
            ),
          ),
          child: Wrap(
            children: widget.pkzComic.tags.map((e) {
              return Container(
                padding: const EdgeInsets.only(
                  left: 10,
                  right: 10,
                  top: 3,
                  bottom: 3,
                ),
                margin: const EdgeInsets.only(
                  left: 5,
                  right: 5,
                  top: 3,
                  bottom: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.pink.shade100,
                  border: Border.all(
                    style: BorderStyle.solid,
                    color: Colors.pink.shade400,
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(30)),
                ),
                child: CcText(
                  e,
                  style: TextStyle(
                    color: Colors.pink.shade500,
                    height: 1.4,
                  ),
                  strutStyle: const StrutStyle(
                    height: 1.4,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(
            top: 5,
            bottom: 5,
            left: 10,
            right: 10,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor,
              ),
            ),
          ),
          child: SelectableText(
            widget.pkzComic.description,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            PkzChapter? first;
            Map<String, PkzChapter> chapters = {};
            for (var vol in widget.pkzComic.volumes) {
              for (var c in vol.chapters) {
                first ??= c;
                chapters[c.id] = (c);
              }
            }
            if (chapters.isEmpty) {
              return Container();
            }
            final width = constraints.maxWidth;
            return Container(
              padding: const EdgeInsets.only(left: 10, right: 10),
              margin: const EdgeInsets.only(top: 10, bottom: 10),
              width: width,
              child: MaterialButton(
                onPressed: () {
                  if (chapters.containsKey(_log?.lastViewEpId)) {
                    Navigator.of(context).push(mixRoute(
                      builder: (BuildContext context) {
                        return PkzReaderScreen(
                          comicInfo: widget.pkzComic,
                          currentEpId: _log!.lastViewEpId,
                          pkzPath: widget.pkzPath,
                          initPicturePosition: _log!.lastViewPictureRank,
                        );
                      },
                    ));
                    return;
                  }
                  Navigator.of(context).push(mixRoute(
                    builder: (BuildContext context) {
                      return PkzReaderScreen(
                        comicInfo: widget.pkzComic,
                        currentEpId: first!.id,
                        pkzPath: widget.pkzPath,
                      );
                    },
                  ));
                },
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        color: Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .color!
                            .withOpacity(.05),
                        padding: const EdgeInsets.all(10),
                        child: CcBuilder(
                          (context) => Text(
                          chapters.containsKey(_log?.lastViewEpId)
                              ? "继续阅读 ${ccConvert(chapters[_log?.lastViewEpId]!.title)}"
                              : "开始阅读",
                          textAlign: TextAlign.center,
                        ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.spaceAround,
          children: chapterButtons,
        ),
      ]),
    );
  }
}
