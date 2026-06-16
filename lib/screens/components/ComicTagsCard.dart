import 'package:pikapika/i18.dart';
import 'package:flutter/material.dart';
import 'package:pikapika/screens/ComicsScreen.dart';
import 'package:pikapika/basic/Navigator.dart';
import 'package:pikapika/basic/Common.dart';
import 'package:pikapika/basic/config/TagFavorite.dart';

// 漫画tag
class ComicTagsCard extends StatefulWidget {
  final List<String> tags;

  const ComicTagsCard(this.tags, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ComicTagsCardState();
}

class _ComicTagsCardState extends State<ComicTagsCard> {
  Future<void> _onLongPress(String tag) async {
    final bool favorite = isTagFavorite(tag);
    final String action = favorite
        ? tr('tag_favorite.remove_favorite')
        : tr('tag_favorite.add_favorite');
    final String? choose = await chooseListDialog(context, tag, [action]);
    if (choose == action) {
      if (favorite) {
        await removeTagFavorite(tag);
      } else {
        await addTagFavorite(tag);
      }
      if (mounted) {
        defaultToast(
          context,
          favorite
              ? tr('tag_favorite.removed')
              : tr('tag_favorite.added'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    final tags = widget.tags;
    return Container(
      padding: const EdgeInsets.only(top: 5, bottom: 5),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
          ),
        ),
      ),
      child: Wrap(
        children: tags.map((e) {
          return InkWell(
            onTap: () {
              navPushOrReplace(context, (context) => ComicsScreen(tag: e));
            },
            onLongPress:
                tagFavoriteEnable ? () => _onLongPress(e) : null,
            child: Container(
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
              child: Text(
                e,
                style: TextStyle(
                  color: Colors.pink.shade500,
                  height: 1.4,
                ),
                strutStyle: const StrutStyle(
                  height: 1.4,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
