import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:pikapika/basic/config/Address.dart';
import 'package:pikapika/basic/config/AndroidDisplayMode.dart';
import 'package:pikapika/basic/config/AndroidSecureFlag.dart';
import 'package:pikapika/basic/config/AppOrientation.dart';
import 'package:pikapika/basic/config/Authentication.dart';
import 'package:pikapika/basic/config/AutoClean.dart';
import 'package:pikapika/basic/config/AutoDeleteDownloadOnUnfavorite.dart';
import 'package:pikapika/basic/config/AutoDownloadOnFavorite.dart';
import 'package:pikapika/basic/config/DisableAutoDownloadOnMobile.dart';
import 'package:pikapika/basic/config/AutoFullScreen.dart';
import 'package:pikapika/basic/config/AutoFullScreenOnForward.dart';
import 'package:pikapika/basic/config/CategoriesColumnCount.dart';
import 'package:pikapika/basic/config/ChooserRoot.dart';
import 'package:pikapika/basic/config/ContentFailedReloadAction.dart';
import 'package:pikapika/basic/config/CopySkipConfirm.dart';
import 'package:pikapika/basic/config/DragRegionLock.dart';
import 'package:pikapika/basic/config/GestureSpeed.dart';
import 'package:pikapika/basic/config/DownloadAndExportPath.dart';
import 'package:pikapika/basic/config/DownloadThreadCount.dart';
import 'package:pikapika/basic/config/EBookScrolling.dart';
import 'package:pikapika/basic/config/EBookScrollingRange.dart';
import 'package:pikapika/basic/config/EBookScrollingTrigger.dart';
import 'package:pikapika/basic/config/FullScreenAction.dart';
import 'package:pikapika/basic/config/FullScreenUI.dart';
import 'package:pikapika/basic/config/HiddenSearchPersion.dart';
import 'package:pikapika/basic/config/HiddenSubIcon.dart';
import 'package:pikapika/basic/config/IgnoreInfoHistory.dart';
import 'package:pikapika/basic/config/ImageAddress.dart';
import 'package:pikapika/basic/config/ImageFilter.dart';
import 'package:pikapika/basic/config/KeyboardController.dart';
import 'package:pikapika/basic/config/LocalHistorySync.dart';
import 'package:pikapika/basic/config/NoAnimation.dart';
import 'package:pikapika/basic/config/PagerAction.dart';
import 'package:pikapika/basic/config/Platform.dart';
import 'package:pikapika/basic/config/Proxy.dart';
import 'package:pikapika/basic/config/Quality.dart';
import 'package:pikapika/basic/config/ReaderDirection.dart';
import 'package:pikapika/basic/config/ReaderSliderPosition.dart';
import 'package:pikapika/basic/config/ReaderType.dart';
import 'package:pikapika/basic/config/RecommendLinks.dart';
import 'package:pikapika/basic/config/ShadowCategories.dart';
import 'package:pikapika/basic/config/ShowCommentAtDownload.dart';
import 'package:pikapika/basic/config/TagFavorite.dart';
import 'package:pikapika/basic/config/Themes.dart';
import 'package:pikapika/basic/Method.dart';
import 'package:pikapika/basic/config/ListLayout.dart';
import 'package:pikapika/basic/config/TimeOffsetHour.dart';
import 'package:pikapika/basic/config/TimeoutLock.dart';
import 'package:pikapika/basic/config/UseApiLoadImage.dart';
import 'package:pikapika/basic/config/UsingRightClickPop.dart';
import 'package:pikapika/basic/config/Version.dart';
import 'package:pikapika/basic/config/VolumeController.dart';
import 'package:pikapika/basic/config/ShadowCategoriesMode.dart';
import 'package:pikapika/basic/config/WillPopNotice.dart';
import 'package:pikapika/basic/config/passed.dart';
import 'package:pikapika/screens/AccessKeyReplaceScreen.dart';
import 'package:pikapika/screens/ComicInfoScreen.dart';
import 'package:pikapika/screens/PkzArchiveScreen.dart';
import 'package:pikapika/screens/calculator_screen.dart';
import 'package:pikapika/screens/components/ContentLoading.dart';
import 'package:uni_links/uni_links.dart';
import 'package:uri_to_file/uri_to_file.dart';
import '../basic/config/CategoriesSort.dart';
import '../basic/config/CopyFullName.dart';
import '../basic/config/CopyFullNameTemplate.dart';
import '../basic/config/DownloadCachePath.dart';
import '../basic/config/ExportPath.dart';
import '../basic/config/ExportRename.dart';
import '../basic/config/HiddenFdIcon.dart';
import '../basic/config/HiddenViewed.dart';
import '../basic/config/HiddenWords.dart';
import '../basic/config/HideOnlineFavorite.dart';
import '../basic/config/IconLoading.dart';
import '../basic/config/IgnoreUpgradeConfirm.dart';
import '../basic/config/IsPro.dart';
import '../basic/config/ReaderBackgroundColor.dart';
import '../basic/config/ReaderScrollByScreenPercentage.dart';
import '../basic/config/WebToonScrollMode.dart';
import '../basic/config/ReaderZoomScale.dart';
import '../basic/config/ReaderTwoPageDirection.dart';
import '../basic/config/ThreeKeepRight.dart';
import '../basic/config/VolumeNextChapter.dart';
import '../basic/config/WebDav.dart';
import 'AccountScreen.dart';
import 'AppScreen.dart';
import 'DownloadOnlyImportScreen.dart';

