import 'dart:async';
import 'dart:io';

import 'package:another_xlider/another_xlider.dart';
import 'package:another_xlider/models/slider_step.dart';
import 'package:another_xlider/models/tooltip/tooltip.dart';
import 'package:another_xlider/models/trackbar.dart';
import 'package:pikapika/i18.dart';
import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:pikapika/basic/Common.dart';
import 'package:pikapika/basic/Cross.dart';
import 'package:pikapika/basic/Entities.dart';
import 'package:pikapika/basic/Method.dart';
import 'package:pikapika/basic/config/Address.dart';
import 'package:pikapika/basic/config/AutoFullScreen.dart';
import 'package:pikapika/basic/config/AutoFullScreenOnForward.dart';
import 'package:pikapika/basic/config/CategoriesColumnCount.dart';
import 'package:pikapika/basic/config/FullScreenAction.dart';
import 'package:pikapika/basic/config/ImageAddress.dart';
import 'package:pikapika/basic/config/ImageFilter.dart';
import 'package:pikapika/basic/config/KeyboardController.dart';
import 'package:pikapika/basic/config/NoAnimation.dart';
import 'package:pikapika/basic/config/DragRegionLock.dart';
import 'package:pikapika/basic/config/GestureSpeed.dart';
import 'package:pikapika/basic/config/Quality.dart';
import 'package:pikapika/basic/config/ReaderDirection.dart';
import 'package:pikapika/basic/config/ReaderSliderPosition.dart';
import 'package:pikapika/basic/config/ReaderTwoPageDirection.dart';
import 'package:pikapika/basic/config/ReaderType.dart';
import 'package:pikapika/basic/config/ThreeKeepRight.dart';
import 'package:pikapika/basic/config/VolumeController.dart';
import 'package:pikapika/screens/components/PkzImages.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:zoomable_positioned_list/zoomable_positioned_list.dart' as zoomable;
import 'gesture_zoom_box.dart';
import '../../basic/config/IconLoading.dart';
import '../../basic/config/ReaderBackgroundColor.dart';
import '../../basic/config/ReaderScrollByScreenPercentage.dart';
import '../../basic/config/WebToonScrollMode.dart';
import '../../basic/config/ReaderZoomScale.dart';
import '../../basic/config/UseApiLoadImage.dart';
import '../../basic/config/VolumeNextChapter.dart';
import '../FilePhotoViewScreen.dart';

import 'Images.dart';

///////////////

Event<_ReaderControllerEventArgs> _readerControllerEvent =
    Event<_ReaderControllerEventArgs>();

class _ReaderControllerEventArgs extends EventArgs {
  final String key;

  _ReaderControllerEventArgs(this.key);
}

Widget readerKeyboardHolder(Widget widget) {
  if (keyboardController &&
      (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    widget = RawKeyboardListener(
      focusNode: FocusNode(),
      child: widget,
      autofocus: true,
      onKey: (event) {
        if (event is RawKeyDownEvent) {
          if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
            _readerControllerEvent.broadcast(_ReaderControllerEventArgs("UP"));
          }
          if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
            _readerControllerEvent
                .broadcast(_ReaderControllerEventArgs("DOWN"));
          }
        }
      },
    );
  }
  return widget;
}

void _onVolumeEvent(dynamic args) {
  _readerControllerEvent.broadcast(_ReaderControllerEventArgs("$args"));
}

var _volumeListenCount = 0;

// 仅支持安卓
// 监听后会拦截安卓手机音量键
// 仅最后一次监听生效
// event可能为DOWN/UP
EventChannel volumeButtonChannel = const EventChannel("volume_button");
StreamSubscription? volumeS;

void addVolumeListen() {
  _volumeListenCount++;
  if (_volumeListenCount == 1) {
    volumeS =
        volumeButtonChannel.receiveBroadcastStream().listen(_onVolumeEvent);
  }
}

void delVolumeListen() {
  _volumeListenCount--;
  if (_volumeListenCount == 0) {
    volumeS?.cancel();
  }
}

///////////////////////////////////////////////////////////////////////////////

// 对Reader的传参以及封装

class PkzFile {
  final String pkzPath;
  final String path;

  PkzFile(this.pkzPath, this.path);
}

class ImageReaderItemPosition {
  final int index;
  final double itemLeadingEdge;
  final double itemTrailingEdge;

  ImageReaderItemPosition(
      this.index, this.itemLeadingEdge, this.itemTrailingEdge);
}

class ReaderImageInfo {
  final String fileServer;
  final String path;
  final String? downloadLocalPath;
  final int? width;
  final int? height;
  final String? format;
  final int? fileSize;
  final PkzFile? pkzFile;

  ReaderImageInfo(
    this.fileServer,
    this.path,
    this.downloadLocalPath,
    this.width,
    this.height,
    this.format,
    this.fileSize, {
    this.pkzFile,
  });
}

class ImageReaderStruct {
  final List<ReaderImageInfo> images;
  final bool fullScreen;
  final FutureOr<dynamic> Function(bool fullScreen) onFullScreenChange;
  final FutureOr<dynamic> Function(int) onPositionChange;
  final int? initPosition;
  final Map<int, String> epNameMap;
  final int epOrder;
  final String comicTitle;
  final FutureOr<dynamic> Function(int) onChangeEp;
  final FutureOr<dynamic> Function() onReloadEp;
  final FutureOr<dynamic> Function() onDownload;

  const ImageReaderStruct({
    required this.images,
    required this.fullScreen,
    required this.onFullScreenChange,
    required this.onPositionChange,
    this.initPosition,
    required this.epNameMap,
    required this.epOrder,
    required this.comicTitle,
    required this.onChangeEp,
    required this.onReloadEp,
    required this.onDownload,
  });
}

//

class ImageReader extends StatefulWidget {
  final ImageReaderStruct struct;

  const ImageReader(this.struct, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ImageReaderState();
}

class _ImageReaderState extends State<ImageReader> {
  // 记录初始方向
  final ReaderDirection _pagerDirection = gReaderDirection;

  // 记录初始阅读器类型
  final ReaderType _pagerType = currentReaderType();

  // 记录了控制器
  late final FullScreenAction _fullScreenAction = currentFullScreenAction();

  late final ReaderSliderPosition _readerSliderPosition =
      currentReaderSliderPosition();

  @override
  Widget build(BuildContext context) {
    return _ImageReaderContent(
      widget.struct,
      _pagerDirection,
      _pagerType,
      _fullScreenAction,
      _readerSliderPosition,
    );
  }
}

//

class _ImageReaderContent extends StatefulWidget {
  // 记录初始方向
  final ReaderDirection pagerDirection;

  // 记录初始阅读器类型
  final ReaderType pagerType;

  final FullScreenAction fullScreenAction;

  final ReaderSliderPosition readerSliderPosition;

  final ImageReaderStruct struct;

  const _ImageReaderContent(this.struct, this.pagerDirection, this.pagerType,
      this.fullScreenAction, this.readerSliderPosition);

  @override
  State<StatefulWidget> createState() {
    switch (pagerType) {
      case ReaderType.WEB_TOON:
        return _WebToonReaderState();
      case ReaderType.WEB_TOON_ZOOM:
        return _WebToonZoomReaderState();
      case ReaderType.GALLERY:
        return _GalleryReaderState();
      // case ReaderType.WEB_TOON_FREE_ZOOM:
      //   return _ListViewReaderState();
      case ReaderType.TWO_PAGE_GALLERY:
        return _TwoPageGalleryReaderState();
      default:
        throw Exception("ERROR READER TYPE");
    }
  }
}

abstract class _ImageReaderContentState extends State<_ImageReaderContent> {
  bool _sliderDragging = false;

  // 阅读器
  Widget _buildViewer();

  Widget _buildViewerProcess() {
    return Stack(
      children: [
        processImageFilter(_buildViewer()),
        if (_sliderDragging) _sliderDraggingText(),
      ],
    );
  }

