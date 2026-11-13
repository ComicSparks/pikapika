import 'package:flutter/material.dart';
import 'package:pikapika/i18.dart';

import '../basic/config/Themes.dart';
import 'CustomThemeManageScreen.dart';
import 'components/ListView.dart';
import 'components/RightClickPop.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
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
      appBar: AppBar(title: Text(tr('screen.theme.title'))),
      body: PikaListView(
        children: themeWidgets(context, setState),
      ),
    );
  }
}

List<Widget> themeWidgets(
    BuildContext context, void Function(VoidCallback fn) setState) {
  return [
    ListTile(
      onTap: () async {
        await chooseLightTheme(context);
        setState(() {});
      },
      title: Text(tr('screen.theme.theme')),
      subtitle: Text(currentLightThemeName()),
    ),
    ...androidNightModeDisplay
        ? [
            SwitchListTile(
                title: Text(tr('screen.theme.dark_mode_different_theme')),
                value: androidNightMode,
                onChanged: (value) async {
                  await setAndroidNightMode(value);
                  setState(() {});
                }),
          ]
        : [],
    ...androidNightModeDisplay && androidNightMode
        ? [
            ListTile(
              onTap: () async {
                await chooseDarkTheme(context);
                setState(() {});
              },
              title: Text(tr('screen.theme.dark_mode_theme')),
              subtitle: Text(currentDarkThemeName()),
            ),
          ]
        : [],
    ListTile(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const CustomThemeManageScreen(),
          ),
        );
        setState(() {});
      },
      title: Text(tr('settings.theme.custom_manage')),
      subtitle: Text(tr('settings.theme.custom_manage_hint')),
    ),
    // ...androidVersion > 0 ? [enableStatusBarColorSetting()] : [],
  ];
}
