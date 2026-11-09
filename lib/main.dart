import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pikapika/basic/Navigator.dart';
import 'package:pikapika/basic/config/Themes.dart';
import 'package:pikapika/basic/define.dart';
import 'package:pikapika/i18.dart' as i18;
import 'package:pikapika/screens/InitScreen.dart';
import 'package:pikapika/screens/components/MouseAndTouchScrollBehavior.dart';
import 'package:pikapika/src/rust/api/auth.dart';
import 'package:pikapika/src/rust/api/simple.dart';
import 'package:pikapika/src/rust/frb_generated.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  final dataDir = await _dataDir();
  await initApplication(dataDir: dataDir);
  await initApplication(dataDir: dataDir);
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await _prepareWindow();
  }
  if (Platform.isAndroid || Platform.isIOS) {
    await EasyLocalization.ensureInitialized();
    runApp(
      EasyLocalization(
        supportedLocales: supportedLocales,
        path: translationsPath,
        fallbackLocale: fallbackLocale,
        child: const PikapikaApp(),
      ),
    );
  } else {
    await i18.loadTranslations();
    runApp(const PikapikaApp());
  }
}

Future<String> _dataDir() async {
  if (Platform.isAndroid || Platform.isIOS) {
    return await const MethodChannel("pikapika/platform")
            .invokeMethod<String>("dataLocal") ??
        "";
  }
  return "";
}

Future<void> _prepareWindow() async {
  await windowManager.ensureInitialized();
  final width = int.tryParse(
        await loadProperty(name: "window_width", defaultValue: "600"),
      ) ??
      600;
  final height = int.tryParse(
        await loadProperty(name: "window_height", defaultValue: "900"),
      ) ??
      900;
  final full =
      await loadProperty(name: "full_screen", defaultValue: "false") == "true";
  await windowManager.waitUntilReadyToShow(
    WindowOptions(size: Size(width.toDouble(), height.toDouble())),
    () async {
      if (full) {
        await windowManager.maximize();
      }
      await windowManager.show();
      await windowManager.focus();
    },
  );
  windowManager.addListener(_WindowStore());
}

class _WindowStore extends WindowListener {
  @override
  void onWindowResize() {
    _store();
  }

  @override
  void onWindowMaximize() {
    saveProperty(name: "full_screen", value: "true");
  }

  @override
  void onWindowUnmaximize() {
    saveProperty(name: "full_screen", value: "false");
  }

  Future<void> _store() async {
    final size = await windowManager.getSize();
    await saveProperty(name: "window_width", value: size.width.round().toString());
    await saveProperty(name: "window_height", value: size.height.round().toString());
  }
}

class PikapikaApp extends StatefulWidget {
  const PikapikaApp({super.key});

  @override
  State<StatefulWidget> createState() => _PikapikaAppState();
}

class _PikapikaAppState extends State<PikapikaApp> {
  @override
  void initState() {
    themeEvent.subscribe(_onChangeTheme);
    super.initState();
  }

  @override
  void dispose() {
    themeEvent.unsubscribe(_onChangeTheme);
    super.dispose();
  }

  void _onChangeTheme(EventArgs? args) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid || Platform.isIOS) {
      return MaterialApp(
        scrollBehavior: mouseAndTouchScrollBehavior,
        theme: currentLightThemeData(),
        darkTheme: currentDarkThemeData(),
        navigatorObservers: [navigatorObserver, routeObserver],
        home: const InitScreen(),
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
      );
    }
    return MaterialApp(
      scrollBehavior: mouseAndTouchScrollBehavior,
      theme: currentLightThemeData(),
      darkTheme: currentDarkThemeData(),
      navigatorObservers: [navigatorObserver, routeObserver],
      home: const InitScreen(),
    );
  }
}
