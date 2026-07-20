import 'dart:io';

import 'package:pikapika/i18.dart';
import 'package:flutter/material.dart';
import 'package:pikapika/basic/Common.dart';
import 'package:pikapika/basic/config/AndroidDisplayMode.dart';
import 'package:pikapika/basic/config/AndroidSecureFlag.dart';
import 'package:pikapika/basic/config/AutoClean.dart';
import 'package:pikapika/basic/config/AutoDeleteDownloadOnUnfavorite.dart';
import 'package:pikapika/basic/config/AutoDownloadOnFavorite.dart';
import 'package:pikapika/basic/config/DisableAutoDownloadOnMobile.dart';
import 'package:pikapika/basic/config/AutoFullScreen.dart';
import 'package:pikapika/basic/config/AutoFullScreenOnForward.dart';
import 'package:pikapika/basic/config/ChooserRoot.dart';
import 'package:pikapika/basic/config/ContentFailedReloadAction.dart';
import 'package:pikapika/basic/config/CopySkipConfirm.dart';
import 'package:pikapika/basic/config/DownloadAndExportPath.dart';
import 'package:pikapika/basic/config/DownloadThreadCount.dart';
import 'package:pikapika/basic/config/EBookScrollingRange.dart';
import 'package:pikapika/basic/config/EBookScrollingTrigger.dart';
import 'package:pikapika/basic/config/ExportRename.dart';
import 'package:pikapika/basic/config/FullScreenAction.dart';
import 'package:pikapika/basic/config/FullScreenUI.dart';
import 'package:pikapika/basic/config/HiddenSearchPersion.dart';
import 'package:pikapika/basic/config/IconLoading.dart';
import 'package:pikapika/basic/config/IgnoreUpgradeConfirm.dart';
import 'package:pikapika/basic/config/IsPro.dart';
import 'package:pikapika/basic/config/KeyboardController.dart';
import 'package:pikapika/basic/config/NoAnimation.dart';
import 'package:pikapika/basic/config/DragRegionLock.dart';
import 'package:pikapika/basic/config/GestureSpeed.dart';
import 'package:pikapika/basic/config/PagerAction.dart';
import 'package:pikapika/basic/config/Quality.dart';
import 'package:pikapika/basic/config/ReaderBackgroundColor.dart';
import 'package:pikapika/basic/config/ReaderDirection.dart';
import 'package:pikapika/basic/config/ReaderSliderPosition.dart';
import 'package:pikapika/basic/config/ReaderType.dart';
import 'package:pikapika/basic/config/ShadowCategories.dart';
import 'package:pikapika/basic/config/ShadowCategoriesMode.dart';
import 'package:pikapika/basic/config/ShowCommentAtDownload.dart';
import 'package:pikapika/basic/config/Themes.dart';
import 'package:pikapika/basic/config/TimeOffsetHour.dart';
import 'package:pikapika/basic/config/VolumeController.dart';
import 'package:pikapika/basic/config/VolumeNextChapter.dart';
import 'package:pikapika/screens/components/NetworkSetting.dart';
import 'package:pikapika/screens/components/RightClickPop.dart';

