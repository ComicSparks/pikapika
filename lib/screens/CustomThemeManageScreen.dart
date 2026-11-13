import 'package:flutter/material.dart';
import 'package:pikapika/basic/Common.dart';
import 'package:pikapika/basic/config/CustomTheme.dart';
import 'package:pikapika/basic/config/Themes.dart';
import 'package:pikapika/i18.dart';

import 'CustomThemeEditScreen.dart';
import 'components/ListView.dart';
import 'components/RightClickPop.dart';

class CustomThemeManageScreen extends StatefulWidget {
  const CustomThemeManageScreen({Key? key}) : super(key: key);

  @override
  State<CustomThemeManageScreen> createState() =>
      _CustomThemeManageScreenState();
}

class _CustomThemeManageScreenState extends State<CustomThemeManageScreen> {
  Future<void> _refresh() async {
    setState(() {});
  }

  Future<void> _copyFromExisting() async {
    final builtins = builtinThemeRefs();
    final customs = customThemes;
    final selected = await showDialog<_CopySource>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(tr("settings.theme.custom_copy_from")),
          children: [
            ...builtins.map(
              (e) => SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(_CopySource.builtin(e)),
                child: Text(e.name),
              ),
            ),
            if (customs.isNotEmpty) const Divider(),
            ...customs.map(
              (e) => SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(_CopySource.custom(e)),
                child: Text(e.name),
              ),
            ),
          ],
        );
      },
    );
    if (selected == null) {
      return;
    }
    late final CustomTheme created;
    if (selected.builtin != null) {
      created = await createCustomThemeFromBuiltin(selected.builtin!);
    } else {
      created = await createCustomThemeFromCustom(selected.custom!);
    }
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomThemeEditScreen(theme: created),
      ),
    );
    await _refresh();
  }

  Future<void> _importPkt() async {
    final theme = await importCustomThemeAndReload(context);
    if (theme != null && mounted) {
      defaultToast(context, tr("settings.theme.custom_import_success"));
      await _refresh();
    }
  }

  Future<void> _edit(CustomTheme theme) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomThemeEditScreen(theme: theme),
      ),
    );
    await _refresh();
  }

  Future<void> _export(CustomTheme theme) async {
    await exportCustomThemePkt(context, theme);
  }

  Future<void> _delete(CustomTheme theme) async {
    final ok = await confirmDialog(
      context,
      tr("settings.theme.custom_delete"),
      tr("settings.theme.custom_delete_confirm"),
    );
    if (!ok) {
      return;
    }
    await deleteCustomThemeById(theme.id);
    if (mounted) {
      defaultToast(context, tr("settings.theme.custom_delete_success"));
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themes = customThemes;
    return rightClickPop(
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr("settings.theme.custom_manage")),
          actions: [
            IconButton(
              tooltip: tr("settings.theme.custom_import"),
              onPressed: _importPkt,
              icon: const Icon(Icons.file_upload_outlined),
            ),
            IconButton(
              tooltip: tr("settings.theme.custom_copy_from"),
              onPressed: _copyFromExisting,
              icon: const Icon(Icons.copy_all_outlined),
            ),
          ],
        ),
        body: themes.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    tr("settings.theme.custom_empty"),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : PikaListView(
                children: themes.map((theme) {
                  return ListTile(
                    leading: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: theme.colors.primary,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade500),
                      ),
                    ),
                    title: Text(theme.name),
                    subtitle: Text(
                      theme.isDark
                          ? tr("settings.theme.custom_is_dark")
                          : tr("settings.theme.custom_is_light"),
                    ),
                    onTap: () => _edit(theme),
                    trailing: PopupMenuButton<_ThemeAction>(
                      onSelected: (action) async {
                        switch (action) {
                          case _ThemeAction.edit:
                            await _edit(theme);
                            break;
                          case _ThemeAction.export:
                            await _export(theme);
                            break;
                          case _ThemeAction.delete:
                            await _delete(theme);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: _ThemeAction.edit,
                          child: Text(tr("settings.theme.custom_edit")),
                        ),
                        PopupMenuItem(
                          value: _ThemeAction.export,
                          child: Text(tr("settings.theme.custom_export")),
                        ),
                        PopupMenuItem(
                          value: _ThemeAction.delete,
                          child: Text(tr("settings.theme.custom_delete")),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
      ),
      context: context,
      canPop: true,
    );
  }
}

enum _ThemeAction { edit, export, delete }

class _CopySource {
  final BuiltinThemeRef? builtin;
  final CustomTheme? custom;

  _CopySource.builtin(this.builtin) : custom = null;

  _CopySource.custom(this.custom) : builtin = null;
}
