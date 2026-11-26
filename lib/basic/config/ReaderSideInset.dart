import 'package:flutter/material.dart';
import 'package:pikapika/basic/Method.dart';
import 'package:pikapika/i18.dart';

enum ReaderSideInsetMode { percent, size }

const _modeProperty = "readerSideInsetMode";
const _portraitProperty = "readerSideInsetPortrait";
const _landscapeProperty = "readerSideInsetLandscape";
const double _minContent = 48;

late ReaderSideInsetMode _mode;
late double _portrait;
late double _landscape;

/// Bumped when a side-inset setting is saved, so an open reader can relayout.
final ValueNotifier<int> readerSideInsetListenable = ValueNotifier<int>(0);

ReaderSideInsetMode get readerSideInsetMode => _mode;
double get readerSideInsetPortrait => _portrait;
double get readerSideInsetLandscape => _landscape;

Future<void> initReaderSideInset() async {
  final mode = await method.loadProperty(_modeProperty, "percent");
  _mode = mode == "size" ? ReaderSideInsetMode.size : ReaderSideInsetMode.percent;
  _portrait = _stored(
    double.tryParse(await method.loadProperty(_portraitProperty, "0")) ?? 0,
  );
  _landscape = _stored(
    double.tryParse(await method.loadProperty(_landscapeProperty, "0")) ?? 0,
  );
}

double _stored(double value) {
  if (value < 0) return 0;
  final maxValue = _mode == ReaderSideInsetMode.percent ? 30.0 : 160.0;
  if (value > maxValue) return maxValue;
  return value;
}

void _notify() {
  readerSideInsetListenable.value++;
}

Future<void> setReaderSideInsetMode(ReaderSideInsetMode value) async {
  _mode = value;
  _portrait = _stored(_portrait);
  _landscape = _stored(_landscape);
  await method.saveProperty(
    _modeProperty,
    value == ReaderSideInsetMode.size ? "size" : "percent",
  );
  await method.saveProperty(_portraitProperty, _portrait.toStringAsFixed(0));
  await method.saveProperty(_landscapeProperty, _landscape.toStringAsFixed(0));
  _notify();
}

Future<void> setReaderSideInsetPortrait(double value) async {
  _portrait = _stored(value);
  await method.saveProperty(_portraitProperty, _portrait.toStringAsFixed(0));
  _notify();
}

Future<void> setReaderSideInsetLandscape(double value) async {
  _landscape = _stored(value);
  await method.saveProperty(_landscapeProperty, _landscape.toStringAsFixed(0));
  _notify();
}

String readerSideInsetModeName() {
  return _mode == ReaderSideInsetMode.size
      ? tr("settings.reader_side_inset.size")
      : tr("settings.reader_side_inset.percent");
}

String readerSideInsetValueLabel(double value) {
  final n = value.toStringAsFixed(0);
  if (_mode == ReaderSideInsetMode.percent) {
    return "${tr("settings.reader_side_inset.percent_each")} $n%";
  }
  return "${tr("settings.reader_side_inset.size_each")} $n";
}

/// Resting cross-axis inset for [viewport]. [verticalReader] leaves space on
/// the left and right; a horizontal reader leaves space on the top and bottom.
ReaderSideFrame readerSideFrame({
  required bool verticalReader,
  required Size viewport,
}) {
  final landscape = viewport.width > viewport.height;
  final stored = landscape ? _landscape : _portrait;
  final cross = verticalReader ? viewport.width : viewport.height;
  if (stored <= 0 || !(cross > _minContent)) {
    return const ReaderSideFrame(0);
  }
  final raw = _mode == ReaderSideInsetMode.percent
      ? cross * stored / 100.0
      : stored;
  final limit = (cross - _minContent) / 2;
  final inset = raw <= 0 ? 0.0 : (raw > limit ? limit : raw);
  return ReaderSideFrame(inset);
}

