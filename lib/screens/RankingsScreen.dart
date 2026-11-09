import 'package:flutter/material.dart';
import 'package:pikapika/i18.dart';
import 'package:pikapika/basic/Entities.dart';
import 'package:pikapika/basic/Method.dart';
import 'package:pikapika/screens/components/Avatar.dart';
import 'package:pikapika/screens/components/ContentBuilder.dart';

import '../basic/Cross.dart';
import '../basic/Navigator.dart';
import '../basic/config/Address.dart';
import 'ComicsScreen.dart';
import 'components/ComicListBuilder.dart';
import 'components/Common.dart';
import 'components/FitButton.dart';
import 'components/RightClickPop.dart';

// 排行榜
class RankingsScreen extends StatelessWidget {
  const RankingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return rightClickPop(
      child: buildScreen(context),
      context: context,
      canPop: true,
    );
  }

  Widget buildScreen(BuildContext context) {
    var theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('screen.rankings.title')),
        actions: [
          commonPopMenu(context),
          addressPopMenu(context),
        ],
      ),
      body: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            Container(
              height: 40,
              color: theme.colorScheme.secondary.withOpacity(.025),
              child: TabBar(
                indicatorColor: theme.colorScheme.secondary,
                labelColor: theme.colorScheme.secondary,
                tabs: [
                  Tab(text: tr('screen.rankings.day')),
                  Tab(text: tr('screen.rankings.week')),
                  Tab(text: tr('screen.rankings.month')),
                  Tab(text: tr('screen.rankings.knight')),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _Leaderboard("H24"),
                  _Leaderboard("D7"),
                  _Leaderboard("D30"),
                  _KnightLeaderBoard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Leaderboard extends StatefulWidget {
  final String type;

  const _Leaderboard(this.type);

  @override
  State<StatefulWidget> createState() => _LeaderboardState();
}

class _LeaderboardState extends State<_Leaderboard> {
  @override
  Widget build(BuildContext context) {
    return ComicListBuilder(() => method.leaderboard(widget.type));
  }
}

class _KnightLeaderBoard extends StatefulWidget {
  const _KnightLeaderBoard();

  @override
  State<StatefulWidget> createState() => _KnightLeaderBoardState();
}

class _KnightLeaderBoardState extends State<_KnightLeaderBoard> {
  Future<List<Knight>> _future = method.leaderboardOfKnight();
  Key _key = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return ContentBuilder(
      key: _key,
      future: _future,
      onRefresh: () async {
        setState(() {
          _future = method.leaderboardOfKnight();
          _key = UniqueKey();
        });
      },
      successBuilder: (
        BuildContext context,
        AsyncSnapshot<List<Knight>> snapshot,
      ) {
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _future = method.leaderboardOfKnight();
            });
          },
          child: ListView(children: [
            ...snapshot.requireData.map(_knightCard).toList(),
            SizedBox(
              height: 80,
              child: FitButton(
                text: tr('screen.rankings.refresh'),
                onPressed: () async {
                  setState(() {
                    _future = method.leaderboardOfKnight();
                  });
                },
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _knightCard(Knight e) {
    final theme = Theme.of(context);
    var nameStyle = const TextStyle(fontWeight: FontWeight.bold);
    var levelStyle = TextStyle(
        fontSize: 12, color: theme.colorScheme.secondary.withOpacity(.8));
    var connectStyle =
        TextStyle(color: theme.textTheme.bodyLarge?.color?.withOpacity(.8));
    var datetimeStyle = TextStyle(
        color: theme.textTheme.bodyLarge?.color?.withOpacity(.6), fontSize: 12);

    final card = Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            width: .25,
            style: BorderStyle.solid,
            color: Colors.grey.shade500.withOpacity(.5),
          ),
          bottom: BorderSide(
            width: .25,
            style: BorderStyle.solid,
            color: Colors.grey.shade500.withOpacity(.5),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Avatar(e.avatar),
          Container(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(e.name, style: nameStyle),
                    Expanded(child: Container()),
                    Text(
                      "${e.comicsUploaded} ${tr('screen.rankings.comics_count')}",
                      style: datetimeStyle,
                    ),
                  ],
                ),
                Text("Lv. ${e.level} (${e.title})", style: levelStyle),
                Text(e.slogan ?? "", style: connectStyle),
              ],
            ),
          ),
        ],
      ),
    );

    return InkWell(
      onTap: () {
        navPushOrReplace(
          context,
          (context) => ComicsScreen(
            creatorId: e.id,
            creatorName: e.name,
          ),
        );
      },
      onLongPress: () {
        confirmCopy(
          context,
          e.name,
        );
      },
      child: card,
    );
  }
}
