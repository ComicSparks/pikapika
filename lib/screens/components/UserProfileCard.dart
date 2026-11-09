import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:pikapika/i18.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pikapika/basic/Common.dart';
import 'package:pikapika/basic/Entities.dart';
import 'package:pikapika/basic/Method.dart';
import 'package:pikapika/screens/components/Avatar.dart';
import 'package:pikapika/screens/components/Images.dart';
import 'package:pikapika/screens/components/ItemBuilder.dart';

import '../../basic/config/IconLoading.dart';
import 'DesktopCropper.dart';

const double _cardHeight = 180;

// 用户信息卡
class UserProfileCard extends StatefulWidget {
  const UserProfileCard({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _UserProfileCardState();
}

class _UserProfileCardState extends State<UserProfileCard> {
  late Future<UserProfile> _future = _load();

  Future<UserProfile> _load() async {
    var profile = await method.userProfile();
    if (!profile.isPunched) {
      await method.punchIn();
      defaultToast(context, tr('app.auto_punch'));
    }
    return profile;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var nameStyle = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
    );
    var nameStrutStyle = const StrutStyle(
      fontSize: 14,
      forceStrutHeight: true,
      fontWeight: FontWeight.bold,
    );
    var levelStyle = TextStyle(
      fontSize: 12,
      color: theme.colorScheme.secondary.withOpacity(.9),
      fontWeight: FontWeight.bold,
    );
    var levelStrutStyle = const StrutStyle(
      fontSize: 12,
      forceStrutHeight: true,
      fontWeight: FontWeight.bold,
    );
    var sloganStyle = TextStyle(
      fontSize: 10,
      color: theme.textTheme.bodyLarge?.color?.withOpacity(.5),
    );
    var sloganStrutStyle = const StrutStyle(
      fontSize: 10,
      forceStrutHeight: true,
    );
    return ItemBuilder(
      future: _future,
      onRefresh: () async {
        setState(() => _future = method.userProfile());
      },
      height: _cardHeight,
      successBuilder:
          (BuildContext context, AsyncSnapshot<UserProfile> snapshot) {
        UserProfile profile = snapshot.data!;
        return Stack(
          children: [
            Stack(
              children: [
                Opacity(
                  opacity: .25, //
                  child: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                      return RemoteImage(
                        path: profile.avatar.path,
                        fileServer: profile.avatar.fileServer,
                        width: constraints.maxWidth,
                        height: _cardHeight,
                      );
                    },
                  ),
                ),
                Positioned.fromRect(
                  rect: Rect.largest,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Container(),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: _cardHeight,
              child: Column(
                children: [
                  Expanded(child: Container()),
                  GestureDetector(
                    onTap: () async {
                      if (Platform.isAndroid || Platform.isIOS) {
                        await _updateAvatarPhone();
                      } else if (Platform.isMacOS ||
                          Platform.isWindows ||
                          Platform.isLinux) {
                        await _updateAvatarDesktop();
                      }
                    },
                    child: Avatar(profile.avatar, size: 65),
                  ),
                  Container(height: 5),
                  Text(
                    profile.name,
                    style: nameStyle,
                    strutStyle: nameStrutStyle,
                  ),
                  Text(
                    "(Lv. ${profile.level}) (${profile.title})",
                    style: levelStyle,
                    strutStyle: levelStrutStyle,
                  ),
                  Container(height: 8),
                  GestureDetector(
                    onTap: () async {
                      var input = await inputString(
                        context,
                        "更新签名",
                        defaultValue: profile.slogan ?? "",
                      );
                      if (input != null) {
                        await method.updateSlogan(input);
                        _reload();
                      }
                    },
                    child: Text(
                      profile.slogan == null || profile.slogan!.isEmpty
                          ? "这个人很懒, 什么也没留下"
                          : profile.slogan!,
                      style: sloganStyle,
                      strutStyle: sloganStrutStyle,
                    ),
                  ),
                  Expanded(child: Container()),
                ],
              ),
            )
          ],
        );
      },
    );
  }

  Future _updateAvatarPhone() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final theme = Theme.of(context);
      final cropper = ImageCropper();
      final croppedFile = await cropper.cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 200, ratioY: 200),
        maxWidth: 200,
        maxHeight: 200,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: "修改头像",
            toolbarColor: theme.appBarTheme.backgroundColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: true,
            aspectRatioPresets: [CropAspectRatioPreset.square],
          ),
          IOSUiSettings(
            resetAspectRatioEnabled: true,
            aspectRatioLockEnabled: true,
            title: "修改头像",
          ),
        ],
      );
      if (croppedFile != null) {
        var buff = await croppedFile.readAsBytes();
        var data = base64Encode(buff);
        await method.updateAvatar(data);
        _reload();
      }
    }
  }

  Future _updateAvatarDesktop() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null) {
      List<int>? buff = await Navigator.of(context).push(
        mixRoute(builder: (BuildContext context) {
          return DesktopCropper(
            file: result.files.first.path!,
            aspectRatio: 1,
            title: "裁剪头像",
          );
        }),
      );
      if (buff != null) {
        var data = base64Encode(buff);
        await method.updateAvatar(data);
        _reload();
      }
    }
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }
}