  Widget _sliderDraggingText() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0x88000000),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          "${_slider + 1} / ${widget.struct.images.length}",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
          ),
        ),
      ),
    );
  }

  // 键盘, 音量键 等事件
  void _needJumpTo(int index, bool animation);

  void _needScrollForward();

  void _needScrollBackward();

  double? get _remainingScrollHeight => null;

  // 记录了是否切换了音量
  late bool _listVolume;
  
  // 屏幕上的多个块的信息
  List<ImageReaderItemPosition> _currentPositions = [];

  void _onPositionsChange(List<ImageReaderItemPosition> positions) {
    if (positions.isEmpty) return;
    _currentPositions = positions;
    var first = positions.reduce((a, b) => a.index < b.index ? a : b);
    _onCurrentChange(first.index);
  }

  void _commonWebToonScrollForward(
    Function(double offset) animateScroll,
    Function(int index) jumpTo,
  ) {
    if (currentWebToonScrollMode() == WebToonScrollMode.SCREEN) {
      double s;
      if (widget.pagerDirection == ReaderDirection.TOP_TO_BOTTOM) {
        s = MediaQuery.of(context).size.height;
      } else {
        s = MediaQuery.of(context).size.width;
      }
      var scrollSize = s * readerScrollByScreenPercentage;
      animateScroll(scrollSize);
    } else {
      if (_currentPositions.isNotEmpty) {
        var min =
            _currentPositions.reduce((a, b) => a.index < b.index ? a : b);
        var max =
            _currentPositions.reduce((a, b) => a.index > b.index ? a : b);
        if (min.index != max.index) {
          // 多个图片
          // 只要最后一个图片没有显示完全, 就把最后一个图片对齐
          if (max.itemTrailingEdge > 1) {
            jumpTo(max.index);
          } else {
            jumpTo(max.index + 1);
          }
        } else {
          // 一个图片
          jumpTo(max.index + 1);
        }
      } else {
        jumpTo(_current + 1);
      }
    }
  }

  void _commonWebToonScrollBackward(
    Function(double offset) animateScroll,
    Function(int index) jumpTo,
  ) {
    if (currentWebToonScrollMode() == WebToonScrollMode.SCREEN) {
      double s;
      if (widget.pagerDirection == ReaderDirection.TOP_TO_BOTTOM) {
        s = MediaQuery.of(context).size.height;
      } else {
        s = MediaQuery.of(context).size.width;
      }
      var scrollSize = s * readerScrollByScreenPercentage;
      animateScroll(-scrollSize);
    } else {
      if (_currentPositions.isNotEmpty) {
        var min =
            _currentPositions.reduce((a, b) => a.index < b.index ? a : b);
        // 第一张图片没有显示的部分超过10像素则对齐, 否则要显示更上一张
        var leading = min.itemLeadingEdge;
        var height = MediaQuery.of(context).size.height;
        if (leading < 0 && leading.abs() * height > 10) {
          jumpTo(min.index);
        } else {
          jumpTo(min.index - 1);
        }
      } else {
        jumpTo(_current - 1);
      }
    }
  }

  // 和初始化与翻页有关

  @override
  void initState() {
    _initCurrent();
    _readerControllerEvent.subscribe(_onPageControl);
    _listVolume = volumeController;
    if (_listVolume) {
      addVolumeListen();
    }
    super.initState();
  }

  @override
  void dispose() {
    _readerControllerEvent.unsubscribe(_onPageControl);
    if (_listVolume) {
      delVolumeListen();
    }
    super.dispose();
  }

  void _onPageControl(_ReaderControllerEventArgs? args) {
    if (args != null) {
      var event = args.key;
      switch (event) {
        case "UP":
          if (ReaderType.WEB_TOON == currentReaderType() ||
              // ReaderType.WEB_TOON_FREE_ZOOM == currentReaderType() ||
              (ReaderType.WEB_TOON_ZOOM == currentReaderType() &&
                  currentWebToonScrollMode() == WebToonScrollMode.SCREEN)) {
            _needScrollBackward();
            break;
          }
          if (_current > 0) {
            _needJumpTo(_current - 1, true);
          }
          break;
        case "DOWN":
          if (currentAutoFullScreenOnForward() && !widget.struct.fullScreen) {
            widget.struct.onFullScreenChange(true);
          }
          if (ReaderType.WEB_TOON == currentReaderType() ||
              // ReaderType.WEB_TOON_FREE_ZOOM == currentReaderType() ||
              (ReaderType.WEB_TOON_ZOOM == currentReaderType() &&
                  currentWebToonScrollMode() == WebToonScrollMode.SCREEN)) {
            _needScrollForward();
            if ((_remainingScrollHeight ?? 10000) < 100) {
              if (volumeNextChapter()) {
                final now = DateTime.now().millisecondsSinceEpoch;
                if (_noticeTime + 3000 > now) {
                  if (_hasNextEp()) {
                    _onNextAction();
                  } else {
                    defaultToast(context,
                        tr('components.image_reader.already_at_the_end'));
                  }
                } else {
                  _noticeTime = now;
                  defaultToast(context,
                      tr('components.image_reader.click_to_next_chapter'));
                }
              }
            }
            break;
          }
          int point = 1;
          if (ReaderType.TWO_PAGE_GALLERY == currentReaderType()) {
            point = 2;
          }
          if (_current < widget.struct.images.length - point) {
            _needJumpTo(_current + point, true);
          } else {
            if (volumeNextChapter()) {
              final now = DateTime.now().millisecondsSinceEpoch;
              if (_noticeTime + 3000 > now) {
                if (_hasNextEp()) {
                  _onNextAction();
                } else {
                  defaultToast(context, tr('components.image_reader.already_at_the_end'));
                }
              } else {
                _noticeTime = now;
                defaultToast(context, tr('components.image_reader.click_to_next_chapter'));
              }
            }
          }
          break;
      }
    }
  }

  int _noticeTime = 0;

  late int _startIndex;
  late int _current;
  late int _slider;
  bool? _hasNextEpCache;

  void _initCurrent() {
    if (widget.struct.initPosition != null &&
        widget.struct.images.length > widget.struct.initPosition!) {
      _startIndex = widget.struct.initPosition!;
    } else {
      _startIndex = 0;
    }
    _current = _startIndex;
    _slider = _startIndex;
  }

  void _onCurrentChange(int index) {
    if (index != _current) {
      setState(() {
        _current = index;
        _slider = index;
        widget.struct.onPositionChange(index);
      });
    }
  }

  // 与显示有关的方法

  @override
  Widget build(BuildContext context) {
    switch (currentFullScreenAction()) {
      // 按钮
      case FullScreenAction.CONTROLLER:
        return Stack(
          children: [
            _buildViewerProcess(),
            _buildBar(_buildFullScreenControllerStackItem()),
          ],
        );
      case FullScreenAction.TOUCH_ONCE:
        return Stack(
          children: [
            _buildTouchOnceControllerAction(_buildViewerProcess()),
            _buildBar(Container()),
          ],
        );
      case FullScreenAction.TOUCH_DOUBLE:
        return Stack(
          children: [
            _buildTouchDoubleControllerAction(_buildViewerProcess()),
            _buildBar(Container()),
          ],
        );
      case FullScreenAction.TOUCH_DOUBLE_ONCE_NEXT:
        return Stack(
          children: [
            _buildTouchDoubleOnceNextControllerAction(_buildViewerProcess()),
            _buildBar(Container()),
          ],
        );
      case FullScreenAction.THREE_AREA:
        return Stack(
          children: [
            _buildViewerProcess(),
            _buildBar(_buildThreeAreaControllerAction()),
          ],
        );
    }
  }

  Widget _buildBar(Widget child) {
    switch (widget.readerSliderPosition) {
      case ReaderSliderPosition.BOTTOM:
        return Column(
          children: [
            _buildAppBar(),
            Expanded(child: child),
            widget.struct.fullScreen
                ? Container()
                : Container(
                    height: 45,
                    color: const Color(0x88000000),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(width: 15),
                        IconButton(
                          icon: const Icon(Icons.fullscreen),
                          color: Colors.white,
                          onPressed: () {
                            widget.struct
                                .onFullScreenChange(!widget.struct.fullScreen);
                          },
                        ),
                        Container(width: 10),
                        Expanded(
                          child:
                          //widget.pagerType != ReaderType.WEB_TOON_FREE_ZOOM
                            //      ?
                              _buildSliderBottom()
                              //    : Container(),
                        ),
                        Container(width: 10),
                        IconButton(
                          icon: const Icon(Icons.skip_next_outlined),
                          color: Colors.white,
                          onPressed: _onNextAction,
                        ),
                        Container(width: 15),
                      ],
                    ),
                  ),
            widget.struct.fullScreen
                ? Container()
                : Container(
                    color: const Color(0x88000000),
                    child: SafeArea(
                      top: false,
                      child: Container(),
                    ),
                  ),
          ],
        );
      case ReaderSliderPosition.RIGHT:
        return Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: Stack(
                children: [
                  child,
                  _buildSliderRight(),
                ],
              ),
            ),
          ],
        );
      case ReaderSliderPosition.LEFT:
        return Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: Stack(
                children: [
                  child,
                  _buildSliderLeft(),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _buildAppBar() => widget.struct.fullScreen
      ? Container()
      : AppBar(
          title: Text(
              "${widget.struct.epNameMap[widget.struct.epOrder] ?? ""} - ${widget.struct.comicTitle}"),
          actions: [
            IconButton(
              onPressed: _onChooseEp,
              icon: const Icon(Icons.menu_open),
            ),
            IconButton(
              onPressed: _onMoreSetting,
              icon: const Icon(Icons.more_horiz),
            ),
          ],
        );

  Widget _buildSliderBottom() {
    return Column(
      children: [
        Expanded(child: Container()),
        SizedBox(
          height: 25,
          child: _buildSliderWidget(Axis.horizontal),
        ),
        Expanded(child: Container()),
      ],
    );
  }

  Widget _buildSliderLeft() => widget.struct.fullScreen
      ? Container()
      : Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 35,
              height: 300,
              decoration: const BoxDecoration(
                color: Color(0x66000000),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              padding:
                  const EdgeInsets.only(top: 10, bottom: 10, left: 6, right: 5),
              child: Center(
                child: _buildSliderWidget(Axis.vertical),
              ),
            ),
          ),
        );

  Widget _buildSliderRight() => widget.struct.fullScreen
      ? Container()
      : Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 35,
              height: 300,
              decoration: const BoxDecoration(
                color: Color(0x66000000),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
              padding:
                  const EdgeInsets.only(top: 10, bottom: 10, left: 5, right: 6),
              child: Center(
                child: _buildSliderWidget(Axis.vertical),
              ),
            ),
          ),
        );

  Widget _buildSliderWidget(Axis axis) {
    final pages = widget.struct.images.length;
    // another_xlider 3 要求 min <= max。没有图片或只有一页时不能用 length - 1。
    if (pages < 2) {
      return const SizedBox.shrink();
    }
    final last = pages - 1;
    return FlutterSlider(
      axis: axis,
      values: [_slider.clamp(0, last).toDouble()],
      min: 0,
      max: last.toDouble(),
      onDragStarted: (handlerIndex, lowerValue, upperValue) {
        setState(() {
          _sliderDragging = true;
        });
      },
      onDragging: (handlerIndex, lowerValue, upperValue) {
        setState(() {
          _slider = (lowerValue.toInt());
        });
      },
      onDragCompleted: (handlerIndex, lowerValue, upperValue) {
        setState(() {
          _sliderDragging = false;
        });
        _slider = (lowerValue.toInt());
        if (_slider != _current) {
          _needJumpTo(_slider, false);
        }
      },
      trackBar: FlutterSliderTrackBar(
        inactiveTrackBar: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey.shade300,
        ),
        activeTrackBar: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      step: const FlutterSliderStep(
        step: 1,
        isPercentRange: false,
      ),
      tooltip: FlutterSliderTooltip(disabled: true),
    );
  }

  Widget _buildFullScreenControllerStackItem() {
    if (widget.readerSliderPosition == ReaderSliderPosition.BOTTOM &&
        !widget.struct.fullScreen) {
      return Container();
    }
    if (widget.readerSliderPosition == ReaderSliderPosition.RIGHT) {
      return SafeArea(
          child: Align(
        alignment: Alignment.bottomRight,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding:
                const EdgeInsets.only(left: 10, right: 10, top: 4, bottom: 4),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
              color: Color(0x88000000),
            ),
            child: GestureDetector(
              onTap: () {
                widget.struct.onFullScreenChange(!widget.struct.fullScreen);
              },
              child: Icon(
                widget.struct.fullScreen
                    ? Icons.fullscreen_exit
                    : Icons.fullscreen_outlined,
                size: 30,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ));
    }
    return SafeArea(
        child: Align(
      alignment: Alignment.bottomLeft,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding:
              const EdgeInsets.only(left: 10, right: 10, top: 4, bottom: 4),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
            color: Color(0x88000000),
          ),
          child: GestureDetector(
            onTap: () {
              widget.struct.onFullScreenChange(!widget.struct.fullScreen);
            },
            child: Icon(
              widget.struct.fullScreen
                  ? Icons.fullscreen_exit
                  : Icons.fullscreen_outlined,
              size: 30,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ));
  }

  Widget _buildTouchOnceControllerAction(Widget child) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        widget.struct.onFullScreenChange(!widget.struct.fullScreen);
      },
      child: child,
    );
  }

  Widget _buildTouchDoubleControllerAction(Widget child) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onDoubleTap: () {
        widget.struct.onFullScreenChange(!widget.struct.fullScreen);
      },
      child: child,
    );
  }

  Widget _buildTouchDoubleOnceNextControllerAction(Widget child) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        _readerControllerEvent.broadcast(_ReaderControllerEventArgs("DOWN"));
      },
      onDoubleTap: () {
        widget.struct.onFullScreenChange(!widget.struct.fullScreen);
      },
      child: child,
    );
  }

  Widget _buildThreeAreaControllerAction() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        var up = Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              _readerControllerEvent
                  .broadcast(_ReaderControllerEventArgs("UP"));
            },
            child: Container(),
          ),
        );
        var down = Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              _readerControllerEvent
                  .broadcast(_ReaderControllerEventArgs("DOWN"));
            },
            child: Container(),
          ),
        );
        var fullScreen = Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () =>
                widget.struct.onFullScreenChange(!widget.struct.fullScreen),
            child: Container(),
          ),
        );
        late Widget child;
        switch (widget.pagerDirection) {
          case ReaderDirection.TOP_TO_BOTTOM:
            child = Column(children: [
              up,
              fullScreen,
              down,
            ]);
            break;
          case ReaderDirection.LEFT_TO_RIGHT:
            child = Row(children: [
              up,
              fullScreen,
              down,
            ]);
            break;
          case ReaderDirection.RIGHT_TO_LEFT:
            if (threeKeepRight) {
              child = Row(children: [
                up,
                fullScreen,
                down,
              ]);
              break;
            }
            child = Row(children: [
              down,
              fullScreen,
              up,
            ]);
            break;
        }
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: child,
        );
      },
    );
  }

  Future _onChooseEp() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xAA000000),
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * (.45),
          child: _EpChooser(
            widget.struct.epNameMap,
            widget.struct.epOrder,
            widget.struct.onChangeEp,
          ),
        );
      },
    );
  }

  Future _onMoreSetting() async {
    // 记录开始的画质
    final currentQuality = currentQualityCode();
    final cReaderSliderPosition = currentReaderSliderPosition();
    //
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xAA000000),
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * (.45),
          child: _SettingPanel(
            widget.struct.onReloadEp,
            widget.struct.onDownload,
          ),
        );
      },
    );
    setState(() {});
    if (widget.pagerDirection != gReaderDirection ||
        widget.pagerType != currentReaderType() ||
        currentQuality != currentQualityCode() ||
        widget.fullScreenAction != currentFullScreenAction() ||
        cReaderSliderPosition != currentReaderSliderPosition()) {
      widget.struct.onReloadEp();
    }
  }

  // 给子类调用的方法

  bool _fullscreenController() {
    switch (currentFullScreenAction()) {
      case FullScreenAction.CONTROLLER:
        return false;
      case FullScreenAction.TOUCH_ONCE:
        return false;
      case FullScreenAction.TOUCH_DOUBLE:
        return false;
      case FullScreenAction.TOUCH_DOUBLE_ONCE_NEXT:
        return false;
      case FullScreenAction.THREE_AREA:
        return true;
    }
  }

  Future _onNextAction() async {
    if (_hasNextEp()) {
      widget.struct.onChangeEp(widget.struct.epOrder + 1);
    } else {
      defaultToast(context, tr('components.image_reader.already_at_the_end'));
    }
  }

  bool _hasNextEp() {
    if (_hasNextEpCache != null) {
      return _hasNextEpCache!;
    }
    for (var element in widget.struct.epNameMap.keys) {
      if (element > widget.struct.epOrder) {
        _hasNextEpCache = true;
        return true;
      }
    }
    _hasNextEpCache = false;
    return false;
  }

  double _topBarHeight() => Scaffold.of(context).appBarMaxHeight ?? 0;

  double _bottomBarHeight() =>
      widget.readerSliderPosition == ReaderSliderPosition.BOTTOM ? 45 : 0;
}