import '../basic/config/AppOrientation.dart';
import '../basic/config/Authentication.dart';
import '../basic/config/CategoriesColumnCount.dart';
import '../basic/config/CategoriesHidden.dart';
import '../basic/config/CategoriesSort.dart';
import '../basic/config/CopyFullName.dart';
import '../basic/config/CopyFullNameTemplate.dart';
import '../basic/config/DownloadCachePath.dart';
import '../basic/config/EBookScrolling.dart';
import '../basic/config/HiddenFdIcon.dart';
import '../basic/config/HiddenSubIcon.dart';
import '../basic/config/HiddenViewed.dart';
import '../basic/config/HiddenWords.dart';
import '../basic/config/HideOnlineFavorite.dart';
import '../basic/config/TagFavorite.dart';
import '../basic/config/IgnoreInfoHistory.dart';
import '../basic/config/ImageFilter.dart';
import '../basic/config/ReaderScrollByScreenPercentage.dart';
import '../basic/config/WebToonScrollMode.dart';
import '../basic/config/ReaderZoomScale.dart';
import '../basic/config/ReaderTwoPageDirection.dart';
import '../basic/config/StartupPic.dart';
import '../basic/config/ThreeKeepRight.dart';
import '../basic/config/TimeoutLock.dart';
import '../basic/config/UsingRightClickPop.dart';
import '../basic/config/WebDav.dart';
import '../basic/config/WillPopNotice.dart';
import '../basic/config/i18n.dart';
import 'CleanScreen.dart';
import 'MigrateScreen.dart';
import 'ModifyPasswordScreen.dart';
import 'ThemeScreen.dart';
import 'WebServerScreen.dart';

class SettingsScreen extends StatefulWidget {
  final bool hiddenAccountInfo;

