import 'package:pikapika/i18.dart';
import 'package:flutter/material.dart';
import 'package:pikapika/basic/Method.dart';
import 'package:pikapika/screens/components/ComicList.dart';
import '../basic/Entities.dart';
import 'components/ComicPager.dart';
import 'components/Common.dart';
import 'components/GoDownloadSelect.dart';
import 'components/RightClickPop.dart';

// 收藏的漫画
class FavouritePaperScreen extends StatefulWidget {
  const FavouritePaperScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _FavouritePaperScreen();
}

class _FavouritePaperScreen extends State<FavouritePaperScreen> {
  late final _comicListController = ComicListController();

  Future<ComicsPage> _fetch(String _currentSort, int _currentPage) {
    return method.favouriteComics(_currentSort, _currentPage);
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
    PreferredSizeWidget appBar = AppBar(
      title: Text(tr('screen.favourite_paper.favourite')),
      actions: [
        commonPopMenu(
          context,
          setState: setState,
          comicListController: _comicListController,
        ),
      ],
    );
    if (_comicListController.selecting) {
      appBar = downAppBar(context, _comicListController, setState);
    }
    return WillPopScope(
      onWillPop: () async {
        if (_comicListController.selecting) {
          setState(() {
            _comicListController.selecting = false;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: appBar,
        body: ComicPager(
          fetchPage: _fetch,
          coll: true,
          comicListController: _comicListController,
        ),
      ),
    );
  }
}
