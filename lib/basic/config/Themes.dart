/// 主题

import 'dart:io';

import 'package:pikapika/i18.dart';
import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pikapika/basic/Common.dart';
import '../Method.dart';
import 'Platform.dart';

// 字体相关

const _fontFamilyProperty = "fontFamily";

List<String> _fontFamily = [];
List<String> _fontList = [];

Future initFont() async {
  if (Platform.isIOS) {
    try {
      _fontList = await method.fontList();
    } catch (e, s) {
      print("获取字体列表失败: $e\n$s");
      _fontList = [];
    }
  }
  var defaultFont = "";
  _fontFamily = (await method.loadProperty(_fontFamilyProperty, defaultFont))
      .split(",")
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}

ThemeData _fontThemeData(bool dark) {
  return ThemeData(
    // 这些主题按 Material 2 配色。Material 3 会把分割线改成近黑的 outlineVariant，
    // 并把彩色顶栏上的标题改成 onSurface。
    useMaterial3: false,
    brightness: dark ? Brightness.dark : Brightness.light,
    fontFamily: _fontFamily.isEmpty ? null : _fontFamily.first,
    ////fontFamilyFallback: _fontFamily.length > 1 ? _fontFamily.sublist(1) : null,
  );
}

Future<void> inputFont(BuildContext context) async {
  var font = await displayTextInputDialog(
    context,
    src: "$_fontFamily",
    title: tr("settings.font.title"),
    hint: tr("settings.font.hint"),
    desc: tr("settings.font.input_hint"),
  );
  if (font != null) {
    await method.saveProperty(_fontFamilyProperty, font);
    _fontFamily = font
        .split(",")
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    _reloadTheme();
  }
}

Future<String?> chooseFontFromList(BuildContext context) async {
  var font = await showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return SimpleDialog(
        title: Text(tr("settings.font.choose_hint")),
        children: _fontList.map((e) {
          return SimpleDialogOption(
            child: Container(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "$e\n 我能吞下玻璃而不伤身体\n The quick brown fox jumps over the lazy dog.",
                style: TextStyle(fontFamily: e, fontSize: 16),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop(e);
            },
          );
        }).toList(),
      );
    },
  );
  if (font == null || font.isEmpty) {
    return null;
  }
  return font;
}

Future<void> chooseFont(BuildContext context) async {
  List<String> fonts = [];
  while (true) {
    var font = await chooseFontFromList(context);
    if (font == null) {
      break;
    }
    fonts.add(font);
  }
  await method.saveProperty(_fontFamilyProperty, fonts.join(","));
  _fontFamily = fonts;
  _reloadTheme();
}

Widget fontSetting() {
  return StatefulBuilder(
    builder: (BuildContext context, void Function(void Function()) setState) {
      return ListTile(
        title: Text(tr("settings.font.title")),
        subtitle: Text(_fontFamily.join(",")),
        onTap: () async {
          if (_fontList.isEmpty) {
            await inputFont(context);
          } else {
            await chooseFont(context);
          }
          setState(() {});
        },
      );
    },
  );
}

//
const _enableStatusBarColorProperty = "enableStatusBarColorProperty";
var _enableStatusBarColor = false;

Widget enableStatusBarColorSetting() {
  return StatefulBuilder(
    builder: (BuildContext context, void Function(void Function()) setState) {
      return SwitchListTile(
        title: Text(tr("settings.theme.enable_status_bar_color")),
        subtitle: Text(tr("settings.theme.enable_status_restart_hint")),
        value: _enableStatusBarColor,
        onChanged: (bool value) async {
          await method.saveProperty(
              _enableStatusBarColorProperty, "$value");
          _enableStatusBarColor = value;
          _reloadTheme();
          setState(() {});
        },
      );
    },
  );
}

// 主题相关

// 主题包
abstract class _ThemePackage {
  String code();

  String name();

  ThemeData themeData(ThemeData rawData);

  bool isDark();
}

class _OriginTheme extends _ThemePackage {
  @override
  String code() => "origin";

  @override
  String name() => tr("settings.theme.origin");

  @override
  ThemeData themeData(ThemeData rawData) => rawData;

  @override
  bool isDark() => false;
}

class _BookTheme extends _ThemePackage {
  @override
  String code() => "book";

  @override
  String name() => tr("settings.theme.book");

  @override
  ThemeData themeData(ThemeData rawData) => rawData.copyWith(
        brightness: Brightness.dark,
        appBarTheme: AppBarTheme(
          elevation: 0,
          foregroundColor: Colors.grey.shade700,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          color: Colors.transparent,
          iconTheme: IconThemeData(
            color: Colors.grey.shade700,
          ),
          shape: Border(
            bottom: BorderSide(color: Colors.grey.shade500, width: 2),
          ),
          titleTextStyle: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 16,
          ),
        ),
      );

  @override
  bool isDark() => false;
}

class _PinkTheme extends _ThemePackage {
  @override
  String code() => "pink";

  @override
  String name() => tr("settings.theme.pink");

