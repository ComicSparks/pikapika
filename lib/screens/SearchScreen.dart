import 'package:flutter/material.dart';
import 'package:flutter_search_bar/flutter_search_bar.dart';
import 'package:pikapi/basic/Common.dart';
import 'package:pikapi/basic/store/Categories.dart';
import 'package:pikapi/basic/config/ListLayout.dart';
import 'package:pikapi/basic/Pica.dart';
import '../basic/Entities.dart';
import 'components/ComicPager.dart';

class SearchScreen extends StatefulWidget {
  final String keyword;
  final String? category;

  const SearchScreen({
    Key? key,
    required this.keyword,
    this.category,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late TextEditingController _textEditController =
      TextEditingController(text: widget.keyword);
  late SearchBar _searchBar = SearchBar(
    hintText: '搜索 ${categoryTitle(widget.category)}',
    controller: _textEditController,
    inBar: false,
    setState: setState,
    onSubmitted: (value) {
      if (value.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SearchScreen(
              keyword: value,
              category: widget.category,
            ),
          ),
        );
      }
    },
    buildDefaultAppBar: (BuildContext context) {
      return AppBar(
        title: Text("${categoryTitle(widget.category)} ${widget.keyword}"),
        actions: [
          chooseLayoutAction(context),
          _chooseCategoryAction(),
          _searchBar.getSearchAction(context),
        ],
      );
    },
  );

  Widget _chooseCategoryAction() => IconButton(
        onPressed: () async {
          String? category = await chooseListDialog(context, '请选择分类', [
            categoryTitle(null),
            ...storedCategories,
          ]);
          if (category != null) {
            if (category == categoryTitle(null)) {
              category = null;
            }
            Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) {
                return SearchScreen(
                  category: category,
                  keyword: widget.keyword,
                );
              },
            ));
          }
        },
        icon: Icon(Icons.category),
      );

  Future<ComicsPage> _fetch(String _currentSort, int _currentPage) {
    if (widget.category == null) {
      return pica.searchComics(widget.keyword, _currentSort, _currentPage);
    } else {
      return pica.searchComicsInCategories(
        widget.keyword,
        _currentSort,
        _currentPage,
        [widget.category!],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _searchBar.build(context),
      body: ComicPager(
        fetchPage: _fetch,
      ),
    );
  }
}