class _EpChooser extends StatefulWidget {
  final Map<int, String> epNameMap;
  final int epOrder;
  final FutureOr Function(int) onChangeEp;

  _EpChooser(this.epNameMap, this.epOrder, this.onChangeEp);

  @override
  State<StatefulWidget> createState() => _EpChooserState();
}

class _EpChooserState extends State<_EpChooser> {
  @override
  Widget build(BuildContext context) {
    var entries = widget.epNameMap.entries.toList();
    entries.sort((a, b) => a.key - b.key);
    var widgets = [
      Container(height: 20),
      ...entries.map((e) {
        return Container(
          margin: const EdgeInsets.only(left: 15, right: 15, top: 5, bottom: 5),
          decoration: BoxDecoration(
            color: widget.epOrder == e.key ? Colors.grey.withAlpha(100) : null,
            border: Border.all(
              color: const Color(0xff484c60),
              style: BorderStyle.solid,
              width: .5,
            ),
          ),
          child: MaterialButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onChangeEp(e.key);
            },
            textColor: Colors.white,
            child: Text(e.value),
          ),
        );
      })
    ];
    return ScrollablePositionedList.builder(
      initialScrollIndex: widget.epOrder < 2 ? 0 : widget.epOrder - 2,
      itemCount: widgets.length,
      itemBuilder: (BuildContext context, int index) => widgets[index],
    );
  }
}

class _SettingPanel extends StatefulWidget {
  final FutureOr Function() onReloadEp;
  final FutureOr Function() onDownload;

  _SettingPanel(this.onReloadEp, this.onDownload);

  @override
  State<StatefulWidget> createState() => _SettingPanelState();
}

