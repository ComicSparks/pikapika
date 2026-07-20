import 'package:pikapika/i18.dart';
import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'SearchAuthorScreen.dart';
import 'components/flutter_search_bar.dart' as fsb;
import 'package:pikapika/basic/Entities.dart';
import 'package:pikapika/basic/config/HiddenSubIcon.dart';
import 'package:pikapika/basic/config/ShadowCategoriesEvent.dart';
import 'package:pikapika/basic/config/ShadowCategoriesMode.dart';
import 'package:pikapika/basic/store/Categories.dart';
import 'package:pikapika/basic/config/ShadowCategories.dart';
import 'package:pikapika/screens/ComicCollectionsScreen.dart';
import 'package:pikapika/screens/RankingsScreen.dart';
import 'package:pikapika/screens/SearchScreen.dart';
import 'package:pikapika/screens/components/ContentError.dart';
import 'package:pikapika/basic/Method.dart';
import '../basic/config/Address.dart';
import '../basic/config/CategoriesColumnCount.dart';
import '../basic/config/CategoriesHidden.dart';
import '../basic/config/CategoriesSort.dart';
import '../basic/config/IconLoading.dart';
import 'ComicSubscribesScreen.dart';
import 'ComicsScreen.dart';
import 'GamesScreen.dart';
import 'RandomComicsScreen.dart';
import 'components/Common.dart';
import 'components/ContentLoading.dart';
import 'components/Images.dart';
import 'components/ListView.dart';

