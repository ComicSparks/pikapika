import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pikapika/basic/Common.dart';
import 'package:pikapika/basic/Cross.dart';
import 'package:pikapika/basic/Method.dart';
import 'package:pikapika/i18.dart';

const customThemeCodePrefix = "custom:";
const _customsPropertyName = "theme.customs";
const pktFormat = "acg-custom-theme";
const _pktLegacyFormats = ["pikapika-theme"];
const _pktVersion = 1;

bool isPktThemeFormat(Object? format) {
  if (format is! String) {
    return false;
  }
  return format == pktFormat || _pktLegacyFormats.contains(format);
}

String customThemeCode(String id) => "$customThemeCodePrefix$id";

String? parseCustomThemeId(String? code) {
  if (code == null || !code.startsWith(customThemeCodePrefix)) {
    return null;
  }
  final id = code.substring(customThemeCodePrefix.length);
  return id.isEmpty ? null : id;
}

class CustomThemeColors {
  final Color primary;
  final Color scaffoldBackground;
  final Color cardColor;
  final Color appBarColor;
  final Color appBarForeground;
  final Color bottomNavBackground;
  final Color bottomNavSelected;
  final Color bottomNavUnselected;
  final Color dividerColor;

  const CustomThemeColors({
    required this.primary,
    required this.scaffoldBackground,
    required this.cardColor,
    required this.appBarColor,
    required this.appBarForeground,
    required this.bottomNavBackground,
    required this.bottomNavSelected,
    required this.bottomNavUnselected,
    required this.dividerColor,
  });

  CustomThemeColors copyWith({
    Color? primary,
    Color? scaffoldBackground,
    Color? cardColor,
    Color? appBarColor,
    Color? appBarForeground,
    Color? bottomNavBackground,
    Color? bottomNavSelected,
    Color? bottomNavUnselected,
    Color? dividerColor,
  }) {
    return CustomThemeColors(
      primary: primary ?? this.primary,
      scaffoldBackground: scaffoldBackground ?? this.scaffoldBackground,
      cardColor: cardColor ?? this.cardColor,
      appBarColor: appBarColor ?? this.appBarColor,
      appBarForeground: appBarForeground ?? this.appBarForeground,
      bottomNavBackground: bottomNavBackground ?? this.bottomNavBackground,
      bottomNavSelected: bottomNavSelected ?? this.bottomNavSelected,
      bottomNavUnselected: bottomNavUnselected ?? this.bottomNavUnselected,
      dividerColor: dividerColor ?? this.dividerColor,
    );
  }

  Map<String, String> toJson() => {
        "primary": colorToHex(primary),
        "scaffoldBackground": colorToHex(scaffoldBackground),
        "cardColor": colorToHex(cardColor),
        "appBarColor": colorToHex(appBarColor),
        "appBarForeground": colorToHex(appBarForeground),
        "bottomNavBackground": colorToHex(bottomNavBackground),
        "bottomNavSelected": colorToHex(bottomNavSelected),
        "bottomNavUnselected": colorToHex(bottomNavUnselected),
        "dividerColor": colorToHex(dividerColor),
      };

  factory CustomThemeColors.fromJson(
    Map<String, dynamic>? json, {
    required CustomThemeColors fallback,
  }) {
    if (json == null) {
      return fallback;
    }
    Color pick(String key, Color def) {
      final raw = json[key];
      if (raw is! String) {
        return def;
      }
      return parseColorHex(raw) ?? def;
    }

    return CustomThemeColors(
      primary: pick("primary", fallback.primary),
      scaffoldBackground:
          pick("scaffoldBackground", fallback.scaffoldBackground),
      cardColor: pick("cardColor", fallback.cardColor),
      appBarColor: pick("appBarColor", fallback.appBarColor),
      appBarForeground: pick("appBarForeground", fallback.appBarForeground),
      bottomNavBackground:
          pick("bottomNavBackground", fallback.bottomNavBackground),
      bottomNavSelected: pick("bottomNavSelected", fallback.bottomNavSelected),
      bottomNavUnselected:
          pick("bottomNavUnselected", fallback.bottomNavUnselected),
      dividerColor: pick("dividerColor", fallback.dividerColor),
    );
  }
}

