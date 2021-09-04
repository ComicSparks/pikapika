import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pikapi/basic/Entities.dart';
import 'package:pikapi/basic/Pica.dart';
import 'package:pikapi/screens/components/ContentBuilder.dart';

import 'GameInfoScreen.dart';
import 'components/Images.dart';

class GamesScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  int _currentPage = 1;
  late Future<GamePage> _future = _loadPage();

  Future<GamePage> _loadPage() {
    return pica.games(_currentPage);
  }

  void _onPageChange(int number) {
    setState(() {
      _currentPage = number;
      _future = _loadPage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('游戏'),
      ),
      body: ContentBuilder(
        future: _future,
        onRefresh: _loadPage,
        successBuilder:
            (BuildContext context, AsyncSnapshot<GamePage> snapshot) {
          var page = snapshot.data!;

          List<Wrap> wraps = [];
          GameCard? gameCard;
          page.docs.forEach((element) {
            if (gameCard == null) {
              gameCard = GameCard(element);
            } else {
              wraps.add(Wrap(
                children: [GameCard(element), gameCard!],
                alignment: WrapAlignment.center,
              ));
              gameCard = null;
            }
          });
          if (gameCard != null) {
            wraps.add(Wrap(
              children: [gameCard!],
              alignment: WrapAlignment.center,
            ));
          }
          return Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(40),
              child: Container(
                padding: EdgeInsets.only(left: 10, right: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      width: .5,
                      style: BorderStyle.solid,
                      color: Colors.grey[200]!,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        _textEditController.clear();
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              content: Card(
                                child: Container(
                                  child: TextField(
                                    controller: _textEditController,
                                    decoration: new InputDecoration(
                                      labelText: "请输入页数：",
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: <TextInputFormatter>[
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'\d+')),
                                    ],
                                  ),
                                ),
                              ),
                              actions: <Widget>[
                                MaterialButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text('取消'),
                                ),
                                MaterialButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    var text = _textEditController.text;
                                    if (text.length == 0 || text.length > 5) {
                                      return;
                                    }
                                    var num = int.parse(text);
                                    if (num == 0 || num > page.pages) {
                                      return;
                                    }
                                    _onPageChange(num);
                                  },
                                  child: Text('确定'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Row(
                        children: [
                          Text("第 ${page.page} / ${page.pages} 页"),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        MaterialButton(
                          minWidth: 0,
                          onPressed: () {
                            if (page.page > 1) {
                              _onPageChange(page.page - 1);
                            }
                          },
                          child: Text('上一页'),
                        ),
                        MaterialButton(
                          minWidth: 0,
                          onPressed: () {
                            if (page.page < page.pages) {
                              _onPageChange(page.page + 1);
                            }
                          },
                          child: Text('下一页'),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
            body: ListView(
              children: [
                ...wraps,
                ...page.page < page.pages
                    ? [
                        MaterialButton(
                          onPressed: () {
                            _onPageChange(page.page + 1);
                          },
                          child: Container(
                            padding: EdgeInsets.only(top: 30, bottom: 30),
                            child: Text('下一页'),
                          ),
                        ),
                      ]
                    : [],
              ],
            ),
          );
        },
      ),
    );
  }
}

class GameCard extends StatelessWidget {
  final GameSimple info;

  GameCard(this.info);

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var textColor = theme.textTheme.bodyText1!.color!;
    var categoriesStyle = TextStyle(
      fontSize: 13,
      color: textColor.withAlpha(0xCC),
    );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // data.width/data.height = width/ ?
        //  data.width * ? = width * data.height
        // ? = width * data.height / data.width
        var size = MediaQuery.of(context).size;
        var min = size.width < size.height ? size.width : size.height;
        var imageWidth = (min - 45 - 40) / 2;
        var imageHeight = imageWidth * 280 / 500;
        return Card(
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => GameInfoScreen(info.id)),
              );
            },
            child: Container(
              padding: EdgeInsets.all(10),
              child: Container(
                width: imageWidth,
                child: Column(
                  children: [
                    RemoteImage(
                      width: imageWidth,
                      height: imageHeight,
                      fileServer: info.icon.fileServer,
                      path: info.icon.path,
                    ),
                    Text(
                      info.title + '\n',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(height: 1.4),
                      strutStyle: StrutStyle(height: 1.4),
                    ),
                    Text(
                      info.publisher,
                      style: categoriesStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

final TextEditingController _textEditController =
    TextEditingController(text: '');
