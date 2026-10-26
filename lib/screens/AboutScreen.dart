import 'package:pikapika/i18.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pikapika/basic/Cross.dart';
import 'package:pikapika/basic/config/Version.dart';
import 'package:pikapika/screens/components/Badge.dart';

import 'components/ListView.dart';
import 'components/RightClickPop.dart';

// 关于
class AboutScreen extends StatefulWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  @override
  void initState() {
    versionEvent.subscribe(_onVersion);
    super.initState();
  }

  @override
  void dispose() {
    versionEvent.unsubscribe(_onVersion);
    super.dispose();
  }

  void _onVersion(dynamic a) {
    setState(() {});
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
    var size = MediaQuery.of(context).size;
    var min = size.width < size.height ? size.width : size.height;
    var _currentVersion = currentVersion();
    var _latestVersion = latestVersion();
    var _latestVersionInfo = latestVersionInfo();
    var _dirty = dirtyVersion();
    return Scaffold(
      appBar: AppBar(
        title: Text(tr("screen.about.title")),
      ),
      body: PikaListView(
        children: [
          Container(height: 20),
          SizedBox(
            width: min / 2,
            height: min / 2,
            child: Center(
              child:
              //  isPro ?
                   SvgPicture.asset(
                      'lib/assets/github.svg',
                      width: min / 3,
                      height: min / 3,
                      color: Colors.grey.shade500,
                    )
                  // : SizedBox(
                  //     width: min / 3,
                  //     height: min / 3,
                  //   )
                    ,
            ),
          ),
          Container(height: 20),
          const Divider(),
          Container(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr("screen.about.version") + " : $_currentVersion",
                  style: const TextStyle(
                    height: 1.3,
                  ),
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: tr("screen.about.check_update") + " : "),
                      ...(_dirty
                          ? _buildDirty()
                          : _buildNewVersion(_latestVersion)),
                    ],
                  ),
                ),
                _buildNewVersionInfo(_latestVersionInfo),
              ],
            ),
          ),
          const Divider(),
          Container(
            padding: const EdgeInsets.all(20),
            child: SelectableText(
              tr("screen.about.tips"),
              style: const TextStyle(
                height: 1.3,
              ),
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  List<InlineSpan> _buildNewVersion(String? latestVersion) {
    // if (!isPro) {
    //   return [
    //     TextSpan(
    //       text: tr("screen.about.download_new_version"),
    //     )
    //   ];
    // }
    if (latestVersion != null) {
      return [
        WidgetSpan(
          child: Badged(
            child: Container(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                latestVersion,
                style: const TextStyle(height: 1.3),
              ),
            ),
            badge: "1",
          ),
        ),
        const TextSpan(text: "  "),
        TextSpan(
          text: "去下载",
          style: TextStyle(
            height: 1.3,
            color: Theme.of(context).colorScheme.primary,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = _openRelease,
        ),
      ];
    }
    return [
      TextSpan(
          text: tr("screen.about.no_new_version"),
          style: const TextStyle(height: 1.3)),
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          padding: const EdgeInsets.all(4),
          margin: const EdgeInsets.only(left: 3, right: 3),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
      ),
      TextSpan(
        text: tr("screen.about.check_update"),
        style: TextStyle(
          height: 1.3,
          color: Theme.of(context).colorScheme.primary,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => manualCheckNewVersion(context),
      ),
    ];
  }

  List<InlineSpan> _buildDirty() {
    return [
      TextSpan(
        text: tr("screen.about.download_release_version"),
        style: TextStyle(
          height: 1.3,
          color: Theme.of(context).colorScheme.primary,
        ),
        recognizer: TapGestureRecognizer()..onTap = _openRelease,
      )
    ];
  }

  Future _openRelease() async {
    var url = downloadUrl();
    if (url != null && url.isNotEmpty) {
      await openUrl(url);
    }
  }

  Widget _buildNewVersionInfo(String? latestVersionInfo) {
    if (latestVersion() == null) {
      return const SizedBox.shrink();
    }
    if (latestVersionInfo == null || latestVersionInfo.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Text(tr("screen.about.update_content") + ":"),
        Container(
          padding: const EdgeInsets.all(15),
          child: Text(
            latestVersionInfo,
            style: const TextStyle(),
          ),
        ),
      ],
    );
  }
}
