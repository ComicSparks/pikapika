import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pikapika/i18.dart';
import 'package:pikapika/basic/Common.dart';
import 'package:pikapika/basic/Method.dart';
import 'package:pikapika/screens/components/ComicInfoCard.dart';
import 'package:pikapika/screens/components/RightClickPop.dart';

import '../basic/Entities.dart';
import '../basic/config/IconLoading.dart';
import 'ComicInfoScreen.dart';
import 'components/Images.dart';
import 'components/ListView.dart';

// 浏览记录
class ViewLogsScreen extends StatefulWidget {
  const ViewLogsScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ViewLogsScreenState();
}

class _ViewLogsScreenState extends State<ViewLogsScreen> {
  static const _pageSize = 24;
  static const _scrollPhysics = AlwaysScrollableScrollPhysics(); // 即使不足一页仍可滚动

  final _scrollController = ScrollController();
  final _comicList = <ViewLog>[];

  var _isLoading = false; // 是否加载中
  var _scrollOvered = false; // 滚动到最后
  var _offset = 0;

  var _inSelection = false; // 是否进入选择模式
  var _selectedList = <String>[]; // 选择列表

  Future _clearAll() async {
    if (await confirmDialog(
      context,
      tr('screen.view_logs.clear_all'),
      tr('screen.view_logs.clear_all_desc'),
    )) {
      await method.clearAllViewLog();
      setState(() {
        _comicList.clear();
        _isLoading = false;
        _scrollOvered = true;
        _offset = 0;
      });
    }
  }

  Future _deleteSelected() async {
    if (_selectedList.isNotEmpty) {
      var confirm = await confirmDialog(
        context,
        tr('screen.view_logs.clear_selected'),
        tr('screen.view_logs.clear_selected_desc'),
      );
      if (!confirm) {
        return;
      }
    }
    if (_selectedList.isNotEmpty) {
      await method.deleteViewLog(_selectedList.join(','));
    }
    setState(() {
      _inSelection = false;
      _selectedList.clear();
      _comicList.clear();
      _isLoading = false;
      _scrollOvered = true;
      _offset = 0;
    });
    _loadPage();
  }

  Future _viewSelected() async {
    if (_selectedList.isNotEmpty) {
      await method.viewComic(_selectedList.join(','));
    }
    setState(() {
      _inSelection = false;
      _selectedList.clear();
      _comicList.clear();
      _isLoading = false;
      _scrollOvered = true;
      _offset = 0;
    });
    _loadPage();
  }

  Future<void> _reloadList() async {
    setState(() {
      _comicList.clear();
      _offset = 0;
      _scrollOvered = false;
    });
    await _loadPage();
  }

