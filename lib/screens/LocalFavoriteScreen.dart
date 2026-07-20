import 'package:pikapika/i18.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pikapika/basic/Entities.dart';
import 'package:pikapika/basic/Method.dart';
import 'package:pikapika/basic/config/IsPro.dart';
import 'package:pikapika/screens/ComicInfoScreen.dart';
import 'package:pikapika/screens/components/ComicInfoCard.dart';
import 'package:pikapika/screens/components/ContentLoading.dart';
import 'package:pikapika/screens/components/ListView.dart';
import 'package:pikapika/screens/components/RightClickPop.dart';
import 'components/DownloadComicsScreen.dart';

class LocalFavoriteScreen extends StatefulWidget {
  const LocalFavoriteScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LocalFavoriteScreenState();
}

// 将ViewLog转换为ComicSimple
ComicSimple _viewLogToComicSimple(ViewLog view) {
  List<dynamic> categories = [];
  try {
    categories = jsonDecode(view.categories);
  } catch (_) {
    categories = [];
  }
  return ComicSimple.fromJson({
    "_id": view.id,
    "title": view.title,
    "author": view.author,
    "pagesCount": view.pagesCount,
    "epsCount": view.epsCount,
    "finished": view.finished,
    "categories": categories,
    "likesCount": 0,
    "thumb": {
      "originalName": view.thumbOriginalName,
      "fileServer": view.thumbFileServer,
      "path": view.thumbPath,
    },
  });
}

