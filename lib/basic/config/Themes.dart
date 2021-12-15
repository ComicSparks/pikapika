/// 主题

import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pikapika/basic/Common.dart';
import '../Method.dart';
import 'Platform.dart';


// 字体相关

const _fontFamilyProperty = "fontFamily";

String? _fontFamily;

Future initFont() async {
  var defaultFont = "";
  _fontFamily = await method.loadProperty(_fontFamilyProperty, defaultFont);
}

ThemeData _fontThemeData(bool dark) {
  return ThemeData(
    brightness: dark ? Brightness.dark : Brightness.light,
    fontFamily: _fontFamily == "" ? null : _fontFamily,
  );
}

Future<void> inputFont(BuildContext context) async {
  var font = await displayTextInputDialog(
    context, src: "$_fontFamily", title: "字体", hint: "请输入字体",
    desc: "请输入字体的名称, 例如宋体/黑体, 如果您保存后没有发生变化, 说明字体无法使用或名称错误, 可以去参考C:\\Windows\\Fonts寻找您的字体。",
  );
  if (font != null) {
    await method.saveProperty(_fontFamilyProperty, font);
    _fontFamily = font;
    _changeThemeByCode(_themeCode);
  }
}

Widget fontSetting() {
  return StatefulBuilder(
    builder: (BuildContext context, void Function(void Function()) setState) {
      return ListTile(
        title: Text("字体"),
        subtitle: Text("$_fontFamily"),
        onTap: () async {
          await inputFont(context);
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
}

class _OriginTheme extends _ThemePackage {
  @override
  String code() => "origin";

  @override
  String name() => "原生";

  @override
  ThemeData themeData(ThemeData rawData) => rawData;
}

class _PinkTheme extends _ThemePackage {
  @override
  String code() => "pink";

  @override
  String name() => "粉色";

  @override
  ThemeData themeData(ThemeData rawData) =>
      rawData.copyWith(
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          secondary: Colors.pink.shade200,
        ),
        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          color: Colors.pink.shade200,
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors.pink[300],
          unselectedItemColor: Colors.grey[500],
        ),
        dividerColor: Colors.grey.shade200,
        primaryColor: Colors.pink.shade200,
        highlightColor: Colors.pink.shade200,
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
}

class _BlackTheme extends _ThemePackage {
  @override
  String code() => "black";

  @override
  String name() => "酷黑";

  @override
  ThemeData themeData(ThemeData rawData) =>
      rawData.copyWith(
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          secondary: Colors.pink.shade200,
        ),
        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          color: Colors.grey.shade800,
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey[400],
          backgroundColor: Colors.grey.shade800,
        ),
        dividerColor: Colors.grey.shade200,
        primaryColor: Colors.pink.shade200,
        highlightColor: Colors.pink.shade200,
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
}

class _DarkTheme extends _ThemePackage {
  @override
  String code() => "dark";

  @override
  String name() => "暗黑";

  @override
  ThemeData themeData(ThemeData rawData) =>
      rawData.copyWith(
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          secondary: Colors.pink.shade200,
        ),
        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          color: Color(0xFF1E1E1E),
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey.shade300,
          backgroundColor: Colors.grey.shade900,
        ),
        primaryColor: Colors.pink.shade200,
        highlightColor: Colors.pink.shade200,
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
}

class _DustyBlueTheme extends _ThemePackage {
  @override
  String code() => "dustyBlue";

  @override
  String name() => "灰蓝";

  @override
  ThemeData themeData(ThemeData rawData) =>
      rawData.copyWith(
        scaffoldBackgroundColor: Color.alphaBlend(
            Color(0x11999999), Color(0xff20253b)),
        cardColor: Color.alphaBlend(Color(0x11AAAAAA), Color(0xff20253b)),
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          secondary: Colors.blue.shade200,
        ),
        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          color: Color(0xff20253b),
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Color(0xff191b26),
          selectedItemColor: Colors.blue.shade200,
          unselectedItemColor: Colors.grey.shade500,
        ),
        dividerColor: Colors.grey.shade800,
        primaryColor: Colors.blue.shade200,
        highlightColor: Colors.blue.shade200,
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
      );
}

var _darkTheme = _DarkTheme();
var _dustyBlueTheme = _DustyBlueTheme();

final _themePackages = <_ThemePackage>[
  _OriginTheme(),
  _PinkTheme(),
  _BlackTheme(),
  _darkTheme,
  _dustyBlueTheme,
];

// 主题更换事件
var themeEvent = Event<EventArgs>();

const _themePropertyName = "theme";
const _defaultThemeCode = "pink";

String? _themeCode;
ThemeData? _themeData;
ThemeData? _currentDarkTheme;
bool _androidNightMode = false;

String currentThemeName() {
  for (var package in _themePackages) {
    if (_themeCode == package.code()) {
      return package.name();
    }
  }
  return "";
}

ThemeData? currentThemeData() {
  return _themeData;
}

ThemeData? currentDarkTheme() {
  return _currentDarkTheme;
}

// 根据Code选择主题, 并发送主题更换事件
void _changeThemeByCode(String? themeCode) {
  _ThemePackage? _themePackage;
  for (var package in _themePackages) {
    if (themeCode == package.code()) {
      _themeCode = themeCode;
      _themePackage = package;
      break;
    }
  }
  if (_themePackage != null) {
    _themeData = _themePackage.themeData(
      _fontThemeData(
          _themePackage == _darkTheme || _themePackage == _dustyBlueTheme),
    );
  }
  _currentDarkTheme = _androidNightMode
      ? _darkTheme.themeData(_fontThemeData(true))
      : _themeData;
  themeEvent.broadcast();
}

// 为了匹配安卓夜间模式增加的配置文件
const _nightModePropertyName = "androidNightMode";

Future<dynamic> initTheme() async {
  _androidNightMode =
      await method.loadProperty(_nightModePropertyName, "true") == "true";
  _changeThemeByCode(
    await method.loadProperty(_themePropertyName, _defaultThemeCode),
  );
}

// 选择主题的对话框
Future<dynamic> chooseTheme(BuildContext buildContext) async {
  String? theme = await showDialog<String>(
    context: buildContext,
    builder: (BuildContext context) {
      return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            var list = <SimpleDialogOption>[];
            if (androidVersion >= 29) {
              var onChange = (bool? v) async {
                if (v != null) {
                  await method.saveProperty(
                      _nightModePropertyName, "$v");
                  _androidNightMode = v;
                }
                _changeThemeByCode(_themeCode);
              };
              list.add(
                SimpleDialogOption(
                  child: GestureDetector(
                    onTap: () {
                      onChange(!_androidNightMode);
                    },
                    child: Container(
                      margin: EdgeInsets.only(top: 3, bottom: 3),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Theme
                                .of(context)
                                .dividerColor,
                            width: 0.5,
                          ),
                          bottom: BorderSide(
                              color: Theme
                                  .of(context)
                                  .dividerColor,
                              width: 0.5
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _androidNightMode,
                            onChanged: onChange,
                          ),
                          Text("随手机进入黑暗模式"),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
            list.addAll(_themePackages
                .map((e) =>
                SimpleDialogOption(
                  child: Text(e.name()),
                  onPressed: () {
                    Navigator.of(context).pop(e.code());
                  },
                )
            ));
            return SimpleDialog(
              title: Text("选择主题"),
              children: list,
            );
          })
    },
  );
  if (theme != null) {
    method.saveProperty(_themePropertyName, theme);
    _changeThemeByCode(theme);
  }
}
