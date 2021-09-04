import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_search_bar/flutter_search_bar.dart';
import 'package:pikapi/basic/Entities.dart';
import 'package:pikapi/basic/store/Categories.dart';
import 'package:pikapi/basic/config/ShadowCategories.dart';
import 'package:pikapi/screens/RankingsScreen.dart';
import 'package:pikapi/screens/SearchScreen.dart';
import 'package:pikapi/screens/components/ContentError.dart';
import 'package:pikapi/basic/Pica.dart';
import 'ComicsScreen.dart';
import 'GamesScreen.dart';
import 'RandomComicsScreen.dart';
import 'components/ContentLoading.dart';
import 'components/Images.dart';

// 分类
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen();

  @override
  State<StatefulWidget> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late SearchBar _searchBar = SearchBar(
    hintText: '搜索',
    inBar: false,
    setState: setState,
    onSubmitted: (value) {
      if (value.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SearchScreen(keyword: value),
          ),
        );
      }
    },
    buildDefaultAppBar: (BuildContext context) {
      return AppBar(
        title: new Text('分类'),
        actions: [_searchBar.getSearchAction(context)],
      );
    },
  );

  late Future<List<Category>> _categoriesFuture = _fetch();

  Future<List<Category>> _fetch() async {
    List<Category> categories = await pica.categories();
    storedCategories = [];
    categories.forEach((element) {
      if (!element.isWeb) {
        storedCategories.add(element.title);
      }
    });
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
    super.initState();
  }

  @override
  void dispose() {
    shadowCategoriesEvent.unsubscribe(_onShadowChange);
    super.dispose();
  }

  void _onShadowChange(EventArgs? args) {
    _reloadCategories();
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
              return ContentLoading(label: '加载中');
            }
            return ListView(
              children: [
                Container(height: 20),
                Wrap(
                  runSpacing: 20,
                  alignment: WrapAlignment.spaceAround,
                  children: _buildChannels(),
                ),
                Divider(),
                Wrap(
                  runSpacing: 20,
                  alignment: WrapAlignment.spaceAround,
                  children: _buildCategories(snapshot.data!),
                ),
                Container(height: 20),
              ],
            );
          }),
        ),
      ),
    );
  }

  List<Widget> _buildCategories(List<Category> cList) {
    var size = MediaQuery.of(context).size;
    var min = size.width < size.height ? size.width : size.height;
    var blockSize = min / 3;
    var imageSize = blockSize - 15;
    var imageRs = imageSize / 10;

    List<Widget> list = [];

    var append = (Widget widget, String title, Function() onTap) {
      list.add(
        GestureDetector(
          onTap: onTap,
          child: Container(
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
    };

    append(
      buildSvg('lib/assets/books.svg', imageSize, imageSize, margin: 20),
      "全分类",
      () => _navigateToCategory(null),
    );

    for (var i = 0; i < cList.length; i++) {
      var c = cList[i];
      if (c.isWeb) continue;
      if (shadowCategories.contains(c.title)) continue;
      append(
        RemoteImage(
          fileServer: c.thumb.fileServer,
          path: c.thumb.path,
          width: imageSize,
          height: imageSize,
        ),
        c.title,
            () => _navigateToCategory(c.title),
      );
    }

    return list;
  }

  List<Widget> _buildChannels() {
    var size = MediaQuery.of(context).size;
    var min = size.width < size.height ? size.width : size.height;
    var blockSize = min / 3;
    var imageSize = blockSize - 15;
    var imageRs = imageSize / 10;

    List<Widget> list = [];

    var append = (Widget widget, String title, Function() onTap) {
      list.add(
        GestureDetector(
          onTap: onTap,
          child: Container(
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
    };

    append(
      buildSvg('lib/assets/rankings.svg', imageSize, imageSize,
          margin: 20, color: Colors.red.shade700),
      "排行榜",
      () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RankingsScreen()),
        );
      },
    );

    append(
      buildSvg('lib/assets/random.svg', imageSize, imageSize,
          margin: 20, color: Colors.orangeAccent.shade700),
      "随机本子",
      () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RandomComicsScreen()),
        );
      },
    );

    append(
      buildSvg('lib/assets/gamepad.svg', imageSize, imageSize,
          margin: 20, color: Colors.blue.shade500),
      "游戏专区",
      () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GamesScreen()),
        );
      },
    );

    return list;
  }

  void _navigateToCategory(String? categoryTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComicsScreen(category: categoryTitle),
      ),
    );
  }
}