class _SettingPanelState extends State<_SettingPanel> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(15),
      children: [
        _chooseTile(
          icon: Icons.crop_sharp,
          title: tr("settings.reader_direction.title"),
          value: gReaderDirectionName(),
          onTap: () async {
            await choosePagerDirection(context);
            setState(() {});
          },
        ),
        _chooseTile(
          icon: Icons.view_day_outlined,
          title: tr("settings.reader_type.title"),
          value: currentReaderTypeName(),
          onTap: () async {
            await choosePagerType(context);
            setState(() {});
          },
        ),
        _chooseTile(
          icon: Icons.image_aspect_ratio_outlined,
          title: tr("settings.quality.title"),
          value: currentQualityName(),
          onTap: () async {
            await chooseQuality(context);
            setState(() {});
          },
        ),
        _chooseTile(
          icon: Icons.control_camera_outlined,
          title: tr("settings.full_screen_action.title"),
          value: currentFullScreenActionName(),
          onTap: () async {
            await chooseFullScreenAction(context);
            setState(() {});
          },
        ),
        const Divider(color: Colors.white24),
        _chooseTile(
          icon: Icons.swap_vert,
          title: tr("settings.web_toon_scroll_mode.title"),
          value: currentWebToonScrollModeName(),
          onTap: () async {
            await chooseWebToonScrollMode(context);
            setState(() {});
          },
        ),
        _sliderTile(
          icon: Icons.straighten,
          title: tr("settings.reader_scroll_by_screen_percentage.title"),
          valueLabel:
              "${currentReaderScrollByScreenPercentage()}%${tr("settings.reader_scroll_by_screen_percentage.screen_size")}",
          min: 5,
          max: 110,
          divisions: 110 - 5,
          value: currentReaderScrollByScreenPercentage().toDouble(),
          onChanged: (v) async {
            await setReaderScrollByScreenPercentage(v.toInt());
            setState(() {});
          },
        ),
        const Divider(color: Colors.white24),
        _sliderTile(
          icon: Icons.zoom_out_map,
          title: tr("settings.reader_zoom.out_title"),
          valueLabel: "${readerZoomMinScale.toStringAsFixed(1)}x",
          min: 0.1,
          max: 1.0,
          divisions: 9,
          value: readerZoomMinScale.clamp(0.1, 1.0).toDouble(),
          onChanged: (v) async {
            final newValue = (v * 10).roundToDouble() / 10;
            await setReaderZoomMinScale(newValue);
            setState(() {});
          },
        ),
        _sliderTile(
          icon: Icons.zoom_in,
          title: tr("settings.reader_zoom.in_title"),
          valueLabel: "${readerZoomMaxScale.toStringAsFixed(1)}x",
          min: 1.0,
          max: 30.0,
          divisions: 29,
          value: readerZoomMaxScale.clamp(1.0, 30.0).toDouble(),
          onChanged: (v) async {
            final newValue = v.roundToDouble();
            await setReaderZoomMaxScale(newValue);
            setState(() {});
          },
        ),
        _sliderTile(
          icon: Icons.touch_app,
          title: tr("settings.reader_zoom.double_tap_title"),
          valueLabel: "${readerZoomDoubleTapScale.toStringAsFixed(1)}x",
          min: 1.5,
          max: 5.0,
          divisions: 7,
          value: readerZoomDoubleTapScale.clamp(1.5, 5.0).toDouble(),
          onChanged: (v) async {
            final newValue = (v * 2).roundToDouble() / 2;
            await setReaderZoomDoubleTapScale(newValue);
            setState(() {});
          },
        ),
        _switchTile(
          icon: Icons.border_inner,
          title: tr('settings.drag_region_lock.title'),
          value: dragRegionLock(),
          onChanged: (v) async {
            await setDragRegionLock(v);
            setState(() {});
          },
        ),
        _sliderTile(
          icon: Icons.speed,
          title: tr('settings.gesture_speed.title'),
          valueLabel: "${currentGestureSpeed().toStringAsFixed(1)}x",
          min: 0.1,
          max: 5.0,
          divisions: 49,
          value: currentGestureSpeed(),
          onChanged: (v) async {
            await setGestureSpeed(v);
            setState(() {});
          },
        ),
        _switchTile(
          icon: Icons.arrow_downward,
          title: tr("settings.auto_full_screen_on_forward.title"),
          value: currentAutoFullScreenOnForward(),
          onChanged: (v) async {
            await setAutoFullScreenOnForward(v);
            setState(() {});
          },
        ),
        const Divider(color: Colors.white24),
        _chooseTile(
          icon: Icons.share,
          title: tr('net.address'),
          value: currentAddressName(),
          onTap: () async {
            await chooseAddressAndSwitch(context);
            setState(() {});
          },
        ),
        _chooseTile(
          icon: Icons.image_search,
          title: tr('settings.image_address.title'),
          value: currentImageAddressName(),
          onTap: () async {
            await chooseImageAddress(context);
            setState(() {});
          },
        ),
        _chooseTile(
          icon: Icons.network_ping,
          title: tr('net.use_api_load_image'),
          value: currentUseApiLoadImageName(),
          onTap: () async {
            await chooseUseApiLoadImage(context);
            setState(() {});
          },
        ),
        const Divider(color: Colors.white24),
        _switchTile(
          icon: Icons.access_time_filled_outlined,
          title: tr('settings.no_animation.title'),
          value: noAnimation(),
          onChanged: (v) async {
            await setNoAnimation(v);
            setState(() {});
          },
        ),
        _actionTile(
          icon: Icons.refresh,
          title: tr('components.image_reader.reload_page'),
          onTap: () {
            Navigator.of(context).pop();
            widget.onReloadEp();
          },
        ),
      ],
    );
  }

  Widget _chooseTile({
    required IconData icon,
    required String title,
    required String value,
    required FutureOr<void> Function() onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 100),
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Colors.white70),
        ],
      ),
      onTap: () async => await onTap(),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white70),
      onTap: onTap,
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required bool value,
    required FutureOr<void> Function(bool) onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: Switch(
        value: value,
        onChanged: (v) async => await onChanged(v),
        activeColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  Widget _sliderTile({
    required IconData icon,
    required String title,
    required String valueLabel,
    required double min,
    required double max,
    required int divisions,
    required double value,
    required FutureOr<void> Function(double) onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Row(
        children: [
          Expanded(
            child: Slider(
              min: min,
              max: max,
              divisions: divisions,
              value: value,
              onChanged: (v) async => await onChanged(v),
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              valueLabel,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

///////////////////////////////////////////////////////////////////////////////

class _WebToonReaderState extends _ImageReaderContentState {
  var _controllerTime = DateTime.now().millisecondsSinceEpoch + 400;
  late final List<Size?> _trueSizes = [];
  late final zoomable.ItemScrollController _itemScrollController;
  late final zoomable.ItemPositionsListener _itemPositionsListener;
  late final zoomable.ScrollOffsetController _scrollOffsetController;
  late final zoomable.ScrollOffsetListener _scrollOffsetListener;
  StreamSubscription<double>? _scrollOffsetSubscription;

  @override
  void initState() {
    for (var e in widget.struct.images) {
      if (e.pkzFile != null &&
          e.width != null &&
          e.height != null &&
          e.width! > 0 &&
          e.height! > 0) {
        _trueSizes.add(Size(e.width!.toDouble(), e.height!.toDouble()));
      } else if (e.downloadLocalPath != null) {
        _trueSizes.add(Size(e.width!.toDouble(), e.height!.toDouble()));
      } else {
        _trueSizes.add(null);
      }
    }
    _itemScrollController = zoomable.ItemScrollController();
    _itemPositionsListener = zoomable.ItemPositionsListener.create();
    _itemPositionsListener.itemPositions.addListener(_onListCurrentChange);
    _scrollOffsetController = zoomable.ScrollOffsetController();
    _scrollOffsetListener = zoomable.ScrollOffsetListener.create();
    _scrollOffsetSubscription = _scrollOffsetListener.changes.listen(_onScroll);
    super.initState();
  }

  void _onScroll(double delta) {
    if (currentAutoFullScreenOnForward() && !widget.struct.fullScreen) {
      if (delta > 0) {
        widget.struct.onFullScreenChange(true);
      }
    }
  }

  @override
  double? get _remainingScrollHeight {
    try {
      return _scrollOffsetController.maxScrollExtent -
          _scrollOffsetController.offset;
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_onListCurrentChange);
    _scrollOffsetSubscription?.cancel();
    super.dispose();
  }

  void _onListCurrentChange() {
    var positions = _itemPositionsListener.itemPositions.value;
    if (positions.isNotEmpty) {
      super._onPositionsChange(positions
          .map((e) => ImageReaderItemPosition(
              e.index, e.itemLeadingEdge, e.itemTrailingEdge))
          .toList());
    }
  }

  @override
  void _needJumpTo(int index, bool animation) {
    if (noAnimation() || animation == false) {
      _itemScrollController.jumpTo(
        index: index,
      );
    } else {
      if (DateTime.now().millisecondsSinceEpoch < _controllerTime) {
        return;
      }
      _controllerTime = DateTime.now().millisecondsSinceEpoch + 400;
      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 400),
      );
    }
  }

  @override
  void _needScrollForward() {
    _commonWebToonScrollForward(
      (offset) {
        _scrollOffsetController.animateScroll(
          offset: offset,
          duration: noAnimation()
              ? Duration.zero
              : const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      },
      (index) {
        _needJumpTo(index, true);
      },
    );
  }

  @override
  void _needScrollBackward() {
    _commonWebToonScrollBackward(
      (offset) {
        _scrollOffsetController.animateScroll(
          offset: offset,
          duration: noAnimation()
              ? Duration.zero
              : const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      },
      (index) {
        _needJumpTo(index, true);
      },
    );
  }

  @override
  Widget _buildViewer() {
    return Container(
      decoration: BoxDecoration(
        color: readerBackgroundColorObj,
      ),
      child: _buildList(),
    );
  }

  Widget _buildList() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // reload _images size
        List<Widget> _images = [];
        for (var index = 0; index < widget.struct.images.length; index++) {
          late Size renderSize;
          if (_trueSizes[index] != null) {
            if (widget.pagerDirection == ReaderDirection.TOP_TO_BOTTOM) {
              renderSize = Size(
                constraints.maxWidth,
                constraints.maxWidth *
                    _trueSizes[index]!.height /
                    _trueSizes[index]!.width,
              );
            } else {
              var maxHeight = constraints.maxHeight -
                  super._topBarHeight() -
                  super._bottomBarHeight() -
                  MediaQuery.of(context).padding.bottom;
              renderSize = Size(
                maxHeight *
                    _trueSizes[index]!.width /
                    _trueSizes[index]!.height,
                maxHeight,
              );
            }
          } else {
            if (widget.pagerDirection == ReaderDirection.TOP_TO_BOTTOM) {
              renderSize = Size(constraints.maxWidth, constraints.maxWidth / 2);
            } else {
              // ReaderDirection.LEFT_TO_RIGHT
              // ReaderDirection.RIGHT_TO_LEFT
              renderSize =
                  Size(constraints.maxWidth / 2, constraints.maxHeight);
            }
          }
          var currentIndex = index;
          onTrueSize(Size size) {
            setState(() {
              _trueSizes[currentIndex] = size;
            });
          }

          var e = widget.struct.images[index];
          if (e.pkzFile != null) {
            _images.add(_WebToonPkzImage(
              width: e.width!,
              height: e.height!,
              format: e.format!,
              size: renderSize,
              onTrueSize: onTrueSize,
              pkzFile: e.pkzFile!,
            ));
          } else if (e.downloadLocalPath != null) {
            _images.add(_WebToonDownloadImage(
              fileServer: e.fileServer,
              path: e.path,
              localPath: e.downloadLocalPath!,
              fileSize: e.fileSize!,
              width: e.width!,
              height: e.height!,
              format: e.format!,
              size: renderSize,
              onTrueSize: onTrueSize,
            ));
          } else {
            _images.add(_WebToonRemoteImage(
              e.fileServer,
              e.path,
              renderSize,
              onTrueSize,
            ));
          }
        }
        return zoomable.ZoomablePositionedList.builder(
          enableZoom: false,
          scrollOffsetController: _scrollOffsetController,
          scrollOffsetListener: _scrollOffsetListener,
          initialScrollIndex: super._startIndex,
          scrollDirection:
              widget.pagerDirection == ReaderDirection.TOP_TO_BOTTOM
                  ? Axis.vertical
                  : Axis.horizontal,
          reverse: widget.pagerDirection == ReaderDirection.RIGHT_TO_LEFT,
          padding: EdgeInsets.only(
            // 不管全屏与否, 滚动方向如何, 顶部永远保持间距
            top: super._topBarHeight(),
            bottom: widget.pagerDirection == ReaderDirection.TOP_TO_BOTTOM
                ? 130 // 纵向滚动 底部永远都是130的空白
                : (super._bottomBarHeight() +
                    MediaQuery.of(context).padding.bottom)
            // 非全屏时, 顶部去掉顶部BAR的高度, 底部去掉底部BAR的高度, 形成看似填充的效果
            ,
          ),
          itemScrollController: _itemScrollController,
          itemPositionsListener: _itemPositionsListener,
          itemCount: widget.struct.images.length + 1,
          itemBuilder: (BuildContext context, int index) {
            if (index >= widget.struct.images.length) {
              return _buildNextEp();
            }
            return _images[index];
          },
        );
      },
    );
  }

  Widget _buildNextEp() {
    if (super._fullscreenController()) {
      return Container();
    }
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.all(20),
      child: MaterialButton(
        onPressed: () {
          if (super._hasNextEp()) {
            super._onNextAction();
          } else {
            Navigator.of(context).pop();
          }
        },
        textColor: invertColor(readerBackgroundColorObj),
        child: Container(
          padding: const EdgeInsets.only(top: 40, bottom: 40),
          child: Text(super._hasNextEp() ? tr('components.image_reader.next_chapter') : tr('components.image_reader.end_reading')),
        ),
      ),
    );
  }
}

// 来自下载
class _WebToonDownloadImage extends _WebToonReaderImage {
  final String fileServer;
  final String path;
  final String localPath;
  final int fileSize;
  final int width;
  final int height;
  final String format;

  _WebToonDownloadImage({
    required this.fileServer,
    required this.path,
    required this.localPath,
    required this.fileSize,
    required this.width,
    required this.height,
    required this.format,
    required Size size,
    Function(Size)? onTrueSize,
  }) : super(size, onTrueSize);

  @override
  Future<RemoteImageData> imageData() async {
    if (localPath == "") {
      return method.remoteImageData(fileServer, path);
    }
    var finalPath = await method.downloadImagePath(localPath);
    return RemoteImageData(
      fileSize: fileSize,
      format: format,
      width: width,
      height: height,
      finalPath: finalPath,
    );
  }
}

// 来自PKZ
class _WebToonPkzImage extends StatelessWidget {
  final PkzFile pkzFile;
  final int width;
  final int height;
  final String format;
  final Size size;
  Function(Size)? onTrueSize;

  _WebToonPkzImage({
    required this.pkzFile,
    required this.width,
    required this.height,
    required this.format,
    required this.size,
    required this.onTrueSize,
  });

  @override
  Widget build(BuildContext context) {
    return PkzLoadingImage(
      pkzPath: pkzFile.pkzPath,
      path: pkzFile.path,
      width: size.width,
      height: size.height,
      onTrueSize: onTrueSize,
    );
  }
}

// 来自远端
class _WebToonRemoteImage extends _WebToonReaderImage {
  final String fileServer;
  final String path;

  _WebToonRemoteImage(
    this.fileServer,
    this.path,
    Size size,
    Function(Size)? onTrueSize,
  ) : super(size, onTrueSize);

  @override
  Future<RemoteImageData> imageData() async {
    return method.remoteImageData(fileServer, path);
  }
}

// 通用
abstract class _WebToonReaderImage extends StatefulWidget {
  final Size size;
  final Function(Size)? onTrueSize;

  _WebToonReaderImage(this.size, this.onTrueSize);

  @override
  State<StatefulWidget> createState() => _WebToonReaderImageState();

  Future<RemoteImageData> imageData();
}

class _WebToonReaderImageState extends State<_WebToonReaderImage> {
  late Future<RemoteImageData> _future = _load();

  Future<RemoteImageData> _load() {
    return widget.imageData().then((value) {
      widget.onTrueSize?.call(
        Size(value.width.toDouble(), value.height.toDouble()),
      );
      return value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return FutureBuilder(
          future: _future,
          builder: (
            BuildContext context,
            AsyncSnapshot<RemoteImageData> snapshot,
          ) {
            if (snapshot.hasError) {
              return GestureDetector(
                onLongPress: () async {
                  String? choose =
                      await chooseListDialog(context, tr('app.please_choose'), [tr('components.image_reader.reload_image')]);
                      if (choose == null) {
                        return;
                      }
                      if (choose == tr('components.image_reader.reload_image')) {
                        setState(() {
                          _future = _load();
                        });
                      }
                },
                child: buildError(widget.size.width, widget.size.height),
              );
            }
            if (snapshot.connectionState != ConnectionState.done) {
              return buildLoading(widget.size.width, widget.size.height);
            }
            var data = snapshot.data!;
            return buildFile(
              data.finalPath,
              widget.size.width,
              widget.size.height,
              context: context,
            );
          },
        );
      },
    );
  }
}

///////////////////////////////////////////////////////////////////////////////

class _WebToonZoomReaderState extends _ImageReaderContentState {
  var _controllerTime = DateTime.now().millisecondsSinceEpoch + 400;
  late final List<Size?> _trueSizes = [];
  late final zoomable.ItemScrollController _itemScrollController;
  late final zoomable.ScrollOffsetController _scrollOffsetController;
  late final zoomable.ItemPositionsListener _itemPositionsListener;
  late final zoomable.ScrollOffsetListener _scrollOffsetListener;
  StreamSubscription<double>? _scrollOffsetSubscription;

  @override
  void initState() {
    for (var e in widget.struct.images) {
      if (e.pkzFile != null &&
          e.width != null &&
          e.height != null &&
          e.width! > 0 &&
          e.height! > 0) {
        _trueSizes.add(Size(e.width!.toDouble(), e.height!.toDouble()));
      } else if (e.downloadLocalPath != null) {
        _trueSizes.add(Size(e.width!.toDouble(), e.height!.toDouble()));
      } else {
        _trueSizes.add(null);
      }
    }
    _itemScrollController = zoomable.ItemScrollController();
    _scrollOffsetController = zoomable.ScrollOffsetController();
    _itemPositionsListener = zoomable.ItemPositionsListener.create();
    _itemPositionsListener.itemPositions.addListener(_onListCurrentChange);
    _scrollOffsetListener = zoomable.ScrollOffsetListener.create();
    _scrollOffsetSubscription = _scrollOffsetListener.changes.listen(_onScroll);
    super.initState();
  }

  void _onScroll(double delta) {
    if (currentAutoFullScreenOnForward() && !widget.struct.fullScreen) {
      if (delta > 0) {
        widget.struct.onFullScreenChange(true);
      }
    }
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_onListCurrentChange);
    _scrollOffsetSubscription?.cancel();
    super.dispose();
  }

  void _onListCurrentChange() {
    var positions = _itemPositionsListener.itemPositions.value;
    if (positions.isNotEmpty) {
      super._onPositionsChange(positions
          .map((e) => ImageReaderItemPosition(
              e.index, e.itemLeadingEdge, e.itemTrailingEdge))
          .toList());
    }
  }

  @override
  void _needJumpTo(int index, bool animation) {
    if (noAnimation() || animation == false) {
      _itemScrollController.jumpTo(
        index: index,
      );
    } else {
      if (DateTime.now().millisecondsSinceEpoch < _controllerTime) {
        return;
      }
      _controllerTime = DateTime.now().millisecondsSinceEpoch + 400;
      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 400),
      );
    }
  }

  @override
  void _needScrollForward() {
    _commonWebToonScrollForward(
      (offset) {
        _scrollOffsetController.animateScroll(
          offset: offset,
          duration: noAnimation()
              ? Duration.zero
              : const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      },
      (index) {
        _needJumpTo(index, true);
      },
    );
  }

  @override
  void _needScrollBackward() {
    _commonWebToonScrollBackward(
      (offset) {
        _scrollOffsetController.animateScroll(
          offset: offset,
          duration: noAnimation()
              ? Duration.zero
              : const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      },
      (index) {
        _needJumpTo(index, true);
      },
    );
  }

  @override
  double? get _remainingScrollHeight {
    try {
      return _scrollOffsetController.maxScrollExtent -
          _scrollOffsetController.offset;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget _buildViewer() {
    return Container(
      decoration: BoxDecoration(
        color: readerBackgroundColorObj,
      ),
      child: _buildList(),
    );
  }

  Widget _buildList() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        List<Widget> _images = [];
        for (var index = 0; index < widget.struct.images.length; index++) {
          late Size renderSize;
          if (_trueSizes[index] != null) {
            if (widget.pagerDirection == ReaderDirection.TOP_TO_BOTTOM) {
              renderSize = Size(
                constraints.maxWidth,
                constraints.maxWidth *
                    _trueSizes[index]!.height /
                    _trueSizes[index]!.width,
              );
            } else {
              var maxHeight = constraints.maxHeight -
                  super._topBarHeight() -
                  super._bottomBarHeight() -
                  MediaQuery.of(context).padding.bottom;
              renderSize = Size(
                maxHeight *
                    _trueSizes[index]!.width /
                    _trueSizes[index]!.height,
                maxHeight,
              );
            }
          } else {
            if (widget.pagerDirection == ReaderDirection.TOP_TO_BOTTOM) {
              renderSize = Size(constraints.maxWidth, constraints.maxWidth / 2);
            } else {
              renderSize =
                  Size(constraints.maxWidth / 2, constraints.maxHeight);
            }
          }
          var currentIndex = index;
          onTrueSize(Size size) {
            setState(() {
              _trueSizes[currentIndex] = size;
            });
          }

          var e = widget.struct.images[index];
          if (e.pkzFile != null) {
            _images.add(_WebToonPkzImage(
              width: e.width!,
              height: e.height!,
              format: e.format!,
              size: renderSize,
              onTrueSize: onTrueSize,
              pkzFile: e.pkzFile!,
            ));
          } else if (e.downloadLocalPath != null) {
            _images.add(_WebToonDownloadImage(
              fileServer: e.fileServer,
              path: e.path,
              localPath: e.downloadLocalPath!,
              fileSize: e.fileSize!,
              width: e.width!,
              height: e.height!,
              format: e.format!,
              size: renderSize,
              onTrueSize: onTrueSize,
            ));
          } else {
            _images.add(_WebToonRemoteImage(
              e.fileServer,
              e.path,
              renderSize,
              onTrueSize,
            ));
          }
        }
        return zoomable.ZoomablePositionedList.builder(
          gestureSpeed: currentGestureSpeed(),
          dragRegionLock: dragRegionLock(),
          scrollOffsetListener: _scrollOffsetListener,
          minScale: readerZoomMinScale,
          maxScale: readerZoomMaxScale,
          doubleTapScale: readerZoomDoubleTapScale,
          doubleTapAnimationDuration: noAnimation()
              ? Duration.zero
              : const Duration(milliseconds: 200),
          enableDoubleTapZoom: widget.fullScreenAction !=
                  FullScreenAction.TOUCH_DOUBLE &&
              widget.fullScreenAction != FullScreenAction.TOUCH_DOUBLE_ONCE_NEXT,
          initialScrollIndex: super._startIndex,
          scrollDirection:
              widget.pagerDirection == ReaderDirection.TOP_TO_BOTTOM
                  ? Axis.vertical
                  : Axis.horizontal,
          reverse: widget.pagerDirection == ReaderDirection.RIGHT_TO_LEFT,
          padding: EdgeInsets.only(
            top: super._topBarHeight(),
            bottom: widget.pagerDirection == ReaderDirection.TOP_TO_BOTTOM
                ? 130
                : (super._bottomBarHeight() +
                    MediaQuery.of(context).padding.bottom),
          ),
          itemScrollController: _itemScrollController,
          scrollOffsetController: _scrollOffsetController,
          itemPositionsListener: _itemPositionsListener,
          itemCount: widget.struct.images.length + 1,
          itemBuilder: (BuildContext context, int index) {
            if (index >= widget.struct.images.length) {
              return _buildNextEp();
            }
            return _images[index];
          },
        );
      },
    );
  }

  Widget _buildNextEp() {
    if (super._fullscreenController()) {
      return Container();
    }
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.all(20),
      child: MaterialButton(
        onPressed: () {
          if (super._hasNextEp()) {
            super._onNextAction();
          } else {
            Navigator.of(context).pop();
          }
        },
        textColor: invertColor(readerBackgroundColorObj),
        child: Container(
          padding: const EdgeInsets.only(top: 40, bottom: 40),
          child: Text(super._hasNextEp()
              ? tr('components.image_reader.next_chapter')
              : tr('components.image_reader.end_reading')),
        ),
      ),
    );
  }
}

