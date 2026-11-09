import 'package:pikapika/i18.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pikapika/basic/Entities.dart';
import 'package:pikapika/basic/Method.dart';
import 'package:pikapika/screens/components/ContentBuilder.dart';

import '../basic/config/IconLoading.dart';
import 'GameInfoScreen.dart';
import 'components/Images.dart';
import 'components/ListView.dart';
import 'components/RightClickPop.dart';

// 游戏列表
class GamesScreen extends StatefulWidget {
  const GamesScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  int _currentPage = 1;
  late Future<GamePage> _future = _loadPage();
  late Key _key = UniqueKey();

  Future<GamePage> _loadPage() {
    return method.games(_currentPage);
  }

  void _onPageChange(int number) {
    setState(() {
      _currentPage = number;
      _future = _loadPage();
      _key = UniqueKey();
    });
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
      appBar: AppBar(
        title: Text(tr('screen.games.title')),
      ),
      body: ContentBuilder(
        key: _key,
        future: _future,
        onRefresh: _loadPage,
        successBuilder:
            (BuildContext context, AsyncSnapshot<GamePage> snapshot) {
          var page = snapshot.data!;

          List<Wrap> wraps = [];
          GameCard? gameCard;
          for (var element in page.docs) {
            if (gameCard == null) {
              gameCard = GameCard(element);
            } else {
              wraps.add(Wrap(
                children: [GameCard(element), gameCard],
                alignment: WrapAlignment.center,
              ));
              gameCard = null;
            }
          }
          if (gameCard != null) {
            wraps.add(Wrap(
              children: [gameCard],
              alignment: WrapAlignment.center,
            ));
          }
          return Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(40),
              child: Container(
                padding: const EdgeInsets.only(left: 10, right: 10),
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
                                    child: TextField(
                                      controller: _textEditController,
                                      decoration: InputDecoration(
                                        labelText: tr("app.please_enter_page_number"),
                                      ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'\d+')),
                                  ],
                                ),
                              ),
                                                                actions: <Widget>[
                                    MaterialButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text(tr('app.cancel')),
                                    ),
                                    MaterialButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        var text = _textEditController.text;
                                        if (text.isEmpty || text.length > 5) {
                                          return;
                                        }
                                        var num = int.parse(text);
                                        if (num == 0 || num > page.pages) {
                                          return;
                                        }
                                        _onPageChange(num);
                                      },
                                      child: Text(tr('app.confirm')),
                                    ),
                                  ],
                            );
                          },
                        );
                      },
                                                child: Row(
                            children: [
                              Text("${tr('app.page')} ${page.page} / ${page.pages}"),
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
                          child: Text(tr('app.previous_page')),
                        ),
                        MaterialButton(
                          minWidth: 0,
                          onPressed: () {
                            if (page.page < page.pages) {
                              _onPageChange(page.page + 1);
                            }
                          },
                          child: Text(tr('app.next_page')),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
            body: PikaListView(
              children: [
                ...wraps,
                ...page.page < page.pages
                    ? [
                        MaterialButton(
                          onPressed: () {
                            _onPageChange(page.page + 1);
                          },
                          child: Container(
                            padding: const EdgeInsets.only(top: 30, bottom: 30),
                            child: Text(tr('screen.games.next_page')),
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

  const GameCard(this.info, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var textColor = theme.textTheme.bodyLarge!.color!;
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
                mixRoute(
                    builder: (context) => GameInfoScreen(info.id)),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              child: SizedBox(
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
                      style: const TextStyle(height: 1.4),
                      strutStyle: const StrutStyle(height: 1.4),
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