  Future<void> _onItemLongPress(ViewLog item) async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(item.title),
          children: [
            if (item.pinnedAt > 0)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, 'unpin'),
                child: ListTile(
                  leading: const Icon(Icons.push_pin_outlined),
                  title: Text(tr('screen.view_logs.unpin')),
                ),
              )
            else
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, 'pin'),
                child: ListTile(
                  leading: const Icon(Icons.push_pin),
                  title: Text(tr('screen.view_logs.pin')),
                ),
              ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'delete'),
              child: ListTile(
                leading: const Icon(Icons.delete),
                title: Text(tr('screen.view_logs.delete')),
              ),
            ),
          ],
        );
      },
    );
    if (action == 'pin') {
      await method.setViewLogPinned(item.id, true);
      await _reloadList();
    } else if (action == 'unpin') {
      await method.setViewLogPinned(item.id, false);
      await _reloadList();
    } else if (action == 'delete') {
      if (await confirmDialog(
        context,
        tr('screen.view_logs.clear_one'),
        tr('screen.view_logs.clear_one_desc'),
      )) {
        await method.deleteViewLog(item.id);
        await _reloadList();
      }
    }
  }

  // 加载一页
  Future<dynamic> _loadPage() async {
    setState(() {
      _isLoading = true;
    });
    try {
      var page = await method.viewLogPage(_offset, _pageSize);
      if (page.isEmpty) {
        _scrollOvered = true;
      } else {
        _comicList.addAll(page);
      }
      _offset += _pageSize;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 滚动事件
  void _handScroll() {
    if (_scrollController.position.pixels +
            MediaQuery.of(context).size.height / 2 <
        _scrollController.position.maxScrollExtent) {
      return;
    }
    if (_isLoading || _scrollOvered || _inSelection) return;
    _loadPage();
  }

  @override
  void initState() {
    _loadPage();
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var entries = _comicList.map((e) {
      Widget card = InkWell(
        onTap: () {
          if (_inSelection) {
            if (_selectedList.contains(e.id)) {
              _selectedList.remove(e.id);
            } else {
              _selectedList.add(e.id);
            }
          } else {
            _chooseComic(e.id);
          }
          setState(() {});
        },
        onLongPress: () {
          if (_inSelection) {
            if (_selectedList.contains(e.id)) {
              _selectedList.remove(e.id);
            } else {
              _selectedList.add(e.id);
            }
          } else {
            _onItemLongPress(e);
          }
          setState(() {});
        },
        child: ViewInfoCard(
          fileServer: e.thumbFileServer,
          author: e.author,
          categories: _decodeCate(e.categories),
          path: e.thumbPath,
          title: e.title,
          pinned: e.pinnedAt > 0,
        ),
      );
      if (_inSelection) {
        card = Stack(
          children: [
            card,
            Positioned(
              top: 10,
              right: 10,
              child: Icon(
                _selectedList.contains(e.id)
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
                color: _selectedList.contains(e.id)
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
          ],
        );
      }
      return card;
    });

    final screen = NotificationListener(
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('screen.view_logs.title')),
          actions: [
            ..._inSelection
                ? [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _inSelection = false;
                          _selectedList.clear();
                        });
                      },
                      icon: Icon(Icons.cancel),
                    ),
                    IconButton(
                      onPressed: _viewSelected,
                      icon: const Icon(Icons.move_up),
                    ),
                    IconButton(
                      onPressed: _deleteSelected,
                      icon: const Icon(Icons.delete),
                    )
                  ]
                : [
                    IconButton(
                      icon: const Icon(Icons.rule),
                      onPressed: () {
                        setState(() {
                          _inSelection = !_inSelection;
                          _selectedList.clear();
                        });
                      },
                    ),
                    IconButton(
                        onPressed: _clearAll,
                        icon: const Icon(Icons.auto_delete)),
                  ],
          ],
        ),
        body: PikaListView(
          physics: _scrollPhysics,
          controller: _scrollController,
          children: entries.toList(),
        ),
      ),
      onNotification: (scrollNotification) {
        if (scrollNotification is ScrollStartNotification) {
          _handScroll();
        }
        return true;
      },
    );
    return rightClickPop(
      child: WillPopScope(
        onWillPop: () async {
          if (_inSelection) {
            setState(() {
              _inSelection = false;
              _selectedList.clear();
            });
            return false;
          }
          return true;
        },
        child: screen,
      ),
      context: context,
      canPop: true,
    );
  }

  void _chooseComic(String comicId) {
    Navigator.push(
      context,
      mixRoute(
        builder: (context) => ComicInfoScreen(
          comicId: comicId,
        ),
      ),
    );
  }

  List<String> _decodeCate(String categories) {
    try {
      var decode = jsonDecode(categories);
      if (decode is List) {
        return List.of(decode).cast();
      }
      return [decode];
    } catch (e) {
      return [categories];
    }
  }
}

class ViewInfoCard extends StatelessWidget {
  final String fileServer;
  final String path;
  final String title;
  final String author;
  final List<String> categories;
  final bool pinned;

  const ViewInfoCard({
    Key? key,
    required this.fileServer,
    required this.path,
    required this.title,
    required this.author,
    required this.categories,
    this.pinned = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.only(right: 10),
            child: RemoteImage(
              key: Key("$fileServer:$path"),
              fileServer: fileServer,
              path: path,
              width: imageWidth,
              height: imageHeight,
            ),
          ),
          Expanded(
            child: Row(
              children: [
                if (pinned)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.push_pin,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: titleStyle),
                      Container(height: 5),
                      Text(author, style: authorStyle),
                      Container(height: 5),
                      Text.rich(
                        TextSpan(
                            text:
                                "${tr('screen.view_logs.categories')} : ${categories.join(' ')}"),
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context)
                              .textTheme
                              .bodyText1!
                              .color!
                              .withAlpha(0xCC),
                        ),
                      ),
                      Container(height: 5),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