///////////////////////////////////////////////////////////////////////////////

class _ListViewReaderState extends _ImageReaderContentState
    with SingleTickerProviderStateMixin {
  final List<Size?> _trueSizes = [];
  final _transformationController = TransformationController();
  late TapDownDetails _doubleTapDetails;
  late final _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );
  late final _scrollController = ScrollController();
  double _lastScrollOffset = 0;

  @override
  void initState() {
    _scrollController.addListener(_onScroll);
    for (var e in widget.struct.images) {
      if (e.pkzFile != null &&
          e.width != null &&
          e.height != null &&
          e.width! > 0 &&
          e.height! > 0) {
        _trueSizes.add(Size(e.width!.toDouble(), e.height!.toDouble()));
      } else if (e.downloadLocalPath != null) {
        _trueSizes.add(Size(e.width!.toDouble(), e.height!.toDouble()));
      } else {
        _trueSizes.add(null);
      }
    }
    super.initState();
  }

  void _onScroll() {
    var offset = _scrollController.offset;
    if (currentAutoFullScreenOnForward() && !widget.struct.fullScreen) {
      if (offset > _lastScrollOffset) {
        widget.struct.onFullScreenChange(true);
      }
    }
    _lastScrollOffset = offset;
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void _needJumpTo(int index, bool animation) {}

  int _controllerTime = 0;

  @override
  void _needScrollForward() {
    var first = _scrollController.offset;

    double s;
    if (gReaderDirection == ReaderDirection.TOP_TO_BOTTOM) {
      s = MediaQuery.of(context).size.height;
    } else {
      s = MediaQuery.of(context).size.width;
    }
    var scrollSize = s * readerScrollByScreenPercentage;
    var pos = first + scrollSize;
    if (pos > _scrollController.position.maxScrollExtent) {
      pos = _scrollController.position.maxScrollExtent;
    }

    if (noAnimation()) {
      _scrollController.jumpTo(pos);
    } else {
      if (DateTime.now().millisecondsSinceEpoch < _controllerTime) {
        return;
      }
      _controllerTime = DateTime.now().millisecondsSinceEpoch + 400;
      _scrollController.animateTo(
        pos,
        duration: const Duration(milliseconds: 400),
        curve: Curves.ease,
      );
    }
  }

  @override
  void _needScrollBackward() {}

  @override
  double? get _remainingScrollHeight {
    if (_scrollController.hasClients) {
      return _scrollController.position.maxScrollExtent -
          _scrollController.offset;
    }
    return null;
  }

  @override
  Widget _buildViewer() {
    return Container(
      decoration: BoxDecoration(
        color: readerBackgroundColorObj,
      ),
      child: _buildList(),
    );
  }

  Widget _buildList() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // reload _images size
        List<Widget> _images = [];
        for (var index = 0; index < widget.struct.images.length; index++) {
          late Size renderSize;
          if (_trueSizes[index] != null) {
            if (widget.pagerDirection == ReaderDirection.TOP_TO_BOTTOM) {
              renderSize = Size(
                constraints.maxWidth,
                constraints.maxWidth *
                    _trueSizes[index]!.height /
                    _trueSizes[index]!.width,
              );
            } else {
              var maxHeight = constraints.maxHeight -
                  super._topBarHeight() -
                  super._bottomBarHeight() -
                  MediaQuery.of(context).padding.bottom;
              renderSize = Size(
                maxHeight *
                    _trueSizes[index]!.width /
                    _trueSizes[index]!.height,
                maxHeight,
              );
            }
          } else {
            if (widget.pagerDirection == ReaderDirection.TOP_TO_BOTTOM) {
              renderSize = Size(constraints.maxWidth, constraints.maxWidth / 2);
            } else {
              // ReaderDirection.LEFT_TO_RIGHT
              // ReaderDirection.RIGHT_TO_LEFT
              renderSize =
                  Size(constraints.maxWidth / 2, constraints.maxHeight);
            }
          }
          var currentIndex = index;
          onTrueSize(Size size) {
            setState(() {
              _trueSizes[currentIndex] = size;
            });
          }

          var e = widget.struct.images[index];
          if (e.pkzFile != null) {
            _images.add(_WebToonPkzImage(
              width: e.width!,
              height: e.height!,
              format: e.format!,
              size: renderSize,
              onTrueSize: onTrueSize,
              pkzFile: e.pkzFile!,
            ));
          } else if (e.downloadLocalPath != null) {
            _images.add(_WebToonDownloadImage(
              fileServer: e.fileServer,
              path: e.path,
              localPath: e.downloadLocalPath!,
              fileSize: e.fileSize!,
              width: e.width!,
              height: e.height!,
              format: e.format!,
              size: renderSize,
              onTrueSize: onTrueSize,
            ));
          } else {
            _images.add(_WebToonRemoteImage(
              e.fileServer,
              e.path,
              renderSize,
              onTrueSize,
            ));
          }
        }
        var list = ListView.builder(
          controller: _scrollController,
          scrollDirection:
              widget.pagerDirection == ReaderDirection.TOP_TO_BOTTOM
                  ? Axis.vertical
                  : Axis.horizontal,
          reverse: widget.pagerDirection == ReaderDirection.RIGHT_TO_LEFT,
          padding: EdgeInsets.only(
            // 不管全屏与否, 滚动方向如何, 顶部永远保持间距
            top: super._topBarHeight(),
            bottom: widget.pagerDirection == ReaderDirection.TOP_TO_BOTTOM
                ? 130 // 纵向滚动 底部永远都是130的空白
                : (super._bottomBarHeight() +
                    MediaQuery.of(context).padding.bottom)
            // 非全屏时, 顶部去掉顶部BAR的高度, 底部去掉底部BAR的高度, 形成看似填充的效果
            ,
          ),
          itemCount: widget.struct.images.length + 1,
          itemBuilder: (BuildContext context, int index) {
            if (widget.struct.images.length == index) {
              return _buildNextEp();
            }
            return _images[index];
          },
        );
        var viewer = InteractiveViewer(
          transformationController: _transformationController,
          minScale: readerZoomMinScale,
          maxScale: readerZoomMaxScale,
          child: list,
        );
        if (FullScreenAction.TOUCH_DOUBLE == currentFullScreenAction() ||
            FullScreenAction.TOUCH_DOUBLE_ONCE_NEXT ==
                currentFullScreenAction()) {
          return viewer;
        }
        return GestureDetector(
          onDoubleTap: _handleDoubleTap,
          onDoubleTapDown: _handleDoubleTapDown,
          child: viewer,
        );
      },
    );
  }

  Widget _buildNextEp() {
    if (super._fullscreenController()) {
      return Container();
    }
    return Container(
      padding: const EdgeInsets.all(20),
      child: MaterialButton(
        onPressed: () {
          if (super._hasNextEp()) {
            super._onNextAction();
          } else {
            Navigator.of(context).pop();
          }
        },
        textColor: invertColor(readerBackgroundColorObj),
        child: Container(
          padding: const EdgeInsets.only(top: 40, bottom: 40),
          child: Text(super._hasNextEp() ? tr('components.image_reader.next_chapter') : tr('components.image_reader.end_reading')),
        ),
      ),
    );
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (_animationController.isAnimating) {
      return;
    }
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      var position = _doubleTapDetails.localPosition;
      final targetScale = readerZoomDoubleTapScale.clamp(1.0, readerZoomMaxScale);
      var animation = Tween(begin: 0.0, end: 1.0).animate(_animationController);
      animation.addListener(() {
        final scale = 1.0 + (targetScale - 1.0) * animation.value;
        _transformationController.value = Matrix4.identity()
          ..translate(
              -position.dx * (scale - 1.0), -position.dy * (scale - 1.0))
          ..scale(scale);
      });
      _animationController.forward(from: 0);
    }
  }
}

