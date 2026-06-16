import 'package:flutter/material.dart';
import 'package:pikapika/i18.dart';
import 'package:pikapika/basic/Common.dart';
import 'package:pikapika/basic/config/HideOnlineFavorite.dart';
import 'package:pikapika/basic/config/HiddenFdIcon.dart';
import 'package:pikapika/basic/config/TagFavorite.dart';
import 'package:pikapika/screens/TagFavoriteScreen.dart';
import 'package:pikapika/basic/config/Version.dart';
import 'package:pikapika/screens/AboutScreen.dart';
import 'package:pikapika/screens/AccountScreen.dart';
import 'package:pikapika/screens/DownloadListScreen.dart';
import 'package:pikapika/screens/FavouritePaperScreen.dart';
import 'package:pikapika/screens/LocalFavoriteScreen.dart';
import 'package:pikapika/screens/ProScreen.dart';
import 'package:pikapika/screens/ViewLogsScreen.dart';
import 'package:pikapika/basic/Method.dart';
import 'package:pikapika/basic/config/WebDav.dart';
import 'package:pikapika/screens/components/RecommendLinksPanel.dart';

import '../basic/config/IconLoading.dart';
import '../basic/config/IsPro.dart';
import 'SettingsScreen.dart';
import 'components/Badge.dart';
import 'components/UserProfileCard.dart';

// 个人空间页面
class SpaceScreen extends StatefulWidget {
  const SpaceScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SpaceScreenState();
}

class _SpaceScreenState extends State<SpaceScreen> {
  @override
  void initState() {
    versionEvent.subscribe(_onEvent);
    proEvent.subscribe(_onEvent);
    hiddenFdIconEvent.subscribe(_onEvent);
    useLocalFavoriteEvent.subscribe(_onEvent);
    hideOnlineFavoriteEvent.subscribe(_onEvent);
    tagFavoriteEnableEvent.subscribe(_onEvent);
    super.initState();
  }

  @override
  void dispose() {
    versionEvent.unsubscribe(_onEvent);
    proEvent.unsubscribe(_onEvent);
    hiddenFdIconEvent.unsubscribe(_onEvent);
    useLocalFavoriteEvent.unsubscribe(_onEvent);
    hideOnlineFavoriteEvent.unsubscribe(_onEvent);
    tagFavoriteEnableEvent.unsubscribe(_onEvent);
    super.dispose();
  }

  void _onEvent(dynamic a) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('screen.space.title')),
        actions: [
          IconButton(
            onPressed: () async {
              bool result = await confirmDialog(context,
                  tr('screen.space.logout'), tr('screen.space.logout_confirm'));
              if (result) {
                await method.clearToken();
                await method.setPassword("");
                Navigator.pushReplacement(
                  context,
                  mixRoute(builder: (context) => const AccountScreen()),
                );
              }
            },
            icon: const Icon(Icons.exit_to_app),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                mixRoute(builder: (context) => const AboutScreen()),
              );
            },
            icon: Badged(
              child: const Icon(Icons.info_outline),
              badge: latestVersion() == null ? null : "1",
            ),
          ),
          ...hiddenFdIcon
              ? []
              : [
                  IconButton(
                    onPressed: () {
                      Navigator.of(context)
                          .push(mixRoute(builder: (BuildContext context) {
                        return const ProScreen();
                      }));
                    },
                    icon: Icon(
                      isPro ? Icons.offline_bolt : Icons.offline_bolt_outlined,
                    ),
                  ),
                ],
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                mixRoute(builder: (context) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: ListView(
        children: [
          const Divider(),
          const UserProfileCard(),
          const Divider(),
          if (!hideOnlineFavorite) ...[
            ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  mixRoute(builder: (context) => const FavouritePaperScreen()),
                );
              },
              title: Text(tr('screen.space.my_favourites')),
            ),
            const Divider(),
          ],
          if (useLocalFavorite) ...[
            ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  mixRoute(builder: (context) => const LocalFavoriteScreen()),
                );
              },
              title: Text(tr('local_favorite.title')),
            ),
            const Divider(),
          ],
          if (tagFavoriteEnable) ...[
            ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  mixRoute(builder: (context) => const TagFavoriteScreen()),
                );
              },
              title: Text(tr('tag_favorite.title')),
            ),
            const Divider(),
          ],
          ListTile(
            onTap: () {
              Navigator.push(
                context,
                mixRoute(builder: (context) => const ViewLogsScreen()),
              );
            },
            title: Text(tr('screen.space.view_history')),
          ),
          const Divider(),
          ListTile(
            onTap: () {
              Navigator.push(
                context,
                mixRoute(builder: (context) => const DownloadListScreen()),
              );
            },
            title: Text(tr('screen.space.my_downloads')),
          ),
          const Divider(),
          const RecommendLinksPanel(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          ),
        ],
      ),
    );
  }
}
