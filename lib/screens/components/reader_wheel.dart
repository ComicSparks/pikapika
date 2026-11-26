import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class ReaderWheelRange {
  final double min;
  final double max;

  const ReaderWheelRange(this.min, this.max);
}

/// Mouse-wheel paging. One accepted event is one step. Events in the same
/// frame collapse into that step. Page mode counts steps, and while a page
/// animation is running at most one extra page is queued. Distance mode adds
/// each step to a target and follows it with an exponential curve.
class ReaderWheel {
  ReaderWheel({
    required this.turnPage,
    required this.readOffset,
    required this.jumpOffset,
    required this.viewport,
    required this.limits,
    required this.pageMode,
    required this.eventsPerPage,
    required this.stepFraction,
    required this.noAnimation,
  });

  final Future<void> Function(int direction) turnPage;
  final double? Function() readOffset;
  final void Function(double offset) jumpOffset;
  final double Function() viewport;
  final ReaderWheelRange? Function() limits;
  final bool Function() pageMode;
  final int Function() eventsPerPage;
  final double Function() stepFraction;
  final bool Function() noAnimation;

  bool _disposed = false;
  int _coalescedSign = 0;
  bool _coalesceScheduled = false;
  int _pageTicks = 0;
  bool _pageBusy = false;
  int _queuedSign = 0;
  double? _target;
  bool _following = false;
  Duration? _lastStamp;

  void dispose() {
    _disposed = true;
    _following = false;
    _target = null;
  }

  void onScroll(PointerScrollEvent event) {
    if (_disposed) return;
    if (event.kind != PointerDeviceKind.mouse) return;
    final dy = event.scrollDelta.dy;
    final dx = event.scrollDelta.dx;
    final delta = dy.abs() >= dx.abs() ? dy : dx;
    if (delta == 0) return;
    _coalescedSign = delta > 0 ? 1 : -1;
    if (_coalesceScheduled) return;
    _coalesceScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _coalesceScheduled = false;
      if (_disposed) return;
      final sign = _coalescedSign;
      _coalescedSign = 0;
      if (sign != 0) _accept(sign);
    });
  }

  void _accept(int sign) {
    if (pageMode()) {
      _pageTicks++;
      final need = eventsPerPage().clamp(1, 4);
      if (_pageTicks < need) return;
      _pageTicks = 0;
      _queuePage(sign);
      return;
    }
    final extent = viewport();
    if (!(extent > 0)) return;
    final fraction = stepFraction().clamp(0.10, 1.0);
    final step = extent * fraction * sign;
    if (noAnimation()) {
      _target = null;
      _following = false;
      final current = readOffset();
      if (current == null) return;
      jumpOffset(current + step);
      return;
    }
    final base = _target ?? readOffset();
    if (base == null) return;
    final range = limits();
    if (range == null) return;
    _target = _clamp(base + step, range.min, range.max);
    _ensureFollow();
  }

  void _queuePage(int sign) {
    if (_pageBusy) {
      _queuedSign = sign;
      return;
    }
    _pageBusy = true;
    Future<void> pending;
    try {
      pending = turnPage(sign);
    } catch (_) {
      pending = Future<void>.value();
    }
    pending.catchError((Object _) {}).whenComplete(() {
      if (_disposed) return;
      _pageBusy = false;
      final queued = _queuedSign;
      _queuedSign = 0;
      if (queued != 0) _queuePage(queued);
    });
  }

  void _ensureFollow() {
    if (_following) return;
    _following = true;
    _lastStamp = null;
    SchedulerBinding.instance.scheduleFrameCallback(_onFrame);
  }

  void _onFrame(Duration stamp) {
    if (_disposed || !_following || _target == null) {
      _following = false;
      _lastStamp = null;
      return;
    }
    final current = readOffset();
    if (current == null) {
      _following = false;
      _target = null;
      _lastStamp = null;
      return;
    }
    final dt = _lastStamp == null
        ? 1 / 60
        : ((stamp - _lastStamp!).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastStamp = stamp;
    final k = 1 - math.exp(-dt / 0.10);
    final next = current + (_target! - current) * k;
    if ((_target! - next).abs() < 0.5) {
      jumpOffset(_target!);
      _target = null;
      _following = false;
      _lastStamp = null;
      return;
    }
    jumpOffset(next);
    SchedulerBinding.instance.scheduleFrameCallback(_onFrame);
  }

  double _clamp(double value, double min, double max) {
    if (max < min) return value.clamp(max, min).toDouble();
    return value.clamp(min, max).toDouble();
  }
}

/// Listens inside a page so this handler is registered before the [PageView].
Widget readerMouseWheel({
  required bool Function() enabled,
  required void Function(PointerScrollEvent event) onScroll,
  required Widget child,
}) {
  return Listener(
    behavior: HitTestBehavior.translucent,
    onPointerSignal: (PointerSignalEvent event) {
      if (!enabled()) return;
      if (event is! PointerScrollEvent ||
          event.kind != PointerDeviceKind.mouse ||
          event.scrollDelta == Offset.zero) {
        return;
      }
      GestureBinding.instance.pointerSignalResolver.register(event,
          (PointerSignalEvent event) {
        onScroll(event as PointerScrollEvent);
      });
    },
    child: child,
  );
}