  const SettingsScreen({Key? key, this.hiddenAccountInfo = false})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
        title: Text(tr('settings.settings')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ExpansionTile(
              leading: const Icon(Icons.ad_units),
              title: Text(tr('settings.interface')),
              children: [
                const Divider(),
                ...themeWidgets(context, setState),
                appOrientationWidget(),
                const Divider(),
                pagerActionSetting(),
                contentFailedReloadActionSetting(),
                willPopNoticeSetting(),
                categoriesColumnCountSetting(),
                categoriesSortSetting(),
                categoriesHiddenSetting(),
                const Divider(),
                setStartupPicTile(context),
                clearStartupPicTile(context),
                const Divider(),
                languageListTile(),
                timeZoneSetting(),
                fontSetting(),
                fullScreenUISetting(),
                usingRightClickPopSetting(),
                hiddenFdIconSetting(),
                hiddenSubIconSetting(),
                hiddenSearchPersionSetting(),
                const Divider(),
              ],
            ),
            ExpansionTile(
              leading: const Icon(Icons.lan),
              title: Text(tr('settings.network')),
              children: const [
                Divider(),
                NetworkSetting(),
              ],
            ),
            ExpansionTile(
              leading: const Icon(Icons.dangerous),
              title: Text(tr('settings.seal')),
              children: [
                const Divider(),
                shadowCategoriesModeSetting(),
                shadowCategoriesSetting(),
                hiddenWordsSetting(),
                hiddenViewedSetting(),
              ],
            ),
            ExpansionTile(
              leading: const Icon(Icons.open_in_browser),
              title: Text(tr('settings.interaction')),
              children: [
                const Divider(),
                copySkipConfirmSetting(),
                copyFullNameSetting(),
                copyFullNameTemplateSetting(),
                const Divider(),
              ],
            ),
            ExpansionTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(tr('settings.reading')),
              children: [
                const Divider(),
                qualitySetting(),
                readerTypeSettings(),
                readerTwoPageDirectionSetting(),
                readerDirectionSetting(),
                readerSliderPositionSetting(),
                autoFullScreenSetting(),
                autoFullScreenOnForwardSetting(),
                fullScreenActionSetting(),
                webToonScrollModeSetting(),
                readerScrollByScreenPercentageSetting(),
                readerZoomMinScaleSetting(),
                readerZoomMaxScaleSetting(),
                readerZoomDoubleTapScaleSetting(),
                dragRegionLockSetting(),
                gestureSpeedSetting(),
                const Divider(),
                volumeControllerSetting(),
                volumeNextChapterSetting(),
                keyboardControllerSetting(),
                const Divider(),
                noAnimationSetting(),
                readerBackgroundColorSetting(),
                const Divider(),
                threeKeepRightSetting(),
                ignoreInfoHistorySetting(),
              ],
            ),
            ExpansionTile(
              leading: const Icon(Icons.download),
              title: Text(tr('settings.download')),
              children: [
                const Divider(),
                autoDownloadOnFavoriteSetting(),
                disableAutoDownloadOnMobileSetting(),
                autoDeleteDownloadOnUnfavoriteSetting(),
                const Divider(),
                ListTile(
                  title: Text(tr('settings.web_server')),
                  subtitle: Text(tr('settings.web_server_subtitle')),
                  onTap: () {
                    Navigator.of(context).push(
                      mixRoute(
                        builder: (BuildContext context) =>
                            const WebServerScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                chooserRootSetting(),
                downloadThreadCountSetting(),
                downloadAndExportPathSetting(),
                showCommentAtDownloadSetting(),
                exportRenameSetting(),
              ],
            ),
            ExpansionTile(
              leading: const Icon(Icons.backup),
              title: Text(tr('settings.sync')),
              children: [
                const Divider(),
                ...webDavSettings(context),
              ],
            ),
            ExpansionTile(
              leading: const Icon(Icons.manage_accounts),
              title: Text(tr('settings.account')),
              children: [
                const Divider(),
                widget.hiddenAccountInfo
                    ? Container()
                    : ListTile(
                        onTap: () async {
                          Navigator.push(
                            context,
                            mixRoute(
                              builder: (context) =>
                                  const ModifyPasswordScreen(),
                            ),
                          );
                        },
                        title: Text(tr('settings.modify_password')),
                      ),
                const Divider(),
                useLocalFavoriteSetting(),
                const Divider(),
                hideOnlineFavoriteSetting(),
                const Divider(),
                tagFavoriteSetting(),
              ],
            ),
            ExpansionTile(
              leading: const Icon(Icons.chrome_reader_mode),
              title: Text(tr('settings.ebook')),
              children: [
                const Divider(),
                iconLoadingSetting(),
                eBookScrollingSetting(),
                eBookScrollingRangeSetting(),
                eBookScrollingTriggerSetting(),
                imageFilterSetting(),
                const Divider(),
              ],
            ),
            ExpansionTile(
              leading: const Icon(Icons.ad_units),
              title: Text(tr('settings.system')),
              children: [
                const Divider(),
                androidDisplayModeSetting(),
                androidSecureFlagSetting(),
                authenticationSetting(),
                lockTimeOutSecSetting(),
                lockTimeOutSecNotice(),
                const Divider(),
                autoCleanSecSetting(),
                ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      mixRoute(builder: (context) => const CleanScreen()),
                    );
                  },
                  title: Text(tr('settings.clear_cache')),
                ),
                const Divider(),
                migrate(context),
                const Divider(),
                downloadCachePathSetting(),
                importViewLogFromOff(),
                const Divider(),
                ignoreUpgradeConfirmSetting(),
              ],
            ),
            SafeArea(
              top: false,
              child: Container(),
            ),
          ],
        ),
      ),
    );
  }

  Widget migrate(BuildContext context) {
    if (Platform.isAndroid) {
      return ListTile(
        title: Text(
          tr('settings.migrate') + (!isPro ? "(${tr('settings.app.pro')})" : ""),
          style: TextStyle(
            color: !isPro ? Colors.grey : null,
          ),
        ),
        subtitle: Text(tr('settings.migrate_subtitle')),
        onTap: () async {
          if (!isPro) {
            defaultToast(context, tr('app.pro_required'));
            return;
          }
          var f =
              await confirmDialog(context, tr('settings.migrate'), tr('settings.migrate_confirm'));
          if (f) {
            Navigator.of(context).pushAndRemoveUntil(
              mixRoute(builder: (BuildContext context) {
                return const MigrateScreen();
              }),
              (route) => false,
            );
          }
        },
      );
    }
    return Container();
  }
}

class _IconAndWidgets {
  final IconData icon;
  final List<Widget> widgets;

  _IconAndWidgets(this.icon, this.widgets);
}