  @override
  ThemeData themeData(ThemeData rawData) => rawData.copyWith(
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: Colors.pink.shade200,
          secondary: Colors.pink.shade200,
          outline: Colors.grey.shade200,
          outlineVariant: Colors.grey.shade200,
        ),
        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
            statusBarColor:
                _enableStatusBarColor ? Colors.pink.shade200 : null,
          ),
          color: Colors.pink.shade200,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors.pink[300],
          unselectedItemColor: Colors.grey[500],
        ),
        dividerColor: Colors.grey.shade200,
        dividerTheme: DividerThemeData(color: Colors.grey.shade200),
        primaryColor: Colors.pink.shade200,
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.pink.shade200,
          selectionColor: Colors.pink.shade300.withAlpha(150),
          selectionHandleColor: Colors.pink.shade300.withAlpha(200),
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.pink.shade200),
          ),
        ),
      );

  @override
  bool isDark() => false;
}

class _BlackTheme extends _ThemePackage {
  @override
  String code() => "black";

  @override
  String name() => tr("settings.theme.black");

  @override
  ThemeData themeData(ThemeData rawData) => rawData.copyWith(
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: Colors.pink.shade200,
          secondary: Colors.pink.shade200,
          outline: Colors.grey.shade200,
          outlineVariant: Colors.grey.shade200,
        ),
        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
            statusBarColor:
                _enableStatusBarColor ? Colors.grey.shade800 : null,
          ),
          color: Colors.grey.shade800,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey[400],
          backgroundColor: Colors.grey.shade800,
        ),
        dividerColor: Colors.grey.shade200,
        dividerTheme: DividerThemeData(color: Colors.grey.shade200),
        primaryColor: Colors.pink.shade200,
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.pink.shade200,
          selectionColor: Colors.pink.shade300.withAlpha(150),
          selectionHandleColor: Colors.pink.shade300.withAlpha(200),
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.pink.shade200),
          ),
        ),
      );

  @override
  bool isDark() => false;
}

class _DarkTheme extends _ThemePackage {
  @override
  String code() => "dark";

  @override
  String name() => tr("settings.theme.dark");

  @override
  ThemeData themeData(ThemeData rawData) => rawData.copyWith(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.light(
          primary: Colors.pink.shade200,
          secondary: Colors.pink.shade200,
          outline: Colors.grey.shade500.withAlpha(70),
          outlineVariant: Colors.grey.shade500.withAlpha(70),
        ),
        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
            statusBarColor:
                _enableStatusBarColor ? const Color(0xFF1E1E1E) : null,
          ),
          color: const Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey.shade300,
          backgroundColor: Colors.grey.shade900,
        ),
        dividerColor: Colors.grey.shade500.withAlpha(70),
        dividerTheme: DividerThemeData(
          color: Colors.grey.shade500.withAlpha(70),
        ),
        primaryColor: Colors.pink.shade200,
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.pink.shade200,
          selectionColor: Colors.pink.shade300.withAlpha(150),
          selectionHandleColor: Colors.pink.shade300.withAlpha(200),
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.pink.shade200),
          ),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: Colors.pink.shade200,
          inactiveTrackColor: Colors.pink.shade300.withAlpha(150),
          thumbColor: Colors.pink.shade200,
          overlayColor: Colors.pink.shade300.withAlpha(150),
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        ),
      );

  @override
  bool isDark() => true;
}

class _DustyBlueTheme extends _ThemePackage {
  @override
  String code() => "dustyBlue";

  @override
  String name() => tr("settings.theme.dusty_blue");

  @override
  ThemeData themeData(ThemeData rawData) => rawData.copyWith(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color.alphaBlend(
          const Color(0x11999999),
          const Color(0xff20253b),
        ),
        cardColor: Color.alphaBlend(
          const Color(0x11AAAAAA),
          const Color(0xff20253b),
        ),
        colorScheme: ColorScheme.light(
          primary: Colors.blue.shade200,
          secondary: Colors.blue.shade200,
          outline: Colors.grey.shade800,
          outlineVariant: Colors.grey.shade800,
        ),
        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
            statusBarColor:
                _enableStatusBarColor ? const Color(0xff20253b) : null,
          ),
          color: const Color(0xff20253b),
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xff20253b),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: const Color(0xff191b26),
          selectedItemColor: Colors.blue.shade200,
          unselectedItemColor: Colors.grey.shade500,
        ),
        dividerColor: Colors.grey.shade800,
        dividerTheme: DividerThemeData(color: Colors.grey.shade800),
        primaryColor: Colors.blue.shade200,
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.blue.shade200,
          selectionColor: Colors.blue.shade900,
          selectionHandleColor: Colors.blue.shade800,
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.blue.shade500),
          ),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: Colors.blue.shade200,
          inactiveTrackColor: Colors.blue.shade300.withAlpha(150),
          thumbColor: Colors.blue.shade200,
          overlayColor: Colors.blue.shade300.withAlpha(150),
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        ),
      );

  @override
  bool isDark() => true;
}