class CustomTheme {
  final String id;
  final String name;
  final bool isDark;
  final CustomThemeColors colors;

  const CustomTheme({
    required this.id,
    required this.name,
    required this.isDark,
    required this.colors,
  });

  String get code => customThemeCode(id);

  CustomTheme copyWith({
    String? id,
    String? name,
    bool? isDark,
    CustomThemeColors? colors,
  }) {
    return CustomTheme(
      id: id ?? this.id,
      name: name ?? this.name,
      isDark: isDark ?? this.isDark,
      colors: colors ?? this.colors,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "isDark": isDark,
        "colors": colors.toJson(),
      };

  factory CustomTheme.fromJson(Map<String, dynamic> json) {
    final isDark = json["isDark"] == true;
    final fallback =
        isDark ? defaultDarkCustomColors : defaultLightCustomColors;
    return CustomTheme(
      id: (json["id"] as String?)?.isNotEmpty == true
          ? json["id"] as String
          : _newId(),
      name: (json["name"] as String?)?.trim().isNotEmpty == true
          ? (json["name"] as String).trim()
          : tr("settings.theme.custom_default_name"),
      isDark: isDark,
      colors: CustomThemeColors.fromJson(
        json["colors"] is Map<String, dynamic>
            ? json["colors"] as Map<String, dynamic>
            : null,
        fallback: fallback,
      ),
    );
  }
}

final CustomThemeColors defaultLightCustomColors = CustomThemeColors(
  primary: Colors.pink.shade200,
  scaffoldBackground: const Color(0xFFFAFAFA),
  cardColor: Colors.white,
  appBarColor: Colors.pink.shade200,
  appBarForeground: Colors.white,
  bottomNavBackground: Colors.white,
  bottomNavSelected: Colors.pink.shade300,
  bottomNavUnselected: Colors.grey.shade500,
  dividerColor: Colors.grey.shade200,
);

final CustomThemeColors defaultDarkCustomColors = CustomThemeColors(
  primary: Colors.pink.shade200,
  scaffoldBackground: const Color(0xFF303030),
  cardColor: const Color(0xFF424242),
  appBarColor: const Color(0xFF1E1E1E),
  appBarForeground: Colors.white,
  bottomNavBackground: Colors.grey.shade900,
  bottomNavSelected: Colors.white,
  bottomNavUnselected: Colors.grey.shade300,
  dividerColor: Colors.grey.shade500.withAlpha(70),
);

List<CustomTheme> _customThemes = [];

List<CustomTheme> get customThemes => List.unmodifiable(_customThemes);

CustomTheme? findCustomTheme(String id) {
  for (final theme in _customThemes) {
    if (theme.id == id) {
      return theme;
    }
  }
  return null;
}

CustomTheme? findCustomThemeByCode(String? code) {
  final id = parseCustomThemeId(code);
  if (id == null) {
    return null;
  }
  return findCustomTheme(id);
}

Future<void> initCustomThemes() async {
  final raw = await method.loadProperty(_customsPropertyName, "[]");
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      _customThemes = [];
      return;
    }
    _customThemes = decoded
        .whereType<Map>()
        .map((e) => CustomTheme.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  } catch (e, s) {
    print("加载自定义主题失败: $e\n$s");
    _customThemes = [];
  }
}

Future<void> _persistCustomThemes() async {
  await method.saveProperty(
    _customsPropertyName,
    jsonEncode(_customThemes.map((e) => e.toJson()).toList()),
  );
}

String _newId() {
  final rand = Random();
  final a = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
  final b = rand.nextInt(1 << 32).toRadixString(16);
  return "${a}_$b";
}

Future<CustomTheme> addCustomTheme(CustomTheme theme) async {
  final created = theme.id.isEmpty ? theme.copyWith(id: _newId()) : theme;
  _customThemes = [..._customThemes, created];
  await _persistCustomThemes();
  return created;
}

