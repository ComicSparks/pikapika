import 'package:pikapika/i18.dart';
import 'package:flutter/material.dart';
import 'package:pikapika/basic/Method.dart';
import 'package:pikapika/screens/components/ContentError.dart';
import 'package:pikapika/screens/components/ListView.dart';

import '../basic/Entities.dart';
import '../basic/config/CategoriesColumnCount.dart';
import '../basic/config/CategoriesHidden.dart';
import 'CategoriesScreen.dart';
import 'components/Images.dart';

class CategoriesHiddenScreen extends StatefulWidget {
  const CategoriesHiddenScreen({Key? key}) : super(key: key);

  @override
  _CategoriesHiddenScreenState createState() => _CategoriesHiddenScreenState();
}

class _CategoriesHiddenScreenState extends State<CategoriesHiddenScreen> {
  late Key _key = UniqueKey();
  late Future<List<Category>> _future = method.categories();

  _reload() {
    setState(() {
      _key = UniqueKey();
      _future = method.categories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      key: _key,
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<List<Category>> snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text(tr('screen.categories_hidden.title')),
            ),
            body: ContentError(
              error: snapshot.error,
              stackTrace: snapshot.stackTrace,
              onRefresh: () async {
                _reload();
              },
            ),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(
              title: Text(tr('screen.categories_hidden.title')),
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        return CategoriesHiddenPanel(snapshot.requireData);
      },
    );
  }
}

class CategoriesHiddenPanel extends StatefulWidget {
  final List<Category> requireData;

  const CategoriesHiddenPanel(this.requireData, {Key? key}) : super(key: key);

  @override
  _CategoriesHiddenPanelState createState() => _CategoriesHiddenPanelState();
}

class _CategoriesHiddenPanelState extends State<CategoriesHiddenPanel> {
  final List<String> _categoriesHidden = [];

  @override
  void initState() {
    _categoriesHidden.addAll(getCategoriesHidden());
    super.initState();
  }

  _switch(String value) {
    setState(() {
      if (_categoriesHidden.contains(value)) {
        _categoriesHidden.remove(value);
      } else {
        _categoriesHidden.add(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
    items.addAll(_buildCategories(widget.requireData, imageSize));
    List<Widget> wrapItems = _wrapItems(items, blockSize, imageRs, imageSize);
    //
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('screen.categories_hidden.title')),
        actions: [
          _saveIcon(),
        ],
      ),
      body: PikaListView(
        children: [
          Container(height: 20),
          Wrap(
            runSpacing: 20,
            alignment: WrapAlignment.spaceAround,
            children: wrapItems,
          ),
          Container(height: 20),
        ],
      ),
    );
  }

  List<Widget> _wrapItems(
    List<CategoriesItem> items,
    double blockSize,
    double imageRs,
    double imageSize,
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
                Stack(
                  children: [
                    Card(
                      elevation: .5,
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.all(Radius.circular(imageRs)),
                        child: widget,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.all(Radius.circular(imageRs)),
                      ),
                    ),
                    if (_categoriesHidden.contains(title))
                      Container(
                        width: imageSize,
                        height: imageSize,
                        color: Colors.black.withOpacity(.6),
                        margin: const EdgeInsets.all(4.0),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.visibility_off,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                  ],
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
      () => _switch(tr('categories.all')),
    ));

    items.add(CategoriesItem(
      Icon(
        Icons.recommend_outlined,
        size: imageSize,
        color: Colors.grey,
      ),
      tr('categories.recommend'),
      () => _switch(tr('categories.recommend')),
    ));

    for (var i = 0; i < cList.length; i++) {
      var c = cList[i];
      if (c.isWeb) continue;
      items.add(CategoriesItem(
        RemoteImage(
          fileServer: c.thumb.fileServer,
          path: c.thumb.path,
          width: imageSize,
          height: imageSize,
        ),
        c.title,
        () => _switch(c.title),
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
      () => _switch(tr('categories.rankings')),
    ));

    items.add(CategoriesItem(
      buildSvg('lib/assets/random.svg', imageSize, imageSize,
          margin: 20, color: Colors.orangeAccent.shade700),
      tr('categories.random'),
      () => _switch(tr('categories.random')),
    ));

    items.add(CategoriesItem(
      buildSvg('lib/assets/gamepad.svg', imageSize, imageSize,
          margin: 20, color: Colors.blue.shade500),
      tr('categories.game'),
      () => _switch(tr('categories.game')),
    ));

    return items;
  }

  Widget _saveIcon() {
    return IconButton(
      onPressed: () async {
        await saveCategoriesHidden(_categoriesHidden);
        Navigator.of(context).pop();
      },
      icon: const Icon(Icons.save),
    );
  }
}