// 初始化界面
class InitScreen extends StatefulWidget {
  const InitScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _InitScreenState();
}

class _InitScreenState extends State<InitScreen> {
  var _authenticating = false;
  Widget? _loadPic;

  Widget _defaultLoadingPic() {
    return const ContentLoading(label: "加载中");
  }

  @override
  initState() {
    _init();
    super.initState();
  }

  Future<dynamic> _init() async {
    var dataLocal = await method.dataLocal();
    print("dataLocal: $dataLocal");
    if (await File(p.join(dataLocal, "startup_pic")).exists()) {
      _loadPic = Image.file(
        File(p.join(dataLocal, "startup_pic")),
        fit: BoxFit.contain,
      );
    } else {
      _loadPic = _defaultLoadingPic();
    }
    setState(() {});
    // 初始化配置文件
    await initPlatform(); // 必须第一个初始化, 加载设备信息
    await initAutoClean();
    await initAppOrientation();
    await initAddress();
    await initImageAddress();
    await initProxy();
    await initQuality();
    await initFont();
    await initTheme();
    await initFullScreenUI();
    await initListLayout();
    await initReaderType();
    await initReaderDirection();
    await initReaderSliderPosition();
    await initAutoFullScreen();
    await initAutoFullScreenOnForward();
    await initFullScreenAction();
    await initPagerAction();
    await initShadowCategoriesMode();
    await initShadowCategories();
    await initIconLoading();
    await initCategoriesColumnCount();
    await initContentFailedReloadAction();
    await initVolumeController();
    await initKeyboardController();
    await initAndroidDisplayMode();
    await initChooserRoot();
    await initExportPath();
    await initTimeZone();
    await initDownloadAndExportPath();
    await initAndroidSecureFlag();
    await initDownloadThreadCount();
    await initNoAnimation();
    await initDragRegionLock();
    await initGestureSpeed();
    await initExportRename();
    await initVersion();
    await initUsingRightClickPop();
    await initAuthentication();
    await reloadIsPro();
    await initIgnoreUpgradeConfirm();
    await initWillPopNotice();
    await initHiddenFdIcon();
    await initShowCommentAtDownload();
    await initDownloadCachePath();
    await initUseApiLoadImage();
    await initWebDav();
    await initImageFilter();
    await initReaderBackgroundColor();
    await initEBookScrolling();
    await initEBookScrollingRange();
    await initEBookScrollingTrigger();
    await initVolumeNextChapter();
    await initCopySkipConfirm();
    await initCopyFullName();
    await initCategoriesSort();
    await initLocalHistorySync();
    await initHideOnlineFavorite();
    await initHiddenViewed();
    await initHiddenSubIcon();
    await initHiddenSearchPersion();
    await initLockTimeOut();
    await initReaderTwoPageDirection();
    await initHiddenWords();
    await initTagFavorite();
    await initReaderScrollByScreenPercentage();
    await initWebToonScrollMode();
    await initReaderZoomScale();
    await initIgnoreInfoHistory();
    await initThreeKeepRight();
    await initCopyFullNameTemplate();
    await initAutoDownloadOnFavorite();
    await initDisableAutoDownloadOnMobile();
    await initAutoDeleteDownloadOnUnfavorite();
    await initPassed();
    await initRecommendLinks();
    if (!currentPassed()) {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (BuildContext context) {
          return const CalculatorScreen();
        },
      ));
      return;
    }
    autoCheckNewVersion();
    String? initUrl;
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        initUrl = (await getInitialUri())?.toString();
        // Use the uri and warn the user, if it is not correct,
        // but keep in mind it could be `null`.
      } on FormatException {
        // Handle exception by warning the user their action did not succeed
        // return?
      }
    }
    if (initUrl != null) {
      var parsed = Uri.parse(initUrl!);
      if (RegExp(r"^pika://access_key/([0-9A-z:\-]+)/$")
          .allMatches(initUrl!)
          .isNotEmpty) {
        String accessKey = RegExp(r"^pika://access_key/([0-9A-z:\-]+)/$")
            .allMatches(initUrl!)
            .first
            .group(1)!;
        Navigator.of(context).pushReplacement(mixRoute(
          builder: (BuildContext context) =>
              AccessKeyReplaceScreen(accessKey: accessKey),
        ));
        return;
      } else if (RegExp(r"^pika://comic/([0-9A-z]+)/$")
          .allMatches(initUrl!)
          .isNotEmpty) {
        String comicId = RegExp(r"^pika://comic/([0-9A-z]+)/$")
            .allMatches(initUrl!)
            .first
            .group(1)!;
        Navigator.of(context).pushReplacement(mixRoute(
          builder: (BuildContext context) =>
              ComicInfoScreen(comicId: comicId, holdPkz: true),
        ));
        return;
      } else if (RegExp(r"^https?://pika/comic/([0-9A-z]+)/$")
          .allMatches(initUrl!)
          .isNotEmpty) {
        String comicId = RegExp(r"^https?://pika/comic/([0-9A-z]+)/$")
            .allMatches(initUrl!)
            .first
            .group(1)!;
        Navigator.of(context).pushReplacement(mixRoute(
          builder: (BuildContext context) =>
              ComicInfoScreen(comicId: comicId, holdPkz: true),
        ));
        return;
      } else if (RegExp(r"^.*\.pkz$").allMatches(parsed.path).isNotEmpty) {
        File file = await toFile(initUrl!);
        Navigator.of(context).pushReplacement(mixRoute(
          builder: (BuildContext context) =>
              PkzArchiveScreen(pkzPath: file.path, holdPkz: true),
        ));
        return;
      } else if (RegExp(r"^.*\.((pki)|(zip))$")
          .allMatches(parsed.path)
          .isNotEmpty) {
        File file = await toFile(initUrl!);
        Navigator.of(context).pushReplacement(
          mixRoute(
            builder: (BuildContext context) =>
                DownloadOnlyImportScreen(path: file.path, holdPkz: true),
          ),
        );
        return;
      }
    }

    setState(() {
      _authenticating = currentAuthentication();
    });
    if (_authenticating) {
      _goAuthentication();
    } else {
      syncWebDavIfAuto(context);
      _goApplication();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_authenticating) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("身份验证"),
        ),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: MaterialButton(
              onPressed: () {
                _goAuthentication();
              },
              child:
                  const Text('您在之前使用APP时开启了身份验证, 请点这段文字进行身份核查, 核查通过后将会进入APP'),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * 4 / 5,
                maxHeight: constraints.maxHeight * 4 / 5,
              ),
              child: _loadPic ?? Container(),
            ),
          );
        },
      ),
    );
  }

  Future _goApplication() async {
    // 登录, 如果token失效重新登录, 网络不好的时候可能需要1分钟
    if (await method.preLogin()) {
      // 如果token或username+password有效则直接进入登录好的界面
      Navigator.pushReplacement(
        context,
        mixRoute(builder: (context) => const AppScreen()),
      );
    } else {
      // 否则跳转到登录页
      Navigator.pushReplacement(
        context,
        mixRoute(builder: (context) => const AccountScreen()),
      );
    }
  }

  Future _goAuthentication() async {
    if (await verifyAuthentication(context)) {
      _goApplication();
    }
  }
}
