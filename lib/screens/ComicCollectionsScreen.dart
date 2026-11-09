import 'package:pikapika/i18.dart';
import 'package:flutter/material.dart';
import 'package:pikapika/basic/Entities.dart';
import 'package:pikapika/basic/Method.dart';
import 'package:pikapika/screens/components/ComicList.dart';
import 'package:pikapika/screens/components/ContentBuilder.dart';
import 'package:pikapika/screens/components/ContentMessage.dart';

import 'components/RightClickPop.dart';

class ComicCollectionsScreen extends StatefulWidget {
  const ComicCollectionsScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ComicCollectionsScreenState();
}

class _ComicCollectionsScreenState extends State<ComicCollectionsScreen> {
  late Future<List<Collection>> _future;
  late Key _key = UniqueKey();

  @override
  void initState() {
    _future = method.collections();
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
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
    return Scaffold(
      appBar: AppBar(title: Text(tr('categories.recommend'))),
      body: ContentBuilder(
        key: _key,
        future: _future,
        onRefresh: () async {
          setState(() {
            _future = method.collections();
            _key = UniqueKey();
          });
        },
        successBuilder: (
          BuildContext context,
          AsyncSnapshot<List<Collection>> snapshot,
        ) {
          final collection = snapshot.requireData;
          if (collection.isEmpty) {
            return ContentMessage(
              message: tr('screen.comic_collections.no_resource'),
              icon: Icons.no_sim_outlined,
              onRefresh: () async {
                setState(() {
                  _future = method.collections();
                });
              },
            );
          }
          final AppBarThemeData appBarTheme = AppBarTheme.of(context);
          final Color titleColor = appBarTheme.foregroundColor ?? Colors.white;
          return DefaultTabController(
            length: collection.length,
            child: Scaffold(
              appBar: PreferredSizeContainer(
                color: appBarTheme.backgroundColor,
                child: TabBar(
                  indicatorColor: titleColor.withValues(alpha: 0.85),
                  labelColor: titleColor,
                  unselectedLabelColor: titleColor.withValues(alpha: 0.7),
                  dividerHeight: 0,
                  tabs: collection
                      .map((e) => Tab(
                          text: e.title.indexOf("推薦") > 0
                              ? e.title.substring(0, e.title.indexOf("推薦"))
                              : e.title))
                      .toList(),
                ),
              ),
              body: TabBarView(
                children: collection.map((e) => ComicList(e.comics)).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PreferredSizeContainer extends StatelessWidget
    implements PreferredSizeWidget {
  final PreferredSizeWidget child;
  final Color? color;

  const PreferredSizeContainer({
    required this.child,
    this.color,
    Key? key,
  }) : super(key: key);

  @override
  Size get preferredSize => child.preferredSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: child,
    );
  }
}
