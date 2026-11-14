/// 内容繁简体转换 (仅影响显示)

import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_opencc_plus/flutter_opencc_plus.dart';
import 'package:pikapika/i18.dart';
import '../Common.dart';
import '../Method.dart';

enum ContentConvertMode {
  off,
  s2t,
  t2s,
}

const _propertyName = "contentConvertMode";
ContentConvertMode _mode = ContentConvertMode.off;
ZhConverter? _converter;
final Map<String, String> _cache = {};

final contentConvertEvent = Event<EventArgs>();

Future<void> initContentConvert() async {
  final value = await method.loadProperty(_propertyName, _mode.name);
  await _applyMode(ContentConvertMode.values.firstWhere(
    (e) => e.name == value,
    orElse: () => ContentConvertMode.off,
  ));
}

String? _dataDir;

Future<void> _applyMode(ContentConvertMode mode) async {
  _mode = mode;
  _cache.clear();
  _converter?.dispose();
  _converter = null;
  try {
    if (mode != ContentConvertMode.off) {
      // iOS/Android 的词库在资源包内, 需要异步解压后才能同步转换
      _dataDir ??= await resolveOpenCCDataDir();
    }
    switch (mode) {
      case ContentConvertMode.off:
        break;
      case ContentConvertMode.s2t:
        _converter = ZhConverter(OpenCCConfig.s2t, dataDir: _dataDir);
        break;
      case ContentConvertMode.t2s:
        _converter = ZhConverter(OpenCCConfig.t2s, dataDir: _dataDir);
        break;
    }
  } catch (e) {
    // 转换器不可用时退化为不转换
    debugPrint('content convert init failed: $e');
    _converter = null;
  }
}

/// 仅用于展示, 不要用于复制/编辑/保存/上传
String ccConvert(String raw) {
  final converter = _converter;
  if (converter == null || raw.isEmpty) {
    return raw;
  }
  return _cache.putIfAbsent(raw, () {
    if (_cache.length > 4000) {
      _cache.clear();
    }
    try {
      return converter.convert(raw);
    } catch (e) {
      return raw;
    }
  });
}

/// 设置变更时重建, 用于 Text.rich 等需要自行调用 ccConvert 的场景
class CcBuilder extends StatefulWidget {
  final Widget Function(BuildContext context) builder;

  const CcBuilder(this.builder);

  @override
  State<StatefulWidget> createState() => CcBuilderState();
}

class CcBuilderState extends State<CcBuilder> {
  @override
  void initState() {
    contentConvertEvent.subscribe(_onChanged);
    super.initState();
  }

  @override
  void dispose() {
    contentConvertEvent.unsubscribe(_onChanged);
    super.dispose();
  }

  void _onChanged(_) {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

/// 与 Text 用法一致, 显示时按设置转换繁简体
class CcText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final StrutStyle? strutStyle;

  const CcText(
    this.data, {
    Key? key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.strutStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CcBuilder(
      (context) => Text(
        ccConvert(data),
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: softWrap,
        strutStyle: strutStyle,
      ),
    );
  }
}

/// 与 SelectableText 用法一致, 选择复制得到转换后的文本
class CcSelectableText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;

  const CcSelectableText(
    this.data, {
    Key? key,
    this.style,
    this.textAlign,
    this.maxLines,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CcBuilder(
      (context) => SelectableText(
        ccConvert(data),
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
      ),
    );
  }
}

Widget contentConvertSetting() {
  return StatefulBuilder(
    builder: (BuildContext context, void Function(void Function()) setState) {
      final names = {
        ContentConvertMode.off: tr('settings.content_convert.off'),
        ContentConvertMode.s2t: tr('settings.content_convert.s2t'),
        ContentConvertMode.t2s: tr('settings.content_convert.t2s'),
      };
      return ListTile(
        title: Text(tr('settings.content_convert.title')),
        subtitle: Text(names[_mode]!),
        onTap: () async {
          final mode = await chooseMapDialog<ContentConvertMode>(
            context,
            {for (final e in names.entries) e.value: e.key},
            tr('settings.content_convert.title'),
          );
          if (mode != null) {
            await method.saveProperty(_propertyName, mode.name);
            await _applyMode(mode);
            contentConvertEvent.broadcast();
            setState(() {});
          }
        },
      );
    },
  );
}