Future<void> updateCustomTheme(CustomTheme theme) async {
  final index = _customThemes.indexWhere((e) => e.id == theme.id);
  if (index < 0) {
    return;
  }
  final next = [..._customThemes];
  next[index] = theme;
  _customThemes = next;
  await _persistCustomThemes();
}

Future<bool> removeCustomTheme(String id) async {
  final before = _customThemes.length;
  _customThemes = _customThemes.where((e) => e.id != id).toList();
  if (_customThemes.length == before) {
    return false;
  }
  await _persistCustomThemes();
  return true;
}

ThemeData buildCustomThemeData(CustomTheme theme, ThemeData rawData) {
  final c = theme.colors;
  final brightness = theme.isDark ? Brightness.dark : Brightness.light;
  return rawData.copyWith(
    brightness: brightness,
    scaffoldBackgroundColor: c.scaffoldBackground,
    cardColor: c.cardColor,
    primaryColor: c.primary,
    dividerColor: c.dividerColor,
    colorScheme: (theme.isDark ? ColorScheme.dark : ColorScheme.light)(
      primary: c.primary,
      secondary: c.primary,
      outline: c.dividerColor,
      outlineVariant: c.dividerColor,
      surface: c.scaffoldBackground,
    ),
    appBarTheme: AppBarTheme(
      systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: c.appBarColor,
      ),
      color: c.appBarColor,
      foregroundColor: c.appBarForeground,
      iconTheme: IconThemeData(color: c.appBarForeground),
      titleTextStyle: TextStyle(
        color: c.appBarForeground,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: c.bottomNavBackground,
      selectedItemColor: c.bottomNavSelected,
      unselectedItemColor: c.bottomNavUnselected,
    ),
    dividerTheme: DividerThemeData(color: c.dividerColor),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.primary,
      selectionColor: c.primary.withAlpha(150),
      selectionHandleColor: c.primary.withAlpha(200),
    ),
    inputDecorationTheme: InputDecorationTheme(
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: c.primary),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: c.primary,
      inactiveTrackColor: c.primary.withAlpha(150),
      thumbColor: c.primary,
      overlayColor: c.primary.withAlpha(150),
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
    ),
  );
}

String colorToHex(Color color) {
  final value = color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
  return "#$value";
}

Color? parseColorHex(String raw) {
  var hex = raw.trim();
  if (hex.startsWith("#")) {
    hex = hex.substring(1);
  }
  if (hex.length == 6) {
    hex = "FF$hex";
  }
  if (hex.length != 8) {
    return null;
  }
  final value = int.tryParse(hex, radix: 16);
  if (value == null) {
    return null;
  }
  return Color(value);
}

Map<String, dynamic> customThemeToPkt(CustomTheme theme) => {
      "format": pktFormat,
      "version": _pktVersion,
      "name": theme.name,
      "isDark": theme.isDark,
      "colors": theme.colors.toJson(),
    };

CustomTheme customThemeFromPkt(Map<String, dynamic> json) {
  if (!isPktThemeFormat(json["format"])) {
    throw FormatException("invalid pkt format");
  }
  final version = json["version"];
  if (version is! int || version != _pktVersion) {
    throw FormatException("unsupported pkt version");
  }
  final isDark = json["isDark"] == true;
  final fallback =
      isDark ? defaultDarkCustomColors : defaultLightCustomColors;
  return CustomTheme(
    id: _newId(),
    name: (json["name"] as String?)?.trim().isNotEmpty == true
        ? (json["name"] as String).trim()
        : tr("settings.theme.custom_default_name"),
    isDark: isDark,
    colors: CustomThemeColors.fromJson(
      json["colors"] is Map<String, dynamic>
          ? json["colors"] as Map<String, dynamic>
          : null,
      fallback: fallback,
    ),
  );
}

String safePktFileName(String name) {
  final cleaned = name
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), "_")
      .trim();
  if (cleaned.isEmpty) {
    return "theme.pkt";
  }
  return cleaned.toLowerCase().endsWith(".pkt") ? cleaned : "$cleaned.pkt";
}

