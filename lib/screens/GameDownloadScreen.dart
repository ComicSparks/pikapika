import 'package:flutter/material.dart';
import 'package:pikapi/basic/Cross.dart';
import 'package:pikapi/basic/Entities.dart';
import 'package:pikapi/basic/Pica.dart';
import 'package:pikapi/screens/components/ItemBuilder.dart';

import 'components/GameTitleCard.dart';

class GameDownloadScreen extends StatefulWidget {
  final GameInfo info;

  const GameDownloadScreen(this.info, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _GameDownloadScreenState();
}

class _GameDownloadScreenState extends State<GameDownloadScreen> {
  late Future<List<String>> _future =
      pica.downloadGame("${widget.info.androidLinks[0]}");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("下载 - ${widget.info.title}"),
      ),
      body: ListView(
        children: [
          GameTitleCard(widget.info),
          ItemBuilder(
            future: _future,
            onRefresh: () async => setState(() => _future =
                pica.downloadGame("${widget.info.androidLinks[0]}")),
            successBuilder:
                (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
              return Container(
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(30),
                      child: Text('获取到下载链接, 您只需要选择其中一个'),
                    ),
                    ...snapshot.data!.map((e) => _copyCard(e)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _copyCard(String string) {
    return InkWell(
      onTap: () {
        copyToClipBoard(context, string);
      },
      child: Row(
        children: [
          Expanded(
            child: Container(
              margin: EdgeInsets.all(10),
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade500,
                  width: .5,
                  style: BorderStyle.solid,
                ),
              ),
              child: Text(string),
            ),
          ),
        ],
      ),
    );
  }
}