EdgeInsets readerSidePaddingOf(
  BuildContext context,
  BoxConstraints constraints, {
  required bool verticalReader,
}) {
  final width = constraints.maxWidth.isFinite
      ? constraints.maxWidth
      : MediaQuery.sizeOf(context).width;
  final height = constraints.maxHeight.isFinite
      ? constraints.maxHeight
      : MediaQuery.sizeOf(context).height;
  return readerSideFrame(
    verticalReader: verticalReader,
    viewport: Size(width, height),
  ).padding(
    verticalReader: verticalReader,
    availableCross: verticalReader ? width : height,
  );
}

class ReaderSideFrame {
  final double inset;

  const ReaderSideFrame(this.inset);

  /// Cross-axis length left for the picture. Never below [_minContent] unless
  /// [available] itself is already smaller.
  double fit(double available) {
    if (!(available > _minContent)) {
      return available > 0 ? available : 0;
    }
    final limit = (available - _minContent) / 2;
    final used = inset <= 0 ? 0.0 : (inset > limit ? limit : inset);
    return available - used * 2;
  }

  Widget place(Widget child) {
    if (inset <= 0) return child;
    return Align(alignment: Alignment.center, child: child);
  }

  EdgeInsets padding({
    required bool verticalReader,
    required double availableCross,
  }) {
    if (!(availableCross > 0)) return EdgeInsets.zero;
    final side = (availableCross - fit(availableCross)) / 2;
    if (!(side > 0)) return EdgeInsets.zero;
    return verticalReader
        ? EdgeInsets.symmetric(horizontal: side)
        : EdgeInsets.symmetric(vertical: side);
  }
}

Future<void> chooseReaderSideInsetMode(BuildContext context) async {
  final choose = await showDialog<ReaderSideInsetMode>(
    context: context,
    builder: (BuildContext context) {
      return SimpleDialog(
        title: Text(tr("settings.reader_side_inset.mode_choose")),
        children: [
          SimpleDialogOption(
            child: Text(tr("settings.reader_side_inset.percent")),
            onPressed: () =>
                Navigator.of(context).pop(ReaderSideInsetMode.percent),
          ),
          SimpleDialogOption(
            child: Text(tr("settings.reader_side_inset.size")),
            onPressed: () =>
                Navigator.of(context).pop(ReaderSideInsetMode.size),
          ),
        ],
      );
    },
  );
  if (choose != null) {
    await setReaderSideInsetMode(choose);
  }
}

class ReaderSideInsetSettings extends StatefulWidget {
  const ReaderSideInsetSettings({Key? key}) : super(key: key);

  @override
  State<ReaderSideInsetSettings> createState() => _ReaderSideInsetSettingsState();
}

class _ReaderSideInsetSettingsState extends State<ReaderSideInsetSettings> {
  @override
  void initState() {
    super.initState();
    readerSideInsetListenable.addListener(_onChanged);
  }

  @override
  void dispose() {
    readerSideInsetListenable.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final maxValue = _mode == ReaderSideInsetMode.percent ? 30.0 : 160.0;
    return Column(
      children: [
        ListTile(
          title: Text(tr("settings.reader_side_inset.mode_title")),
          subtitle: Text(readerSideInsetModeName()),
          onTap: () => chooseReaderSideInsetMode(context),
        ),
        _slider(
          title: tr("settings.reader_side_inset.portrait"),
          value: _portrait,
          maxValue: maxValue,
          save: setReaderSideInsetPortrait,
        ),
        _slider(
          title: tr("settings.reader_side_inset.landscape"),
          value: _landscape,
          maxValue: maxValue,
          save: setReaderSideInsetLandscape,
        ),
      ],
    );
  }

  Widget _slider({
    required String title,
    required double value,
    required double maxValue,
    required Future<void> Function(double value) save,
  }) {
    final shown = value.clamp(0.0, maxValue).toDouble();
    return ListTile(
      title: Text("$title : ${readerSideInsetValueLabel(shown)}"),
      subtitle: Slider(
        min: 0,
        max: maxValue,
        divisions: maxValue.toInt(),
        value: shown,
        label: readerSideInsetValueLabel(shown),
        onChanged: (double next) => save(next.roundToDouble()),
      ),
    );
  }
}