class _LocalFavoriteScreenState extends State<LocalFavoriteScreen>
    {
  List<LocalFavoriteFolder> _folders = [];
  List<ComicSimple> _comics = [];
  String _currentFolderId = 'all';
  bool _loading = true;
  bool _selecting = false;
  final Set<String> _selectedComicIds = {};

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() {
      _loading = true;
    });

    try {
      final folders = await method.listLocalFavoriteFolders();
      if (!mounted) {
        return;
      }

      bool currentExists = _currentFolderId == 'all';
      if (_currentFolderId != 'all') {
        currentExists = folders.any((f) => f.id == _currentFolderId);
      }

      setState(() {
        _folders = folders;
        if (!currentExists) {
          _currentFolderId = 'all';
        }
      });

      await _loadComics();
    } catch (e) {
      print("Load folders error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _currentFolderTitle() {
    if (_currentFolderId == 'all') {
      return tr('local_favorite.all_folders');
    }
    for (final f in _folders) {
      if (f.id == _currentFolderId) {
        return f.name;
      }
    }
    return tr('local_favorite.all_folders');
  }

  Future<void> _loadComics() async {
    setState(() {
      _loading = true;
    });

    try {
      List<LocalFavoriteComic> localFavorites;
      if (_currentFolderId == 'all') {
        localFavorites = await method.listAllLocalFavoriteComics();
      } else {
        localFavorites = await method.listLocalFavoriteComics(_currentFolderId);
      }

      // 获取漫画详情
      List<ComicSimple> comics = [];
      for (var fav in localFavorites) {
        if (fav.info != null && fav.info!.isNotEmpty) {
          try {
            comics.add(ComicSimple.fromJson(
              Map<String, dynamic>.from(jsonDecode(fav.info!)),
            ));
            continue;
          } catch (e) {
            // Fallback to view log
          }
        }
        try {
          var view = await method.loadView(fav.comicId);
          if (view != null) {
            comics.add(_viewLogToComicSimple(view));
          }
        } catch (e) {
          print("Load comic ${fav.comicId} error: $e");
        }
      }

      if (mounted) {
        setState(() {
          _comics = comics;
        });
      }
    } catch (e) {
      print("Load comics error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return rightClickPop(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_selecting
              ? "${tr('local_favorite.title')} · ${tr('local_favorite.select_mode')} (${_selectedComicIds.length})"
              : "${tr('local_favorite.title')} · ${_currentFolderTitle()}"),
          actions: [
            IconButton(
              onPressed: _openFolderPicker,
              icon: const Icon(Icons.folder_open),
              tooltip: tr('local_favorite.select_folder'),
            ),
            _buildMenuButton(),
          ],
        ),
        body: _buildBody(),
      ),
      context: context,
      canPop: true,
    );
  }

  Future<void> _openFolderPicker() async {
    String? selected = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(tr('local_favorite.select_folder')),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: const Icon(Icons.folder_special),
                  title: Text(tr('local_favorite.all_folders')),
                  onTap: () => Navigator.of(context).pop('all'),
                ),
                const Divider(),
                ..._folders.map(
                  (f) => ListTile(
                    leading: const Icon(Icons.folder),
                    title: Text(f.name),
                    onTap: () => Navigator.of(context).pop(f.id),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.create_new_folder),
                  title: Text(tr('local_favorite.new_folder')),
                  onTap: () => Navigator.of(context).pop('__CREATE__'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(tr('app.cancel')),
            ),
          ],
        );
      },
    );

    if (!mounted || selected == null) return;
    if (selected == '__CREATE__') {
      await _createFolder();
      return;
    }
    if (selected != _currentFolderId) {
      setState(() {
        _currentFolderId = selected;
        _selecting = false;
        _selectedComicIds.clear();
      });
      await _loadComics();
    }
  }

  Widget _buildBody() {
    if (_loading) {
      return const ContentLoading(label: '加载中');
    }

    if (_folders.isEmpty && _comics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              tr('local_favorite.no_folders'),
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createFolder,
              icon: const Icon(Icons.create_new_folder),
              label: Text(tr('local_favorite.new_folder')),
            ),
          ],
        ),
      );
    }

    if (_comics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.book, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              tr('local_favorite.empty_folder'),
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ComicList(
      _comics,
    );
  }

  Widget ComicList(List<ComicSimple> comics) {
    final entries = comics.map((e) {
      Widget card = GestureDetector(
        onTap: () {
          if (_selecting) {
            setState(() {
              if (_selectedComicIds.contains(e.id)) {
                _selectedComicIds.remove(e.id);
              } else {
                _selectedComicIds.add(e.id);
              }
            });
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ComicInfoScreen(comicId: e.id),
              ),
            );
          }
        },
        child: ComicInfoCard(e, linkItem: true),
      );

      if (_selecting) {
        card = Stack(
          children: [
            card,
            Positioned(
              top: 10,
              right: 10,
              child: Icon(
                _selectedComicIds.contains(e.id)
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
                color: _selectedComicIds.contains(e.id)
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
          ],
        );
      }

      return card;
    });

    return PikaListView(
      children: entries.toList(),
    );
  }

  Widget _buildMenuButton() {
    return PopupMenuButton<int>(
      itemBuilder: (BuildContext context) => <PopupMenuItem<int>>[
        PopupMenuItem<int>(
          value: 10,
          child: ListTile(
            leading: const Icon(Icons.create_new_folder),
            title: Text(tr('local_favorite.new_folder')),
          ),
        ),
        if (_currentFolderId != 'all')
          PopupMenuItem<int>(
            value: 11,
            child: ListTile(
              leading: const Icon(Icons.delete),
              title: Text(tr('local_favorite.delete_folder')),
            ),
          ),
        if (!_selecting && _comics.isNotEmpty)
          PopupMenuItem<int>(
            value: 20,
            child: ListTile(
              leading: Icon(
                Icons.checklist,
              ),
              title: Text(
                tr('local_favorite.select_mode'),
              ),
            ),
          ),
        if (_selecting)
          PopupMenuItem<int>(
            value: 21,
            child: ListTile(
              leading: const Icon(Icons.close),
              title: Text(tr('local_favorite.cancel_select_mode')),
            ),
          ),
        if (_selecting && _comics.isNotEmpty)
          PopupMenuItem<int>(
            value: 22,
            child: ListTile(
              leading: const Icon(Icons.select_all),
              title: Text(tr('local_favorite.select_all')),
            ),
          ),
        if (_selecting && _selectedComicIds.isNotEmpty)
          PopupMenuItem<int>(
            value: 1,
            child: ListTile(
              leading: const Icon(Icons.drive_file_move),
              title: Text(tr('local_favorite.move_to_folder')),
            ),
          ),
        if (_selecting && _selectedComicIds.isNotEmpty)
          PopupMenuItem<int>(
            value: 0,
            child: ListTile(
              leading: Icon(
                Icons.download,
                color: isPro ? null : Colors.grey,
              ),
              title: Text(
                tr('local_favorite.batch_download') +
                    (isPro ? "" : " (${tr('app.pro')})"),
                style: TextStyle(
                  color: isPro ? null : Colors.grey,
                ),
              ),
            ),
          ),
        if (_selecting && _selectedComicIds.isNotEmpty)
          PopupMenuItem<int>(
            value: 23,
            child: ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(tr('local_favorite.remove_selected')),
            ),
          ),
        PopupMenuItem<int>(
          value: 3,
          child: ListTile(
            leading: const Icon(Icons.refresh),
            title: Text(tr('app.refresh')),
          ),
        ),
      ],
      onSelected: (int value) {
        switch (value) {
          case 10:
            _createFolder();
            break;
          case 11:
            _deleteFolder();
            break;
          case 20:
            setState(() {
              _selecting = true;
              _selectedComicIds.clear();
            });
            break;
          case 21:
            setState(() {
              _selecting = false;
              _selectedComicIds.clear();
            });
            break;
          case 22:
            setState(() {
              _selectedComicIds.clear();
              for (final c in _comics) {
                _selectedComicIds.add(c.id);
              }
            });
            break;
          case 0:
            _batchDownload();
            break;
          case 1:
            _moveToFolder();
            break;
          case 23:
            _removeSelected();
            break;
          case 3:
            _loadComics();
            break;
        }
      },
    );
  }

  Future<void> _createFolder() async {
    int folderCount = await method.countLocalFavoriteFolders();

    if (!isPro && folderCount >= 3) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('local_favorite.folder_limit_reached')),
          ),
        );
      }
      return;
    }

    String? folderName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text(tr('local_favorite.new_folder')),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: tr('local_favorite.folder_name'),
            ),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(tr('app.cancel')),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text.trim());
              },
              child: Text(tr('app.confirm')),
            ),
          ],
        );
      },
    );

    if (folderName != null && folderName.isNotEmpty) {
      try {
        await method.createLocalFavoriteFolder(folderName);
        await _loadFolders();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('local_favorite.create_success'))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('local_favorite.create_folder_failed'))),
          );
        }
      }
    }
  }

  Future<void> _deleteFolder() async {
    if (_currentFolderId == 'all') return;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(tr('local_favorite.delete_folder')),
          content: Text(tr('local_favorite.delete_confirm')),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(tr('app.cancel')),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(tr('app.confirm')),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await method.deleteLocalFavoriteFolder(_currentFolderId);
        _currentFolderId = 'all';
        await _loadFolders();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('local_favorite.delete_success'))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('local_favorite.delete_failed'))),
          );
        }
      }
    }
  }

  Future<void> _batchDownload() async {
    if (!_selecting || _selectedComicIds.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('local_favorite.select_comics'))),
        );
      }
      return;
    }
    if (!isPro) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('app.pro_required'))),
      );
      return;
    }

    final list = _selectedComicIds.toList();
    setState(() {
      _selecting = false;
      _selectedComicIds.clear();
    });
    Navigator.of(context).push(MaterialPageRoute(
      builder: (BuildContext context) {
        return DownloadComicsScreen(list);
      },
    ));
  }

  Future<void> _moveToFolder() async {
    if (_selectedComicIds.isEmpty) return;

    List<LocalFavoriteFolder> targetFolders =
        _folders.where((f) => f.id != _currentFolderId).toList();

    String? targetFolderId = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(tr('local_favorite.move_to_folder')),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: targetFolders.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    leading: const Icon(Icons.folder_special),
                    title: Text(tr('local_favorite.all_folders')),
                    onTap: () {
                      Navigator.of(context).pop('');
                    },
                  );
                }
                final folder = targetFolders[index - 1];
                return ListTile(
                  leading: const Icon(Icons.folder),
                  title: Text(folder.name),
                  onTap: () {
                    Navigator.of(context).pop(folder.id);
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(tr('app.cancel')),
            ),
          ],
        );
      },
    );

    if (targetFolderId != null) {
      try {
        await method.moveLocalFavoriteComics(
          _selectedComicIds.toList(),
          targetFolderId,
        );
        setState(() {
          _selecting = false;
          _selectedComicIds.clear();
        });
        await _loadComics();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('local_favorite.move_success'))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('local_favorite.move_failed'))),
          );
        }
      }
    }
  }

  Future<void> _removeSelected() async {
    if (_selectedComicIds.isEmpty) return;
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(tr('local_favorite.remove_selected')),
          content: Text(tr('local_favorite.remove_selected_confirm')),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(tr('app.cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(tr('app.confirm')),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;

    try {
      final ids = _selectedComicIds.toList();
      for (final id in ids) {
        await method.removeLocalFavoriteComic(id);
      }
      if (!mounted) return;
      setState(() {
        _selectedComicIds.clear();
        _selecting = false;
      });
      await _loadComics();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('local_favorite.remove_selected_success'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('local_favorite.remove_selected_failed'))),
        );
      }
    }
  }
}
