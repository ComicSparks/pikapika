import 'dart:async';
import 'dart:math';

import 'package:pikapika/i18.dart';
import 'package:flutter/material.dart';
import 'components/flutter_search_bar.dart' as fsb;
import 'package:pikapika/basic/Channels.dart';
import 'package:pikapika/basic/Common.dart';
import 'package:pikapika/basic/Entities.dart';
import 'package:pikapika/basic/Method.dart';
import 'package:pikapika/screens/DownloadExportGroupScreen.dart';
import '../basic/config/IconLoading.dart';
import 'DownloadImportScreen.dart';
import 'DownloadInfoScreen.dart';
import 'components/ContentLoading.dart';
import 'components/DownloadInfoCard.dart';
import 'components/ListView.dart';
import 'components/RightClickPop.dart';

// 下载列表
class DownloadListScreen extends StatefulWidget {
  const DownloadListScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DownloadListScreenState();
}

class _DownloadListScreenState extends State<DownloadListScreen> {
  String _search = "";
  bool _selecting = false;
  List<String> _selectingList = [];
  List<String> _selectable = [];
  String _filterCustomFolder = "";
  List<String> _folderList = [];

  late final fsb.SearchBar _searchBar = fsb.SearchBar(
    hintText: tr('screen.download_list.search_download'),
    inBar: false,
    setState: setState,
    onSubmitted: (value) {
      _search = value;
      _reloadList();
      setState(() {});
      _searchBar.controller.text = value;
    },
    buildDefaultAppBar: (BuildContext context) {
      final theme = Theme.of(context);
      final appBarIconColor = theme.appBarTheme.foregroundColor ?? Colors.white;
      if (_selecting) {
        return AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              if (_selecting) {
                setState(() {
                  _selecting = false;
                  _selectingList = [];
                });
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(tr('screen.download_list.multi_select_operation')),
          actions: [
            _selectingCancelButton(appBarIconColor),
            _selectingMoveButton(appBarIconColor),
            _selectingDeleteButton(appBarIconColor),
            _selectAllButton(appBarIconColor),
          ],
        );
      }

      return AppBar(
        title: Text(_search == ""
            ? tr('screen.download_list.download_list')
            : (tr('screen.download_list.search_download') + ' - $_search')),
        actions: [
          //_searchBar.getSearchAction(context),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _searchBar.beginSearch(context);
            },
            child: Column(
              children: [
                Expanded(child: Container()),
                Icon(
                  Icons.search,
                  size: 18,
                  color: appBarIconColor,
                ),
                Text(
                  tr('screen.download_list.search'),
                  style: TextStyle(fontSize: 14, color: appBarIconColor),
                ),
                Expanded(child: Container()),
              ],
            ),
          ),
          _customFolderButton(appBarIconColor),
          _toSelectingButton(appBarIconColor),
          _fileButton(appBarIconColor),
          Container(width: 10),
          pauseButton(appBarIconColor),
        ],
      );
    },
  );

  DownloadComic? _downloading;
  late bool _downloadRunning = false;
  late Future<List<DownloadComic>> _f = method
      .allDownloads(_search, customFolder: _filterCustomFolder)
      .then((value) {
    setState(() {
      _selecting = false;
      _selectingList = [];
      _selectable = value.map((e) => e.id).toList();
    });
    return value;
  });

  List<DownloadComic> _data = [];
  final Set<String> _deletingIds = {};

  bool _isDeleting(DownloadComic comic) {
    return comic.deleting || _deletingIds.contains(comic.id);
  }

  void _onMessageChange(AppEvent event) {
    if (event case AppEvent_Download(:final comic)) {
      setState(() {
        _downloading = comic;
      });
    }
  }

  @override
  void initState() {
    registerEvent(_onMessageChange, "DOWNLOAD");
    method
        .downloadRunning()
        .then((val) => setState(() => _downloadRunning = val));
    method.allCustomFolders().then((value) {
      setState(() {
        _folderList = value.where((e) => e.isNotEmpty).toList();
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    unregisterEvent(_onMessageChange);
    super.dispose();
  }

  Widget _selectAllButton(Color appBarIconColor) {
    return IconButton(
      icon: Icon(
        Icons.select_all,
        size: 18,
        color: appBarIconColor,
      ),
      onPressed: () async {
        setState(() {
          if (_selectingList.length >= _selectable.length) {
            _selectingList.clear();
          } else {
            _selectingList.clear();
            _selectingList.addAll(_selectable);
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = Scaffold(
      appBar: _searchBar.build(context),
      body: FutureBuilder(
        future: _f,
        builder: (BuildContext context,
            AsyncSnapshot<List<DownloadComic>> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return ContentLoading(label: tr('app.loading'));
          }

          if (snapshot.hasError) {
            print("${snapshot.error}");
            print("${snapshot.stackTrace}");
            return Center(child: Text(tr('app.loading_failed')));
          }

          var data = List<DownloadComic>.of(snapshot.data!);
          _data = data;
          if (_downloading != null) {
            for (var i = 0; i < data.length; i++) {
              if (_downloading!.id == data[i].id) {
                data[i] = _downloading!;
              }
            }
          }

          if (_selecting) {
            return ListView(
              children: [
                ...data.map(selectingWidget),
              ],
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _reloadList();
              setState(() {});
            },
            child: PikaListView(
              children: [
                ...data.map(downloadWidget),
              ],
            ),
          );
        },
      ),
    );
    var w = rightClickPop(
      child: screen,
      context: context,
      canPop: true,
    );
    return WillPopScope(
      onWillPop: () async {
        if (_selecting) {
          setState(() {
            _selecting = false;
            _selectingList = [];
          });
          return false;
        }
        return true;
      },
      child: w,
    );
  }

  Widget _customFolderButton(Color appBarIconColor) {
    return IconButton(
        onPressed: () async {
          String? choose = await chooseListDialog(
              context, tr('screen.download_list.select_folder'), [
            tr('app.all'),
            ..._folderList,
          ]);
          if (choose != null) {
            if (choose == tr('app.all')) {
              choose = "";
            }
            _filterCustomFolder = choose;
            _reloadList();
            setState(() {});
          }
        },
        icon: Column(
          children: [
            Expanded(child: Container()),
            Icon(
              Icons.folder,
              size: 18,
              color: appBarIconColor,
            ),
            Text(
              _customFolderName(),
              style: TextStyle(fontSize: 14, color: appBarIconColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Expanded(child: Container()),
          ],
        ));
  }

  String _customFolderName() {
    if (_filterCustomFolder == "") {
      return tr('app.all');
    }
    return _filterCustomFolder;
  }

  Widget downloadWidget(DownloadComic e) {
    return InkWell(
      onTap: () {
        if (_isDeleting(e)) {
          return;
        }
        Navigator.push(
          context,
          mixRoute(
            builder: (context) => DownloadInfoScreen(
              comicId: e.id,
              comicTitle: e.title,
            ),
          ),
        );
      },
      onLongPress: () async {
        String? action =
            await chooseListDialog(context, e.title, [tr('app.delete')]);
        if (action == tr('app.delete')) {
          await method.deleteDownloadComic(e.id);
          setState(() => _deletingIds.add(e.id));
        }
      },
      child: DownloadInfoCard(
        task: e,
        downloading: _downloading != null && _downloading!.id == e.id,
      ),
    );
  }

  Widget selectingWidget(DownloadComic e) {
    return InkWell(
      onTap: () {
        if (_isDeleting(e)) {
          defaultToast(context,
              tr('screen.download_list.download_already_in_delete_queue'));
          return;
        } else {
          if (_selectingList.contains(e.id)) {
            setState(() {
              _selectingList.remove(e.id);
            });
          } else {
            setState(() {
              _selectingList.add(e.id);
            });
          }
        }
      },
      child: Stack(
        children: [
          DownloadInfoCard(
            task: e,
            downloading: _downloading != null && _downloading!.id == e.id,
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
                    _selectingList.contains(e.id)
                        ? Icons.check_circle_sharp
                        : Icons.circle_outlined,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fileButton(Color appBarIconColor) {
    return PopupMenuButton<int>(
      itemBuilder: (BuildContext context) => <PopupMenuItem<int>>[
        PopupMenuItem<int>(
          value: 0,
          child: ListTile(
            leading: const Icon(Icons.read_more),
            title: Text(tr('screen.download_list.import')),
          ),
        ),
        PopupMenuItem<int>(
          value: 1,
          child: ListTile(
            leading: const Icon(Icons.save_alt),
            title: Text(tr('screen.download_list.export')),
          ),
        ),
      ],
      onSelected: (a) async {
        if (a == 0) {
          await Navigator.push(
            context,
            mixRoute(
              builder: (context) => const DownloadImportScreen(),
            ),
          );
          _reloadList();
          setState(() {});
        } else if (a == 1) {
          await Navigator.push(
            context,
            mixRoute(
              builder: (context) => const DownloadExportGroupScreen(),
            ),
          );
        }
      },
      child: Column(
        children: [
          Expanded(child: Container()),
          Icon(
            Icons.drive_file_move,
            size: 18,
            color: appBarIconColor,
          ),
          Text(
            tr('screen.download_list.file'),
            style: TextStyle(fontSize: 14, color: appBarIconColor),
          ),
          Expanded(child: Container()),
        ],
      ),
    );
  }

  Future<void> _onPauseChangeClick() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(tr('screen.download_list.download_task')),
          content: Text(
            _downloadRunning
                ? tr('screen.download_list.pause_download')
                : tr('screen.download_list.start_download'),
          ),
          actions: [
            MaterialButton(
              onPressed: () async {
                Navigator.pop(context);
              },
              child: Text(tr('app.cancel')),
            ),
            MaterialButton(
              onPressed: () async {
                Navigator.pop(context);
                var to = !_downloadRunning;
                await method.setDownloadRunning(to);
                setState(() {
                  _downloadRunning = to;
                });
              },
              child: Text(tr('app.confirm')),
            ),
          ],
        );
      },
    );
  }

  Widget pauseButton(Color appBarIconColor) {
    return PopupMenuButton<int>(
        itemBuilder: (BuildContext context) => <PopupMenuItem<int>>[
              PopupMenuItem<int>(
                value: 0,
                child: ListTile(
                  leading: const Icon(Icons.compare_arrows_sharp),
                  title: Text(_downloadRunning
                      ? tr('screen.download_list.pause_download')
                      : tr('screen.download_list.start_download')),
                ),
              ),
              PopupMenuItem<int>(
                value: 1,
                child: ListTile(
                  leading: const Icon(Icons.sync_problem),
                  title: Text(tr('screen.download_list.resume_failed')),
                ),
              ),
            ],
        onSelected: (a) async {
          if (a == 0) {
            await _onPauseChangeClick();
          } else if (a == 1) {
            await method.resetFailed();
            _reloadList();
            setState(() {});
            defaultToast(
                context, tr('screen.download_list.resume_failed_desc'));
          }
        },
        child: Column(
          children: [
            Expanded(child: Container()),
            Icon(
              _downloadRunning
                  ? Icons.compare_arrows_sharp
                  : Icons.schedule_send,
              size: 18,
              color: appBarIconColor,
            ),
            Text(
              _downloadRunning
                  ? tr('screen.download_list.downloading')
                  : tr('screen.download_list.paused'),
              style: TextStyle(fontSize: 14, color: appBarIconColor),
            ),
            Expanded(child: Container()),
          ],
        ));
  }

  void _reloadList() {
    _f = method
        .allDownloads(_search, customFolder: _filterCustomFolder)
        .then((value) {
      setState(() {
        _selecting = false;
        _selectingList = [];
      });
      return value;
    });
    method.allCustomFolders().then((value) {
      setState(() {
        _folderList = value.where((e) => e.isNotEmpty).toList();
      });
    });
  }

  Widget _selectingCancelButton(Color appBarIconColor) {
    return IconButton(
      onPressed: () {
        setState(() {
          _selecting = false;
          _selectingList = [];
        });
      },
      icon: Icon(Icons.cancel, color: appBarIconColor),
    );
  }

  Widget _selectingMoveButton(Color appBarIconColor) {
    return IconButton(
      onPressed: () async {
        var tmp = _selectingList;
        _selecting = false;
        _selectingList = [];
        setState(() {});
        if (tmp.isEmpty) {
          defaultToast(
              context, tr('screen.download_list.select_download_to_move'));
        } else {
          var moveToChoose = await chooseListDialog(
            context,
            tr('screen.download_list.move_download'),
            [
              tr('app.all'),
              ..._folderList,
              tr('screen.download_list.input_name')
            ],
            tips: tr('screen.download_list.empty_folder_will_be_deleted'),
          );
          if (moveToChoose == null) {
            return;
          }
          if (moveToChoose == tr('screen.download_list.input_name')) {
            String? name = await displayTextInputDialog(context,
                title: tr('screen.download_list.folder_name'),
                hint: tr('screen.download_list.please_input_folder_name'));
            if (name != null) {
              if (tr('app.all') != name &&
                  tr('screen.download_list.input_name') != name) {
                await method.moveDownloadComic(tmp, name);
                _reloadList();
                setState(() {});
              }
            }
          } else if (moveToChoose == tr('app.all')) {
            await method.moveDownloadComic(tmp, "");
            _reloadList();
            setState(() {});
          } else {
            await method.moveDownloadComic(tmp, moveToChoose);
            _reloadList();
            setState(() {});
          }
        }
      },
      icon: Icon(Icons.move_down, color: appBarIconColor),
    );
  }

  Widget _selectingDeleteButton(Color appBarIconColor) {
    return IconButton(
      onPressed: () async {
        var tmp = _selectingList;
        _selecting = false;
        _selectingList = [];
        setState(() {});
        if (tmp.isEmpty) {
          defaultToast(
              context, tr('screen.download_list.select_download_to_delete'));
        } else {
          if (await confirmDialog(
              context,
              tr('screen.download_list.delete_download'),
              tr('screen.download_list.delete_selected_download'))) {
            for (var id in tmp) {
              await method.deleteDownloadComic(id);
            }
            for (var i = 0; i < _data.length; i++) {
              if (tmp.contains(_data[i].id)) {
                _deletingIds.add(_data[i].id);
              }
            }
            _selecting = false;
            _selectingList = [];
            //_reloadList();
            setState(() {});
          }
        }
      },
      icon: Icon(Icons.delete, color: appBarIconColor),
    );
  }

  Widget _toSelectingButton(Color appBarIconColor) {
    return IconButton(
      onPressed: () {
        setState(() {
          _selecting = true;
          _selectingList = [];
        });
      },
      icon: Column(
        children: [
          Expanded(child: Container()),
          Icon(
            Icons.rule,
            size: 18,
            color: appBarIconColor,
          ),
          Text(
            tr('screen.download_list.multi_select'),
            style: TextStyle(fontSize: 14, color: appBarIconColor),
          ),
          Expanded(child: Container()),
        ],
      ),
    );
  }
}
