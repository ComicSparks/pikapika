import 'package:flutter/material.dart';
import 'package:pikapika/i18.dart';

import '../Method.dart';

enum ReaderWheelMode { page, distance }

const _modeProperty = "readerWheelMode";
const _eventsProperty = "readerWheelEventsPerPage";
const _stepProperty = "readerWheelStepPercent";
const _noAnimationProperty = "readerWheelNoAnimation";

ReaderWheelMode _mode = ReaderWheelMode.page;
int _eventsPerPage = 1;
int _stepPercent = 50;
bool _wheelNoAnimation = false;

ReaderWheelMode get readerWheelMode => _mode;

int get readerWheelEventsPerPage => _eventsPerPage;

int get readerWheelStepPercent => _stepPercent;

double get readerWheelStepFraction => _stepPercent / 100;

bool readerWheelNoAnimation() => _wheelNoAnimation;

Future<void> initReaderWheel() async {
  _mode = (await method.loadProperty(_modeProperty, "page")) == "distance"
      ? ReaderWheelMode.distance
      : ReaderWheelMode.page;
  _eventsPerPage = _clampEvents(
    int.tryParse(await method.loadProperty(_eventsProperty, "1")) ?? 1,
  );
  _stepPercent = _clampStep(
    int.tryParse(await method.loadProperty(_stepProperty, "50")) ?? 50,
  );
  _wheelNoAnimation =
      (await method.loadProperty(_noAnimationProperty, "false")) == "true";
}

int _clampEvents(int value) => value.clamp(1, 4).toInt();

int _clampStep(int value) => value.clamp(10, 100).toInt();

String readerWheelModeName() => _mode == ReaderWheelMode.distance
    ? tr("settings.reader_wheel.distance")
    : tr("settings.reader_wheel.page");

Future<void> chooseReaderWheelMode(BuildContext context) async {
  final result = await showDialog<ReaderWheelMode>(
    context: context,
    builder: (BuildContext context) {
      return SimpleDialog(
        title: Text(tr("settings.reader_wheel.mode_choose")),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ReaderWheelMode.page),
            child: Text(tr("settings.reader_wheel.page")),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ReaderWheelMode.distance),
            child: Text(tr("settings.reader_wheel.distance")),
          ),
        ],
      );
    },
  );
  if (result == null) return;
  _mode = result;
  await method.saveProperty(
    _modeProperty,
    result == ReaderWheelMode.distance ? "distance" : "page",
  );
}

Future<void> setReaderWheelEventsPerPage(int value) async {
  _eventsPerPage = _clampEvents(value);
  await method.saveProperty(_eventsProperty, "$_eventsPerPage");
}

Future<void> setReaderWheelStepPercent(int value) async {
  _stepPercent = _clampStep(value);
  await method.saveProperty(_stepProperty, "$_stepPercent");
}

Future<void> setReaderWheelNoAnimation(bool value) async {
  _wheelNoAnimation = value;
  await method.saveProperty(_noAnimationProperty, "$value");
}

class ReaderWheelSettings extends StatefulWidget {
  const ReaderWheelSettings({Key? key}) : super(key: key);

  @override
  State<ReaderWheelSettings> createState() => _ReaderWheelSettingsState();
}

class _ReaderWheelSettingsState extends State<ReaderWheelSettings> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(tr("settings.reader_wheel.mode_title")),
          subtitle: Text(readerWheelModeName()),
          onTap: () async {
            await chooseReaderWheelMode(context);
            setState(() {});
          },
        ),
        ListTile(
          title: Text(
            "${tr("settings.reader_wheel.events_title")} : $_eventsPerPage",
          ),
          subtitle: Slider(
            min: 1,
            max: 4,
            divisions: 3,
            value: _eventsPerPage.toDouble(),
            onChanged: (double value) async {
              await setReaderWheelEventsPerPage(value.round());
              setState(() {});
            },
          ),
        ),
        ListTile(
          title: Text(
            "${tr("settings.reader_wheel.step_title")} : $_stepPercent%",
          ),
          subtitle: Slider(
            min: 10,
            max: 100,
            divisions: 90,
            value: _stepPercent.toDouble(),
            onChanged: (double value) async {
              await setReaderWheelStepPercent(value.round());
              setState(() {});
            },
          ),
        ),
        SwitchListTile(
          title: Text(tr("settings.reader_wheel.no_animation")),
          value: _wheelNoAnimation,
          onChanged: (bool value) async {
            await setReaderWheelNoAnimation(value);
            setState(() {});
          },
        ),
      ],
    );
  }
}