class _DarkBlackTheme extends _ThemePackage {
  @override
  String code() => "dark_black";

  @override
  String name() => tr("settings.theme.dark_black");

  @override
  ThemeData themeData(ThemeData rawData) => rawData.copyWith(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.light(
          primary: Colors.pink.shade200,
          secondary: Colors.pink.shade200,
          outline: const Color.fromARGB(0xff, 64, 64, 64),
          outlineVariant: const Color.fromARGB(0xff, 64, 64, 64),
        ),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: _enableStatusBarColor
                ? const Color.fromARGB(0xff, 10, 10, 10)
                : null,
          ),
          color: const Color.fromARGB(0xff, 10, 10, 10),
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey.shade300,
          backgroundColor: const Color.fromARGB(0xff, 10, 10, 10),
        ),
        primaryColor: Colors.pink.shade200,
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.pink.shade200,
          selectionColor: Colors.pink.shade300.withAlpha(150),
          selectionHandleColor: Colors.pink.shade300.withAlpha(200),
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.pink.shade200),
          ),
        ),
        dividerColor: const Color.fromARGB(0xff, 64, 64, 64),
        dividerTheme: const DividerThemeData(
          color: Color.fromARGB(0xff, 64, 64, 64),
        ),
      );

  @override
  bool isDark() => true;
}

final _themePackages = <_ThemePackage>[
  _OriginTheme(),
  _PinkTheme(),
  _BlackTheme(),
  _DarkTheme(),
  _DustyBlueTheme(),
  _DarkBlackTheme(),
  _BookTheme(),
];

// 主题更换事件
var themeEvent = Event<EventArgs>();

const _nightModePropertyName = "androidNightMode";
const _lightThemePropertyName = "theme";
const _darkThemePropertyName = "theme.dark";
const _defaultLightThemeCode = "pink";
const _defaultDarkThemeCode = "dark";
bool androidNightModeDisplay = false;
bool androidNightMode = false;

String? _lightThemeCode;
ThemeData? _lightThemeData;
String? _darkThemeCode;
ThemeData? _darkThemeData;

// _changeThemeByCode

String _codeToName(String? code) {
  for (var package in _themePackages) {
    if (code == package.code()) {
      return package.name();
    }
  }
  return "";
}

String currentLightThemeName() {
  return _codeToName(_lightThemeCode);
}

String currentDarkThemeName() {
  return _codeToName(_darkThemeCode);
}

ThemeData? currentLightThemeData() {
  return _lightThemeData;
}

ThemeData? currentDarkThemeData() {
  return _darkThemeData;
}

// 根据Code选择主题, 并发送主题更换事件

ThemeData? _themeByCode(String? themeCode) {
  for (var package in _themePackages) {
    if (themeCode == package.code()) {
      return package.themeData(_fontThemeData(package.isDark()));
    }
  }
  return null;
}

void _reloadTheme() {
  _lightThemeData = _themeByCode(_lightThemeCode);
  if (androidNightMode) {
    _darkThemeData = _themeByCode(_darkThemeCode);
  } else {
    _darkThemeData = _lightThemeData;
  }
  themeEvent.broadcast();
}

Future<dynamic> initTheme() async {
  androidNightModeDisplay = androidVersion >= 29 || Platform.isIOS;
  androidNightMode =
      await method.loadProperty(_nightModePropertyName, "true") == "true";
  _lightThemeCode = await method.loadProperty(
      _lightThemePropertyName, _defaultLightThemeCode);
  _darkThemeCode =
      await method.loadProperty(_darkThemePropertyName, _defaultDarkThemeCode);
  _enableStatusBarColor =
      await method.loadProperty(_enableStatusBarColorProperty, "false") == "true";
  _reloadTheme();
}

// 选择主题的对话框
Future<String?> _chooseTheme(BuildContext buildContext) {
  return showDialog<String>(
    context: buildContext,
    builder: (BuildContext context) {
      return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
        var list = <SimpleDialogOption>[];
        list.addAll(_themePackages.map((e) => SimpleDialogOption(
              child: Text(e.name()),
              onPressed: () {
                Navigator.of(context).pop(e.code());
              },
            )));
        return SimpleDialog(
          title: Text(tr("settings.theme.choose_theme")),
          children: list,
        );
      });
    },
  );
}

Future<dynamic> chooseLightTheme(BuildContext buildContext) async {
  String? theme = await _chooseTheme(buildContext);
  if (theme != null) {
    await method.saveProperty(_lightThemePropertyName, theme);
    _lightThemeCode = theme;
    _reloadTheme();
  }
}

Future<dynamic> chooseDarkTheme(BuildContext buildContext) async {
  String? theme = await _chooseTheme(buildContext);
  if (theme != null) {
    await method.saveProperty(_darkThemePropertyName, theme);
    _darkThemeCode = theme;
    _reloadTheme();
  }
}

Future setAndroidNightMode(bool value) async {
  await method.saveProperty(_nightModePropertyName, "$value");
  androidNightMode = value;
  _reloadTheme();
}