Future<CustomTheme?> importCustomThemePkt(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    dialogTitle: tr("settings.theme.custom_import"),
    type: FileType.any,
    withData: true,
  );
  if (result == null || result.files.isEmpty) {
    return null;
  }
  final file = result.files.first;
  try {
    late final String content;
    if (file.bytes != null) {
      content = utf8.decode(file.bytes!);
    } else if (file.path != null) {
      content = await File(file.path!).readAsString();
    } else {
      throw Exception("empty file");
    }
    final decoded = jsonDecode(content);
    if (decoded is! Map) {
      throw FormatException("pkt root must be object");
    }
    final theme = customThemeFromPkt(Map<String, dynamic>.from(decoded));
    await addCustomTheme(theme);
    return theme;
  } catch (e, s) {
    print("导入自定义主题失败: $e\n$s");
    if (context.mounted) {
      defaultToast(context, tr("settings.theme.custom_import_failed"));
    }
    return null;
  }
}

Future<bool> exportCustomThemePkt(
  BuildContext context,
  CustomTheme theme,
) async {
  final fileName = safePktFileName(theme.name);
  final content =
      const JsonEncoder.withIndent("  ").convert(customThemeToPkt(theme));
  try {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: tr("settings.theme.custom_export"),
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ["pkt"],
      );
      if (path == null) {
        return false;
      }
      final out = path.toLowerCase().endsWith(".pkt") ? path : "$path.pkt";
      await File(out).writeAsString(content);
    } else {
      final folder = await chooseFolder(context);
      if (folder == null) {
        return false;
      }
      await File("$folder${Platform.pathSeparator}$fileName")
          .writeAsString(content);
    }
    if (context.mounted) {
      defaultToast(context, tr("settings.theme.custom_export_success"));
    }
    return true;
  } catch (e, s) {
    print("导出自定义主题失败: $e\n$s");
    if (context.mounted) {
      defaultToast(context, tr("settings.theme.custom_export_failed"));
    }
    return false;
  }
}

Future<Color?> showColorPickerDialog(
  BuildContext context, {
  required Color initial,
  required String title,
}) async {
  final presets = <Color>[
    Colors.pink.shade200,
    Colors.pink.shade300,
    Colors.red.shade400,
    Colors.orange.shade400,
    Colors.amber.shade600,
    Colors.green.shade400,
    Colors.teal.shade400,
    Colors.blue.shade200,
    Colors.blue.shade400,
    Colors.indigo.shade400,
    Colors.purple.shade300,
    Colors.brown.shade400,
    Colors.grey.shade200,
    Colors.grey.shade500,
    Colors.grey.shade800,
    Colors.black,
    Colors.white,
    const Color(0xFF1E1E1E),
    const Color(0xFF20253B),
    const Color(0xFF191B26),
    const Color(0xFFFAFAFA),
    const Color(0xFF303030),
  ];

  var current = initial;
  final controller = TextEditingController(text: colorToHex(initial));

  final result = await showDialog<Color>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: current,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: tr("settings.theme.custom_color_hex"),
                      hintText: "#AARRGGBB",
                    ),
                    onChanged: (value) {
                      final parsed = parseColorHex(value);
                      if (parsed != null) {
                        setState(() {
                          current = parsed;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: presets.map((color) {
                      final selected = color.toARGB32() == current.toARGB32();
                      return InkWell(
                        onTap: () {
                          setState(() {
                            current = color;
                            controller.text = colorToHex(color);
                          });
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.shade500,
                              width: selected ? 2.5 : 1,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              MaterialButton(
                child: Text(tr("app.cancel")),
                onPressed: () => Navigator.of(context).pop(),
              ),
              MaterialButton(
                child: Text(tr("app.confirm")),
                onPressed: () {
                  final parsed = parseColorHex(controller.text) ?? current;
                  Navigator.of(context).pop(parsed);
                },
              ),
            ],
          );
        },
      );
    },
  );
  controller.dispose();
  return result;
}
