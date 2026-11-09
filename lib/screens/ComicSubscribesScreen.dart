import 'package:pikapika/i18.dart';
import 'package:flutter/material.dart';
import 'package:pikapika/basic/Entities.dart';
import 'package:pikapika/basic/entity_convert.dart';
import 'package:pikapika/basic/Method.dart';
import 'package:pikapika/screens/components/ComicList.dart';
import 'package:pikapika/screens/components/CommonData.dart';
import 'package:pikapika/screens/components/ContentBuilder.dart';

import '../basic/config/Address.dart';
import 'components/Badge.dart';
import 'components/Common.dart';

class IntoComicSubscribesScreenButton extends StatefulWidget {
  const IntoComicSubscribesScreenButton({Key? key}) : super(key: key);

  @override
  State<IntoComicSubscribesScreenButton> createState() =>
      _IntoComicSubscribesScreenButtonState();
}

class _IntoComicSubscribesScreenButtonState
    extends State<IntoComicSubscribesScreenButton> {
  @override
  void initState() {
    super.initState();
    subscribedEvent.subscribe(_setState);
    _sync();
  }

  @override
  void dispose() {
    subscribedEvent.unsubscribe(_setState);
    super.dispose();
  }

  _setState(_) {
    setState(() {});
  }

  void _sync() async {
    await updateSubscribed();
  }

  @override
  Widget build(BuildContext context) {
    final count = allSubscribed.values.isEmpty
        ? 0
        : allSubscribed.values
            .map((e) => e.newEpCount)
            .reduce((value, element) => value + element);
    return Badged(
      badge: count == 0 ? null : count.toString(),
      child: IconButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ComicSubscribesScreen(),
            ),
          );
        },
        icon: const Icon(Icons.alarm),
      ),
    );
  }
}

class ComicSubscribesScreen extends StatefulWidget {
  const ComicSubscribesScreen({Key? key}) : super(key: key);

  @override
  State<ComicSubscribesScreen> createState() => _ComicSubscribesScreenState();
}

class _ComicSubscribesScreenState extends State<ComicSubscribesScreen> {
  @override
  void initState() {
    super.initState();
    subscribedEvent.subscribe(_setState);
  }

  @override
  void dispose() {
    subscribedEvent.unsubscribe(_setState);
    super.dispose();
  }

  void _setState(_) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('screen.comic_subscribes.update_reminder')),
        actions: [
          commonPopMenu(context),
          addressPopMenu(context),
          _popMenu(context),
        ],
      ),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final subs = allSubscribed.values.toList();
    List<ComicSimple> comicList = [];
    for (var comicSubscribe in subs) {
      comicList.add(comicSimpleFromSubscribe(comicSubscribe));
    }
    return ComicList(comicList);
  }
}

Widget _popMenu(BuildContext context) {
  return PopupMenuButton<int>(
    icon: const Icon(Icons.more_vert),
    itemBuilder: (BuildContext context) => <PopupMenuItem<int>>[
      PopupMenuItem<int>(
        value: 0,
        child: ListTile(
          leading: const Icon(Icons.share),
          title: Text(tr('screen.comic_subscribes.check_update')),
        ),
      ),
      PopupMenuItem<int>(
        value: 1,
        child: ListTile(
          leading: const Icon(Icons.image_search),
          title: Text(tr('screen.comic_subscribes.cancel_all_update_reminder')),
        ),
      ),
    ],
    onSelected: (int value) {
      switch (value) {
        case 0:
          updateSubscribedForce();
          break;
        case 1:
          removeAllSubscribed();
          break;
      }
    },
  );
}