///////////////////////////////////////////////////////////////////////////////

class _GalleryReaderState extends _ImageReaderContentState {
  late PageController _pageController;
  List<ImageProvider> ips = [];
  List<PhotoViewGalleryPageOptions> options = [];
  late Widget gallery;

  @override
  void initState() {
    super.initState();
    // 需要先初始化 super._startIndex 才能使用, 所以在上面
    _pageController = PageController(initialPage: super._startIndex);
    for (var index = 0; index < widget.struct.images.length; index++) {
      var item = widget.struct.images[index];
      late ImageProvider ip;
      if (item.pkzFile != null) {
        ip = PkzImageProvider(item.pkzFile!.pkzPath, item.pkzFile!.path);
      } else if (item.downloadLocalPath != null) {
        ip = ResourceDownloadFileImageProvider(item.downloadLocalPath!);
      } else {
        ip = ResourceRemoteImageProvider(item.fileServer, item.path);
      }
      ips.add(ip);
    }
    for (var ip in ips) {
      options.add(PhotoViewGalleryPageOptions(
        disableGestures:
            FullScreenAction.TOUCH_DOUBLE == currentFullScreenAction() ||
                FullScreenAction.TOUCH_DOUBLE_ONCE_NEXT ==
                    currentFullScreenAction(),
        imageProvider: ip,
        initialScale: PhotoViewComputedScale.contained,
        minScale: PhotoViewComputedScale.contained * readerZoomMinScale,
        maxScale: PhotoViewComputedScale.contained * readerZoomMaxScale,
        tightMode: dragRegionLock(),
        errorBuilder: (b, e, s) {
          print("$e,$s");
          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return buildError(constraints.maxWidth, constraints.maxHeight);
            },
          );
        },
        filterQuality: FilterQuality.high,
      ));
    }
    _preloadJump(super._startIndex, init: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void _needJumpTo(int index, bool animation) {
    if (noAnimation() || animation == false) {
      _pageController.jumpToPage(
        index,
      );
    } else {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.ease,
      );
    }
    _preloadJump(index);
  }

  @override
  void _needScrollForward() {}

  @override
  void _needScrollBackward() {}

  _preloadJump(int index, {bool init = false}) {
    fn() {
      for (var i = index - 1; i < index + 3; i++) {
        if (i < 0 || i >= ips.length) continue;
        final ip = ips[i];
        precacheImage(ip, context);
      }
    }

    if (init) {
      WidgetsBinding.instance?.addPostFrameCallback((_) => fn());
    } else {
      fn();
    }
  }

  Future _onLongPress() async {
    if (_current >= 0 && _current < widget.struct.images.length) {
      var item = widget.struct.images[_current];
      if (item.pkzFile != null) {
        return;
      }
      Future<String> load() async {
        var item = widget.struct.images[_current];
        if (item.downloadLocalPath != null) {
          return method.downloadImagePath(item.downloadLocalPath!);
        }
        var data = await method.remoteImageData(item.fileServer, item.path);
        return data.finalPath;
      }

      String? choose = await chooseListDialog(context, tr('app.please_choose'), [tr('app.preview_image'), tr('app.save_image')]);
      if (choose == null) {
        return;
      }

      if (choose == tr('app.preview_image')) {
        try {
          var file = await load();
          Navigator.of(context).push(mixRoute(
            builder: (context) => FilePhotoViewScreen(file),
          ));
        } catch (e) {
          defaultToast(context, tr('components.image_reader.image_load_failed'));
        }
      } else if (choose == tr('app.save_image')) {
        try {
          var file = await load();
          saveImage(file, context);
        } catch (e) {
          defaultToast(context, tr('components.image_reader.image_load_failed'));
        }
      }
    }
  }

  void _onGalleryPageChange(int to) {
    if (to > super._current &&
        currentAutoFullScreenOnForward() &&
        !widget.struct.fullScreen) {
      widget.struct.onFullScreenChange(true);
    }
    for (var i = to; i < to + 3 && i < ips.length; i++) {
      final ip = ips[i];
      precacheImage(ip, context);
    }
    // 包含一个下一章, 假设5张图片 0,1,2,3,4 length=5, 下一章=5
    if (to >= 0 && to < widget.struct.images.length) {
      super._onCurrentChange(to);
    }
  }

  @override
  Widget _buildViewer() {
    gallery = PhotoViewGallery.builder(
      scrollDirection: widget.pagerDirection == ReaderDirection.TOP_TO_BOTTOM
          ? Axis.vertical
          : Axis.horizontal,
      reverse: widget.pagerDirection == ReaderDirection.RIGHT_TO_LEFT,
      backgroundDecoration: BoxDecoration(color: readerBackgroundColorObj),
      loadingBuilder: (context, event) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return buildLoading(constraints.maxWidth, constraints.maxHeight);
        },
      ),
      pageController: _pageController,
      onPageChanged: _onGalleryPageChange,
      itemCount: widget.struct.images.length,
      builder: (BuildContext context, int index) {
        return options[index];
      },
      allowImplicitScrolling: true,
    );
    gallery = GestureDetector(
      child: gallery,
      onLongPress: _onLongPress,
    );
    gallery = Container(
      padding: EdgeInsets.only(
        top: widget.struct.fullScreen ? 0 : super._topBarHeight(),
        bottom: widget.struct.fullScreen ? 0 : super._bottomBarHeight(),
      ),
      child: gallery,
    );
    gallery = Stack(
      children: [
        gallery,
        _buildNextEpController(),
      ],
    );
    return gallery;
  }

  Widget _buildNextEpController() {
    if (super._fullscreenController() ||
        _current < widget.struct.images.length - 1) return Container();
    return Align(
      alignment: Alignment.bottomRight,
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding:
                const EdgeInsets.only(left: 10, right: 10, top: 4, bottom: 4),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
              color: Color(0x88000000),
            ),
            child: GestureDetector(
              onTap: () {
                if (_hasNextEp()) {
                  _onNextAction();
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: Text(
                _hasNextEp() ? tr('components.image_reader.next_chapter') : tr('components.image_reader.end_reading'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

///////////////////////////////////////////////////////////////////////////////

class _TwoPageGalleryReaderState extends _ImageReaderContentState {
  late PageController _pageController;
  var _controllerTime = DateTime.now().millisecondsSinceEpoch + 400;
  late final List<Size?> _trueSizes = [];
  List<ImageProvider> ips = [];
  List<PhotoViewGalleryPageOptions> options = [];
  late PhotoViewGallery _view;

  @override
  void initState() {
    // 需要先初始化 super._startIndex 才能使用, 所以在上面
    for (var e in widget.struct.images) {
      if (e.pkzFile != null &&
          e.width != null &&
          e.height != null &&
          e.width! > 0 &&
          e.height! > 0) {
        _trueSizes.add(Size(e.width!.toDouble(), e.height!.toDouble()));
      } else if (e.downloadLocalPath != null) {
        _trueSizes.add(Size(e.width!.toDouble(), e.height!.toDouble()));
      } else {
        _trueSizes.add(null);
      }
    }
    super.initState();
    _pageController = PageController(initialPage: super._startIndex ~/ 2);
    for (var index = 0; index < widget.struct.images.length; index++) {
      var item = widget.struct.images[index];
      late ImageProvider ip;
      if (item.pkzFile != null) {
        ip = PkzImageProvider(item.pkzFile!.pkzPath, item.pkzFile!.path);
      } else if (item.downloadLocalPath != null) {
        ip = ResourceDownloadFileImageProvider(item.downloadLocalPath!);
      } else {
        ip = ResourceRemoteImageProvider(item.fileServer, item.path);
      }
      ips.add(ip);
    }
    for (var index = 0; index < ips.length; index += 2) {
      // 两页
      late ImageProvider leftIp = ips[index];
      late ImageProvider rightIp = ips[index + 1];
      if (index + 1 < ips.length) {
        leftIp = ips[index];
        rightIp = ips[index + 1];
      } else {
        leftIp = ips[index];
        // ImageProvider by color black
        rightIp = const AssetImage('lib/assets/0.png');
      }
      if (twoPageDirection == TwoPageDirection.RIGHT_TO_LEFT) {
        final temp = leftIp;
        leftIp = rightIp;
        rightIp = temp;
      }
      late Alignment leftAlignment, rightAlignment;
      switch (gReaderTwoPageDirection) {
        case ReaderTwoPageDirection.CLOSE_TO:
          leftAlignment = Alignment.centerRight;
          rightAlignment = Alignment.centerLeft;
          break;
        case ReaderTwoPageDirection.PULL_AWAY:
          leftAlignment = Alignment.centerLeft;
          rightAlignment = Alignment.centerRight;
          break;
        case ReaderTwoPageDirection.EACH_CENTERED:
          leftAlignment = Alignment.center;
          rightAlignment = Alignment.center;
          break;
      }

      options.add(
        PhotoViewGalleryPageOptions.customChild(
          disableGestures:
              FullScreenAction.TOUCH_DOUBLE == currentFullScreenAction() ||
                  FullScreenAction.TOUCH_DOUBLE_ONCE_NEXT ==
                      currentFullScreenAction(),
          initialScale: PhotoViewComputedScale.contained,
          minScale: PhotoViewComputedScale.contained * readerZoomMinScale,
          maxScale: PhotoViewComputedScale.contained * readerZoomMaxScale,
          tightMode: dragRegionLock(),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: leftAlignment,
                      child: Image(
                        image: leftIp,
                        fit: BoxFit.contain,
                        // loadingBuilder: (context, child, event) => buildLoading(constraints.maxWidth, constraints.maxHeight),
                        errorBuilder: (b, e, s) {
                          print("$e,$s");
                          return buildError(
                            constraints.maxWidth / 2,
                            constraints.maxHeight / 2,
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: rightAlignment,
                      child: Image(
                        image: rightIp,
                        fit: BoxFit.contain,
                        // loadingBuilder: (context, child, event) => buildLoading(constraints.maxWidth, constraints.maxHeight),
                        errorBuilder: (b, e, s) {
                          print("$e,$s");
                          return buildError(
                            constraints.maxWidth / 2,
                            constraints.maxHeight / 2,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }
    _view = PhotoViewGallery(
      pageController: _pageController,
      pageOptions: options,
      scrollDirection: widget.pagerDirection == ReaderDirection.TOP_TO_BOTTOM
          ? Axis.vertical
          : Axis.horizontal,
      reverse: widget.pagerDirection == ReaderDirection.RIGHT_TO_LEFT,
      onPageChanged: _onGalleryPageChange,
      backgroundDecoration: BoxDecoration(color: readerBackgroundColorObj),
    );
    _preloadJump(super._startIndex, init: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void _needJumpTo(int index, bool animation) {
    if (noAnimation() || animation == false) {
      _pageController.jumpToPage(
        index ~/ 2,
      );
    } else {
      _pageController.animateToPage(
        index ~/ 2,
        duration: const Duration(milliseconds: 400),
        curve: Curves.ease,
      );
    }
    _preloadJump(index);
  }

  @override
  void _needScrollBackward() {
    // TODO: implement _needScrollBackward
  }

  @override
  void _needScrollForward() {
    // TODO: implement _needScrollForward
  }

  _preloadJump(int index, {bool init = false}) {
    fn() {
      for (var i = index - 2; i < index + 5; i++) {
        if (i < 0 || i >= ips.length) continue;
        final ip = ips[i];
        precacheImage(ip, context);
      }
    }

    if (init) {
      WidgetsBinding.instance?.addPostFrameCallback((_) => fn());
    } else {
      fn();
    }
  }

  @override
  Widget _buildViewer() {
    return Stack(
      children: [
        GestureDetector(
          onLongPress: _onLongPress,
          child: _view,
        ),
        _buildNextEpController(),
      ],
    );
  }

  void _onGalleryPageChange(int to) {
    var toIndex = to * 2;
    if (toIndex > super._current &&
        currentAutoFullScreenOnForward() &&
        !widget.struct.fullScreen) {
      widget.struct.onFullScreenChange(true);
    }
    // 提前加载
    for (var i = toIndex + 2; i < toIndex + 5 && i < ips.length; i++) {
      final ip = ips[i];
      precacheImage(ip, context);
    }
    // 包含一个下一章, 假设5张图片 0,1,2,3,4 length=5, 下一章=5
    if (to >= 0 && to < widget.struct.images.length) {
      super._onCurrentChange(toIndex);
    }
  }

  Widget _buildNextEpController() {
    if (super._fullscreenController() ||
        _current < widget.struct.images.length - 2) return Container();
    return Align(
      alignment: Alignment.bottomRight,
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding:
            const EdgeInsets.only(left: 10, right: 10, top: 4, bottom: 4),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
              color: Color(0x88000000),
            ),
            child: GestureDetector(
              onTap: () {
                if (_hasNextEp()) {
                  _onNextAction();
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: Text(
                _hasNextEp() ? tr('components.image_reader.next_chapter') : tr('components.image_reader.end_reading'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future _onLongPress() async {
    List<ReaderImageInfo> matchImages = [];
    if (_current >= 0 && _current < widget.struct.images.length) {
      var item = widget.struct.images[_current];
      if (item.pkzFile != null) {
        return;
      }
      matchImages.add(item);
    }
    if (_current + 1 >= 0 && _current + 1 < widget.struct.images.length) {
      var item = widget.struct.images[_current + 1];
      if (item.pkzFile != null) {
        return;
      }
      matchImages.add(item);
    }
    if (matchImages.isEmpty) {
      return;
    }
    String? choose = await chooseListDialog(context, tr('app.please_choose'), [tr('components.image_reader.save_image_in_this_page')]);
    if (choose == null) {
      return;
    }
    if (choose == tr('components.image_reader.save_image_in_this_page')) {
        for (var item in matchImages) {
          if (item.downloadLocalPath != null) {
            var file = await method.downloadImagePath(item.downloadLocalPath!);
            saveImage(file, context);
          } else {
            var data = await method.remoteImageData(item.fileServer, item.path);
            saveImage(data.finalPath, context);
          }
        }
    }
  }
}

///////////////////////////////////////////////////////////////////////////////

Color invertColor(Color color) {
  return Color.fromRGBO(
    255 - color.red,
    255 - color.green,
    255 - color.blue,
    1.0,
  );
}

///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