// 分类
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late final fsb.SearchBar _searchBar = fsb.SearchBar(
    hintText: tr('screen.categories.search_hint'),
    inBar: false,
    setState: setState,
    onSubmitted: (value) {
      if (value.isNotEmpty) {
        Navigator.push(
          context,
          mixRoute(
            builder: (context) => SearchScreen(keyword: value),
          ),
        );
      }
    },
    buildDefaultAppBar: (BuildContext context) {
      return AppBar(
        title: Text(tr('app.categories')),
        actions: [
          if (!hiddenSubIcon) const IntoComicSubscribesScreenButton(),
          commonPopMenu(context),
          addressPopMenu(context),
          if (!hiddenSubIcon) const ComicSearchAuthorScreenButton(),
          _searchBar.getSearchAction(context),
        ],
      );
    },
  );

  late Future<List<Category>> _categoriesFuture = _fetch();

  Future<List<Category>> _fetch() async {
    List<Category> categories = await method.categories();
    storedCategories = [];
    for (var element in categories) {
      if (!element.isWeb) {
        storedCategories.add(element.title);
      }
    }
    return categories;
  }

  void _reloadCategories() {
    setState(() {
      this._categoriesFuture = _fetch();
    });
  }

  @override
  void initState() {
    shadowCategoriesEvent.subscribe(_onShadowChange);
    categoriesColumnCountEvent.subscribe(_setState);
    categoriesSortEvent.subscribe(_onShadowChange);
    categoriesHiddenEvent.subscribe(_onShadowChange);
    hiddenSubIconEvent.subscribe(_setState);
    super.initState();
  }

  @override
  void dispose() {
    shadowCategoriesEvent.unsubscribe(_onShadowChange);
    categoriesColumnCountEvent.unsubscribe(_setState);
    categoriesSortEvent.unsubscribe(_onShadowChange);
    categoriesHiddenEvent.unsubscribe(_onShadowChange);
    hiddenSubIconEvent.unsubscribe(_setState);
    super.dispose();
  }

  void _onShadowChange(EventArgs? args) {
    _reloadCategories();
  }

  _setState(_) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var themeBackground = theme.scaffoldBackgroundColor;
    var shadeBackground = Color.fromARGB(
      0x11,
      255 - themeBackground.red,
      255 - themeBackground.green,
      255 - themeBackground.blue,
    );
    return Scaffold(
      appBar: _searchBar.build(context),
      body: Container(
        color: shadeBackground,
        child: FutureBuilder(
          future: _categoriesFuture,
          builder:
              ((BuildContext context, AsyncSnapshot<List<Category>> snapshot) {
            if (snapshot.hasError) {
              return ContentError(
                error: snapshot.error,
                stackTrace: snapshot.stackTrace,
                onRefresh: () async {
                  _reloadCategories();
                },
              );
            }
            if (snapshot.connectionState != ConnectionState.done) {
              return ContentLoading(label: tr('app.loading'));
            }
            //
            late double blockSize;
            late double imageSize;
            late double imageRs;
            if (categoriesColumnCount == 0) {
              var size = MediaQuery.of(context).size;
              var min = size.width < size.height ? size.width : size.height;
              blockSize = (min ~/ 3).floorToDouble();
            } else {
              var size = MediaQuery.of(context).size;
              var min = size.width;
              blockSize = (min ~/ categoriesColumnCount).floorToDouble();
            }
            imageSize = blockSize - 15;
            imageRs = imageSize / 10;
            List<CategoriesItem> items = [];
            //
            items.addAll(_buildChannels(imageSize));
            items.addAll(_buildCategories(snapshot.data!, imageSize));
            var hidden = getCategoriesHidden();
            items.removeWhere((e) => hidden.contains(e.title));
            var names = items.map((e) => e.title).toList();
            var sort = getCategoriesSort();
            items.sort((a, b) {
              var aIndex = sort.indexOf(a.title);
              var bIndex = sort.indexOf(b.title);
              if (aIndex == bIndex) {
                aIndex = names.indexOf(a.title);
                bIndex = names.indexOf(b.title);
              }
              if (aIndex == -1) {
                return 1;
              } else if (bIndex == -1) {
                return -1;
              } else {
                return aIndex - bIndex;
              }
            });
            List<Widget> wrapItems = _wrapItems(items, blockSize, imageRs);
            return PikaListView(
              children: [
                Container(height: 20),
                Wrap(
                  runSpacing: 20,
                  alignment: WrapAlignment.spaceAround,
                  children: wrapItems,
                ),
                Container(height: 20),
              ],
            );
          }),
        ),
      ),
    );
  }

  List<Widget> _wrapItems(
    List<CategoriesItem> items,
    double blockSize,
    double imageRs,
  ) {
    List<Widget> list = [];

    append(Widget widget, String title, Function() onTap) {
      list.add(
        GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: blockSize,
            child: Column(
              children: [
                Card(
                  elevation: .5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(imageRs)),
                    child: widget,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(imageRs)),
                  ),
                ),
                Container(height: 5),
                Center(
                  child: Text(title),
                ),
              ],
            ),
          ),
        ),
      );
    }

    for (var value in items) {
      append(value.icon, value.title, value.onTap);
    }

    return list;
  }

  List<CategoriesItem> _buildCategories(
    List<Category> cList,
    double imageSize,
  ) {
    List<CategoriesItem> items = [];

    items.add(CategoriesItem(
      buildSvg('lib/assets/books.svg', imageSize, imageSize, margin: 20),
      tr('categories.all'),
      () => _navigateToCategory(null),
    ));

    items.add(CategoriesItem(
      Icon(
        Icons.recommend_outlined,
        size: imageSize,
        color: Colors.grey,
      ),
      tr('categories.recommend'),
      () {
        Navigator.push(
          context,
          mixRoute(
            builder: (context) => const ComicCollectionsScreen(),
          ),
        );
      },
    ));

    for (var i = 0; i < cList.length; i++) {
      var c = cList[i];
      if (c.isWeb) continue;
      switch (currentShadowCategoriesMode()) {
        case ShadowCategoriesMode.BLACK_LIST:
          if (shadowCategories.contains(c.title)) continue;
          break;
        case ShadowCategoriesMode.WHITE_LIST:
          if (!shadowCategories.contains(c.title)) continue;
          break;
      }
      items.add(CategoriesItem(
        RemoteImage(
          fileServer: c.thumb.fileServer,
          path: c.thumb.path,
          width: imageSize,
          height: imageSize,
        ),
        c.title,
        () => _navigateToCategory(c.title),
      ));
    }

    return items;
  }

  List<CategoriesItem> _buildChannels(double imageSize) {
    List<CategoriesItem> items = [];

    items.add(CategoriesItem(
      buildSvg('lib/assets/rankings.svg', imageSize, imageSize,
          margin: 20, color: Colors.red.shade700),
      tr('categories.rankings'),
      () {
        Navigator.push(
          context,
          mixRoute(builder: (context) => const RankingsScreen()),
        );
      },
    ));

    items.add(CategoriesItem(
      buildSvg('lib/assets/random.svg', imageSize, imageSize,
          margin: 20, color: Colors.orangeAccent.shade700),
      tr('categories.random'),
      () {
        Navigator.push(
          context,
          mixRoute(builder: (context) => const RandomComicsScreen()),
        );
      },
    ));

    items.add(CategoriesItem(
      buildSvg('lib/assets/gamepad.svg', imageSize, imageSize,
          margin: 20, color: Colors.blue.shade500),
      tr('categories.game'),
      () {
        Navigator.push(
          context,
          mixRoute(builder: (context) => const GamesScreen()),
        );
      },
    ));

    return items;
  }

  void _navigateToCategory(String? categoryTitle) {
    Navigator.push(
      context,
      mixRoute(
        builder: (context) => ComicsScreen(category: categoryTitle),
      ),
    );
  }
}

class CategoriesItem {
  final Widget icon;
  final String title;
  final Function() onTap;

  const CategoriesItem(
    this.icon,
    this.title,
    this.onTap,
  );
}
