import 'dart:math';

import 'package:pikapika/i18.dart';
import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:pikapika/basic/Common.dart';
import 'package:pikapika/basic/Entities.dart';
import 'package:pikapika/basic/Method.dart';
import 'package:pikapika/basic/config/HiddenWords.dart';
import 'package:pikapika/basic/config/ShadowCategories.dart';
import 'package:pikapika/basic/config/ListLayout.dart';
import 'package:pikapika/basic/config/ShadowCategoriesMode.dart';
import 'package:pikapika/screens/components/CommonData.dart';

import '../../basic/config/HiddenViewed.dart';
import 'ComicInfoCard.dart';
import 'Images.dart';
import 'LinkToComicInfo.dart';
import 'ListView.dart';

class ComicListController {
  _ComicListState? _state;

  bool get selecting => _state?._selecting ?? false;

  set selecting(bool value) => _state?._setSelect(value);

  List<String> get selected => _state?._selected ?? [];

  selectAll() {
    _state?._selectAll();
  }

  loadViewed() {
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _state?._loadViewed();
    });
  }
}

// 漫画列表页
class ComicList extends StatefulWidget {
  final Widget? appendWidget;
  final List<ComicSimple> comicList;
  final ScrollController? scrollController;
  final ComicListController? listController;

  const ComicList(
    this.comicList, {
    this.appendWidget,
    this.scrollController,
    Key? key,
    // required
    this.listController,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ComicListState();
}

class _ComicListState extends State<ComicList> {
  final List<String> viewedList = [];
  bool _selecting = false;
  List<String> _selected = [];

  _selectAll() {
    setState(() {
      if (_selected.length == widget.comicList.length) {
        _selected.clear();
      } else {
        _selected.addAll(widget.comicList.map((e) => e.id));
      }
    });
  }

  _setSelect(bool value) {
    setState(() {
      _selected.clear();
      _selecting = value;
    });
  }

  Future _loadViewed() async {
    if (widget.comicList.isNotEmpty) {
      var list = await method
          .loadViewedList(widget.comicList.map((e) => e.id).toList());
      viewedList.clear();
      viewedList.addAll(list);
      setState(() {});
    }
  }

  @override
  void initState() {
    widget.listController?._state = this;
    _loadViewed();
    listLayoutEvent.subscribe(_onLayoutChange);
    super.initState();
  }

  @override
  void dispose() {
    if (widget.listController?._state == this) {
      widget.listController?._state = null;
    }
    listLayoutEvent.unsubscribe(_onLayoutChange);
    super.dispose();
  }

  void _onLayoutChange(EventArgs? args) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    switch (currentLayout) {
      case ListLayout.INFO_CARD:
        return _buildInfoCardList();
      case ListLayout.ONLY_IMAGE:
        return _buildGridImageWarp();
      case ListLayout.COVER_AND_TITLE:
        return _buildGridImageTitleWarp();
      default:
        return Container();
    }
  }

  Widget _buildInfoCardList() {
    return PikaListView(
      controller: widget.scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        ...widget.comicList.map((e) {
          bool viewed = viewedList.contains(e.id);
          if (hiddenViewed && viewed) {
            return InkWell(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    tr('components.comic_info_card.viewed'),
                    style: TextStyle(
                      fontSize: 12,
                      color: (Theme.of(context).textTheme.bodyLarge?.color ??
                              Colors.black)
                          .withOpacity(.3),
                    ),
                  ),
                ),
              ),
            );
          }
          late bool shadow;
          X:
          switch (currentShadowCategoriesMode()) {
            case ShadowCategoriesMode.BLACK_LIST:
              shadow = e.categories
                  .map((c) => shadowCategories.contains(c))
                  .reduce((value, element) => value || element);
              break;
            case ShadowCategoriesMode.WHITE_LIST:
              for (var c in e.categories) {
                if (shadowCategories.contains(c)) {
                  shadow = false;
                  break X;
                }
              }
              shadow = true;
              break;
          }
          if (!shadow) {
            for (var value in hiddenWords) {
              if (e.title.toLowerCase().contains(value.toLowerCase()) ||
                  e.author.toLowerCase().contains(value.toLowerCase())) {
                shadow = true;
                break;
              }
            }
          }
          if (shadow) {
            return InkWell(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    tr('components.comic_list.shadow'),
                    style: TextStyle(
                      fontSize: 12,
                      color: (Theme.of(context).textTheme.bodyLarge?.color ??
                              Colors.black)
                          .withOpacity(.3),
                    ),
                  ),
                ),
              ),
            );
          }
          if (_selecting) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (_selected.contains(e.id)) {
                    _selected.remove(e.id);
                  } else {
                    _selected.add(e.id);
                  }
                });
              },
              child: Stack(children: [
                AbsorbPointer(
                  child: ComicInfoCard(
                    e,
                    viewed: viewedList.contains(e.id),
                  ),
                ),
                SizedBox(
                  height: imageHeight,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      margin: const EdgeInsets.only(top: 5),
                      padding: const EdgeInsets.only(right: 10, left: 5),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade500.withOpacity(.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(5),
                          bottomLeft: Radius.circular(5),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Icon(
                          _selected.contains(e.id)
                              ? Icons.check_circle_sharp
                              : Icons.circle_outlined,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            );
          }
          Widget card = ComicInfoCard(
            e,
            viewed: viewedList.contains(e.id),
          );
          if (allSubscribed.containsKey(e.id)) {
            final subscribed = allSubscribed[e.id]!;
            if (subscribed.newEpCount > 0) {
              card = Stack(
                children: [
                  card,
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(5),
                        ),
                      ),
                      child: Text(
                        subscribed.newEpCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
          }
          return LinkToComicInfo(comicId: e.id, child: card);
        }).toList(),
        ...widget.appendWidget != null
            ? [
                SizedBox(
                  height: 80,
                  child: widget.appendWidget,
                ),
              ]
            : [],
      ],
    );
  }

  Widget _buildGridImageWarp() {
    var gap = 3.0;
    var size = MediaQuery.of(context).size;
    var min = size.width < size.height ? size.width : size.height;
    var widthAndGap = min / 4;
    int rowCap = size.width ~/ widthAndGap;
    var width = widthAndGap - gap * 2;
    var height = width * coverHeight / coverWidth;
    List<Widget> wraps = [];
    List<Widget> tmp = [];
    for (var e in widget.comicList) {
      late bool shadow;
      X:
      switch (currentShadowCategoriesMode()) {
        case ShadowCategoriesMode.BLACK_LIST:
          shadow = e.categories
              .map((c) => shadowCategories.contains(c))
              .reduce((value, element) => value || element);
          break;
        case ShadowCategoriesMode.WHITE_LIST:
          for (var c in e.categories) {
            if (shadowCategories.contains(c)) {
              shadow = false;
              break X;
            }
          }
          shadow = true;
          break;
      }
      if (!shadow) {
        for (var value in hiddenWords) {
          if (e.title.toLowerCase().contains(value.toLowerCase()) ||
              e.author.toLowerCase().contains(value.toLowerCase())) {
            shadow = true;
            break;
          }
        }
      }

      bool viewed = viewedList.contains(e.id);
      if (hiddenViewed && viewed) {
        tmp.add(
          Container(
            padding: EdgeInsets.all(gap),
            child: Container(
              width: width,
              height: height,
              color:
                  (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black)
                      .withOpacity(.05),
              child: Center(
                child: Text(
                  tr('components.comic_info_card.viewed'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: (Theme.of(context).textTheme.bodyLarge?.color ??
                            Colors.black)
                        .withOpacity(.5),
                  ),
                ),
              ),
            ),
          ),
        );
      } else if (shadow) {
        tmp.add(
          Container(
            padding: EdgeInsets.all(gap),
            child: Container(
              width: width,
              height: height,
              color:
                  (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black)
                      .withOpacity(.05),
              child: Center(
                child: Text(
                  tr('components.comic_list.shadow'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: (Theme.of(context).textTheme.bodyLarge?.color ??
                            Colors.black)
                        .withOpacity(.5),
                  ),
                ),
              ),
            ),
          ),
        );
      } else if (_selecting) {
        Widget c = Container(
          padding: EdgeInsets.all(gap),
          child: RemoteImage(
            fileServer: e.thumb.fileServer,
            path: e.thumb.path,
            width: width,
            height: height,
          ),
        );
        c = GestureDetector(
          onTap: () {
            setState(() {
              if (_selected.contains(e.id)) {
                _selected.remove(e.id);
              } else {
                _selected.add(e.id);
              }
            });
          },
          child: Stack(children: [
            AbsorbPointer(
              child: c,
            ),
            SizedBox(
              width: width,
              height: height,
              child: Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800.withOpacity(.75),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(5),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(
                      _selected.contains(e.id)
                          ? Icons.check_circle_sharp
                          : Icons.circle_outlined,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ),
            ),
          ]),
        );
        tmp.add(c);
      } else {
        Widget c = LinkToComicInfo(
          comicId: e.id,
          child: Container(
            padding: EdgeInsets.all(gap),
            child: RemoteImage(
              fileServer: e.thumb.fileServer,
              path: e.thumb.path,
              width: width,
              height: height,
            ),
          ),
        );
        if (allSubscribed.containsKey(e.id)) {
          final subscribed = allSubscribed[e.id]!;
          if (subscribed.newEpCount > 0) {
            c = Stack(
              children: [
                c,
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(5),
                      ),
                    ),
                    child: Text(
                      subscribed.newEpCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        }
        tmp.add(c);
      }
      if (tmp.length == rowCap) {
        wraps.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: tmp,
        ));
        tmp = [];
      }
    }
    // 追加特殊按钮
    if (widget.appendWidget != null) {
      tmp.add(Container(
        color:
            (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.transparent)
                .withOpacity(.1),
        margin: EdgeInsets.only(
          left: (rowCap - tmp.length) * gap,
          right: (rowCap - tmp.length) * gap,
          top: gap,
          bottom: gap,
        ),
        width: (rowCap - tmp.length) * width,
        height: height,
        child: widget.appendWidget,
      ));
    }
    // 最后一页没有下一页所有有可能为空
    if (tmp.isNotEmpty) {
      wraps.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: tmp,
      ));
      tmp = [];
    }
    // 返回
    return PikaListView(
      controller: widget.scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(top: gap, bottom: gap),
      children: wraps,
    );
  }

  Widget _buildGridImageTitleWarp() {
    var gap = 3.0;
    var size = MediaQuery.of(context).size;
    var min = size.width < size.height ? size.width : size.height;
    var widthAndGap = min / 3;
    int rowCap = size.width ~/ widthAndGap;
    var width = widthAndGap - gap * 2;
    var height = width * coverHeight / coverWidth;
    double titleFontSize = max(width / 11, 10);
    double shadowFontSize = max(width / 9, 12);
    List<Widget> wraps = [];
    List<Widget> tmp = [];
    for (var e in widget.comicList) {
      late bool shadow;
      X:
      switch (currentShadowCategoriesMode()) {
        case ShadowCategoriesMode.BLACK_LIST:
          shadow = e.categories
              .map((c) => shadowCategories.contains(c))
              .reduce((value, element) => value || element);
          break;
        case ShadowCategoriesMode.WHITE_LIST:
          for (var c in e.categories) {
            if (shadowCategories.contains(c)) {
              shadow = false;
              break X;
            }
          }
          shadow = true;
          break;
      }
      if (!shadow) {
        for (var value in hiddenWords) {
          if (e.title.toLowerCase().contains(value.toLowerCase()) ||
              e.author.toLowerCase().contains(value.toLowerCase())) {
            shadow = true;
            break;
          }
        }
      }
      bool viewed = viewedList.contains(e.id);
      if (hiddenViewed && viewed) {
        tmp.add(
          Container(
            padding: EdgeInsets.all(gap),
            child: Container(
              width: width,
              height: height,
              color:
                  (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black)
                      .withOpacity(.05),
              child: Center(
                child: Text(
                  tr('components.comic_info_card.viewed'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: shadowFontSize,
                    color: (Theme.of(context).textTheme.bodyLarge?.color ??
                            Colors.black)
                        .withOpacity(.5),
                  ),
                ),
              ),
            ),
          ),
        );
      } else if (shadow) {
        tmp.add(
          Container(
            padding: EdgeInsets.all(gap),
            child: Container(
              width: width,
              height: height,
              color:
                  (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black)
                      .withOpacity(.05),
              child: Center(
                child: Text(
                  tr('components.comic_list.shadow'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: shadowFontSize,
                    color: (Theme.of(context).textTheme.bodyLarge?.color ??
                            Colors.black)
                        .withOpacity(.5),
                  ),
                ),
              ),
            ),
          ),
        );
      } else if (_selecting) {
        Widget c = Container(
          margin: EdgeInsets.all(gap),
          width: width,
          height: height,
          child: Stack(
            children: [
              RemoteImage(
                fileServer: e.thumb.fileServer,
                path: e.thumb.path,
                width: width,
                height: height,
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  color: Colors.black.withOpacity(.3),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.title + '\n',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: titleFontSize,
                            height: 1.2,
                          ),
                          strutStyle: const StrutStyle(height: 1.2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
        c = GestureDetector(
          onTap: () {
            setState(() {
              if (_selected.contains(e.id)) {
                _selected.remove(e.id);
              } else {
                _selected.add(e.id);
              }
            });
          },
          child: Stack(children: [
            AbsorbPointer(
              child: c,
            ),
            SizedBox(
              width: width,
              height: height,
              child: Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800.withOpacity(.75),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(5),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(
                      _selected.contains(e.id)
                          ? Icons.check_circle_sharp
                          : Icons.circle_outlined,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ),
            ),
          ]),
        );
        tmp.add(c);
      } else {
        Widget c = LinkToComicInfo(
          comicId: e.id,
          child: Container(
            margin: EdgeInsets.all(gap),
            width: width,
            height: height,
            child: Stack(
              children: [
                RemoteImage(
                  fileServer: e.thumb.fileServer,
                  path: e.thumb.path,
                  width: width,
                  height: height,
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    color: Colors.black.withOpacity(.3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            e.title + '\n',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: titleFontSize,
                              height: 1.2,
                            ),
                            strutStyle: const StrutStyle(height: 1.2),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        if (allSubscribed.containsKey(e.id)) {
          final subscribed = allSubscribed[e.id]!;
          if (subscribed.newEpCount > 0) {
            c = Stack(
              children: [
                c,
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(5),
                      ),
                    ),
                    child: Text(
                      subscribed.newEpCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        }
        tmp.add(c);
      }
      if (tmp.length == rowCap) {
        wraps.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: tmp,
        ));
        tmp = [];
      }
    }
    // 追加特殊按钮
    if (widget.appendWidget != null) {
      tmp.add(Container(
        color:
            (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.transparent)
                .withOpacity(.1),
        margin: EdgeInsets.only(
          left: (rowCap - tmp.length) * gap,
          right: (rowCap - tmp.length) * gap,
          top: gap,
          bottom: gap,
        ),
        width: (rowCap - tmp.length) * width,
        height: height,
        child: widget.appendWidget,
      ));
    }
    // 最后一页没有下一页所有有可能为空
    if (tmp.isNotEmpty) {
      wraps.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: tmp,
      ));
      tmp = [];
    }
    // 返回
    return PikaListView(
      controller: widget.scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(top: gap, bottom: gap),
      children: wraps,
    );
  }
}
