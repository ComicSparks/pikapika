import 'package:flutter/material.dart';
import 'package:pikapika/basic/Common.dart';
import 'package:pikapika/basic/config/CustomTheme.dart';
import 'package:pikapika/basic/config/Themes.dart';
import 'package:pikapika/i18.dart';

import 'components/ListView.dart';
import 'components/RightClickPop.dart';

class CustomThemeEditScreen extends StatefulWidget {
  final CustomTheme theme;

  const CustomThemeEditScreen({Key? key, required this.theme})
      : super(key: key);

  @override
  State<CustomThemeEditScreen> createState() => _CustomThemeEditScreenState();
}

class _CustomThemeEditScreenState extends State<CustomThemeEditScreen> {
  late TextEditingController _nameController;
  late CustomThemeColors _colors;
  late bool _isDark;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.theme.name);
    _colors = widget.theme.colors;
    _isDark = widget.theme.isDark;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickColor({
    required String title,
    required Color current,
    required void Function(Color color) apply,
  }) async {
    final color = await showColorPickerDialog(
      context,
      initial: current,
      title: title,
    );
    if (color != null) {
      setState(() {
        apply(color);
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      defaultToast(context, tr("settings.theme.custom_name_required"));
      return;
    }
    setState(() {
      _saving = true;
    });
    try {
      await saveCustomThemeEdits(
        widget.theme.copyWith(
          name: name,
          isDark: _isDark,
          colors: _colors,
        ),
      );
      if (mounted) {
        defaultToast(context, tr("settings.theme.custom_save_success"));
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Widget _colorTile({
    required String title,
    required Color color,
    required void Function(Color color) apply,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(colorToHex(color)),
      trailing: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade500),
        ),
      ),
      onTap: _saving
          ? null
          : () => _pickColor(title: title, current: color, apply: apply),
    );
  }

  @override
  Widget build(BuildContext context) {
    return rightClickPop(
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr("settings.theme.custom_edit")),
          actions: [
            TextButton(
              onPressed: _saving ? null : _save,
              style: TextButton.styleFrom(
                foregroundColor:
                    Theme.of(context).appBarTheme.foregroundColor ??
                        Colors.white,
              ),
              child: Text(tr("app.confirm")),
            ),
          ],
        ),
        body: PikaListView(
          children: [
            ListTile(
              title: Text(tr("settings.theme.custom_name")),
              subtitle: TextField(
                controller: _nameController,
                enabled: !_saving,
                decoration: InputDecoration(
                  hintText: tr("settings.theme.custom_name_hint"),
                ),
              ),
            ),
            SwitchListTile(
              title: Text(tr("settings.theme.custom_is_dark")),
              value: _isDark,
              onChanged: _saving
                  ? null
                  : (value) {
                      setState(() {
                        _isDark = value;
                      });
                    },
            ),
            const Divider(),
            _colorTile(
              title: tr("settings.theme.custom_color_primary"),
              color: _colors.primary,
              apply: (c) => _colors = _colors.copyWith(primary: c),
            ),
            _colorTile(
              title: tr("settings.theme.custom_color_scaffold"),
              color: _colors.scaffoldBackground,
              apply: (c) => _colors = _colors.copyWith(scaffoldBackground: c),
            ),
            _colorTile(
              title: tr("settings.theme.custom_color_card"),
              color: _colors.cardColor,
              apply: (c) => _colors = _colors.copyWith(cardColor: c),
            ),
            _colorTile(
              title: tr("settings.theme.custom_color_app_bar"),
              color: _colors.appBarColor,
              apply: (c) => _colors = _colors.copyWith(appBarColor: c),
            ),
            _colorTile(
              title: tr("settings.theme.custom_color_app_bar_fg"),
              color: _colors.appBarForeground,
              apply: (c) => _colors = _colors.copyWith(appBarForeground: c),
            ),
            _colorTile(
              title: tr("settings.theme.custom_color_bottom_bg"),
              color: _colors.bottomNavBackground,
              apply: (c) => _colors = _colors.copyWith(bottomNavBackground: c),
            ),
            _colorTile(
              title: tr("settings.theme.custom_color_bottom_selected"),
              color: _colors.bottomNavSelected,
              apply: (c) => _colors = _colors.copyWith(bottomNavSelected: c),
            ),
            _colorTile(
              title: tr("settings.theme.custom_color_bottom_unselected"),
              color: _colors.bottomNavUnselected,
              apply: (c) =>
                  _colors = _colors.copyWith(bottomNavUnselected: c),
            ),
            _colorTile(
              title: tr("settings.theme.custom_color_divider"),
              color: _colors.dividerColor,
              apply: (c) => _colors = _colors.copyWith(dividerColor: c),
            ),
          ],
        ),
      ),
      context: context,
      canPop: true,
    );
  }
}
