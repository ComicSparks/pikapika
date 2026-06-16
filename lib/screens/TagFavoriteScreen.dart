import 'package:pikapika/i18.dart';
import 'package:flutter/material.dart';
import 'package:pikapika/basic/Common.dart';
import 'package:pikapika/basic/Navigator.dart';
import 'package:pikapika/basic/config/TagFavorite.dart';
import 'ComicsScreen.dart';
import 'components/RightClickPop.dart';

// 标签收藏
class TagFavoriteScreen extends StatefulWidget {
  const TagFavoriteScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TagFavoriteScreenState();
}

class _TagFavoriteScreenState extends State<TagFavoriteScreen> {
  bool _selecting = false;
  final Set<String> _selected = {};

  @override
  void initState() {
    tagFavoritesEvent.subscribe(_onEvent);
    super.initState();
  }

  @override
  void dispose() {
    tagFavoritesEvent.unsubscribe(_onEvent);
    super.dispose();
  }

  void _onEvent(dynamic a) {
    if (mounted) {
      setState(() {});
    }
  }

  void _enterSelectMode() {
    setState(() {
      _selecting = true;
      _selected.clear();
    });
  }

  void _exitSelectMode() {
    setState(() {
      _selecting = false;
      _selected.clear();
    });
  }

  void _toggleSelect(String tag) {
    setState(() {
      if (_selected.contains(tag)) {
        _selected.remove(tag);
      } else {
        _selected.add(tag);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selected
        ..clear()
        ..addAll(tagFavorites.map((e) => e.tag));
    });
  }

  Future<void> _removeTag(String tag) async {
    final bool confirm = await confirmDialog(
      context,
      tr('tag_favorite.delete'),
      "${tr('tag_favorite.delete_confirm')}\n$tag",
    );
    if (confirm) {
      await removeTagFavorite(tag);
    }
  }

  Future<void> _removeSelected() async {
    if (_selected.isEmpty) return;
    final bool confirm = await confirmDialog(
      context,
      tr('tag_favorite.delete_selected'),
      tr('tag_favorite.delete_selected_confirm'),
    );
    if (confirm) {
      await removeTagFavorites(_selected.toList());
      _exitSelectMode();
    }
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
    final favorites = tagFavorites;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selecting
              ? "${tr('tag_favorite.title')} (${_selected.length})"
              : tr('tag_favorite.title'),
        ),
        actions: favorites.isEmpty
            ? null
            : _selecting
                ? [
                    IconButton(
                      icon: const Icon(Icons.select_all),
                      tooltip: tr('tag_favorite.select_all'),
                      onPressed: _selectAll,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: tr('tag_favorite.delete_selected'),
                      onPressed: _selected.isEmpty ? null : _removeSelected,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: tr('tag_favorite.cancel_select'),
                      onPressed: _exitSelectMode,
                    ),
                  ]
                : [
                    IconButton(
                      icon: const Icon(Icons.checklist),
                      tooltip: tr('tag_favorite.select_mode'),
                      onPressed: _enterSelectMode,
                    ),
                  ],
      ),
      body: favorites.isEmpty
          ? Center(
              child: Text(tr('tag_favorite.no_tags')),
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: favorites.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final e = favorites[index];
                if (_selecting) {
                  return CheckboxListTile(
                    value: _selected.contains(e.tag),
                    title: Text(e.tag),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (_) => _toggleSelect(e.tag),
                  );
                }
                return ListTile(
                  title: Text(e.tag),
                  onTap: () {
                    navPushOrReplace(
                      context,
                      (context) => ComicsScreen(tag: e.tag),
                    );
                  },
                  onLongPress: () {
                    _removeTag(e.tag);
                  },
                );
              },
            ),
    );
  }
}
