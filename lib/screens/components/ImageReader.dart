import 'dart:async';
import 'dart:io';

import 'package:another_xlider/another_xlider.dart';
import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:pikapika/basic/Common.dart';
import 'package:pikapika/basic/Cross.dart';
import 'package:pikapika/basic/Entities.dart';
import 'package:pikapika/basic/Method.dart';
import 'package:pikapika/basic/config/Address.dart';
import 'package:pikapika/basic/config/FullScreenAction.dart';
import 'package:pikapika/basic/config/ImageAddress.dart';
import 'package:pikapika/basic/config/KeyboardController.dart';
import 'package:pikapika/basic/config/NoAnimation.dart';
import 'package:pikapika/basic/config/Quality.dart';
import 'package:pikapika/basic/config/ReaderDirection.dart';
import 'package:pikapika/basic/config/ReaderSliderPosition.dart';
import 'package:pikapika/basic/config/ReaderType.dart';
import 'package:pikapika/basic/config/VolumeController.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../FilePhotoViewScreen.dart';
import 'gesture_zoom_box.dart';

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
EventChannel volumeButtonChannel = EventChannel("volume_button");
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

class ReaderImageInfo {
  final String fileServer;
  final String path;
  final String? downloadLocalPath;
  final int? width;
  final int? height;
  final String? format;
  final int? fileSize;

  ReaderImageInfo(this.fileServer, this.path, this.downloadLocalPath,
      this.width, this.height, this.format, this.fileSize);
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

  const ImageReader(this.struct);

  @override
  State<StatefulWidget> createState() => _ImageReaderState();
}

class _ImageReaderState extends State<ImageReader> {
  // 记录初始方向
  final ReaderDirection _pagerDirection = gReaderDirection;

  // 记录初始阅读器类型
  final ReaderType _pagerType = currentReaderType();

  // 记录了控制器
  late FullScreenAction _fullScreenAction = currentFullScreenAction();

  late ReaderSliderPosition _readerSliderPosition =
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

  const _ImageReaderContent(
    this.struct,
    this.pagerDirection,
    this.pagerType,
    this.fullScreenAction,
    this.readerSliderPosition,
  );

  @override
  State<StatefulWidget> createState() {
    switch (pagerType) {
      case ReaderType.WEB_TOON:
        return _WebToonReaderState();
      case ReaderType.WEB_TOON_ZOOM:
        return _WebToonZoomReaderState();
      case ReaderType.GALLERY:
        return _GalleryReaderState();
      case ReaderType.WEB_TOON_FREE_ZOOM:
        return _ListViewReaderState();
      default:
        throw Exception("ERROR READER TYPE");
    }
  }
}

abstract class _ImageReaderContentState extends State<_ImageReaderContent> {
  // 阅读器
  Widget _buildViewer();

  // 键盘, 音量键 等事件
  void _needJumpTo(int index, bool animation);

  // 记录了是否切换了音量
  late bool _listVolume;

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
      switch ("$event") {
        case "UP":
          if (_current > 0) {
            _needJumpTo(_current - 1, true);
          }
          break;
        case "DOWN":
          if (_current < widget.struct.images.length - 1) {
            _needJumpTo(_current + 1, true);
          }
          break;
      }
    }
  }

  late int _startIndex;
  late int _current;
  late int _slider;

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
    return Stack(
      children: [
        _buildViewer(),
        _buildBar(),
      ],
    );
  }

  Widget _buildBar() {
    switch (widget.readerSliderPosition) {
      case ReaderSliderPosition.BOTTOM:
        return Column(
          children: [
            _buildAppBar(),
            Expanded(child: _buildController()),
            widget.struct.fullScreen
                ? Container()
                : Container(
                    height: 45,
                    color: Color(0x88000000),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(width: 15),
                        IconButton(
                          icon: Icon(Icons.fullscreen),
                          color: Colors.white,
                          onPressed: () {
                            widget.struct
                                .onFullScreenChange(!widget.struct.fullScreen);
                          },
                        ),
                        Container(width: 10),
                        Expanded(
                          child:
                              widget.pagerType != ReaderType.WEB_TOON_FREE_ZOOM
                                  ? _buildSliderBottom()
                                  : Container(),
                        ),
                        Container(width: 10),
                        IconButton(
                          icon: Icon(Icons.skip_next_outlined),
                          color: Colors.white,
                          onPressed: _onNextAction,
                        ),
                        Container(width: 15),
                      ],
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
                  _buildController(),
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
                  _buildController(),
                  _buildSliderLeft(),
                ],
              ),
            ),
          ],
        );
    }
    return Container();
  }

  Widget _buildAppBar() => widget.struct.fullScreen
      ? Container()
      : AppBar(
          title: Text(
              "${widget.struct.epNameMap[widget.struct.epOrder] ?? ""} - ${widget.struct.comicTitle}"),
          actions: [
            IconButton(
              onPressed: _onChooseEp,
              icon: Icon(Icons.menu_open),
            ),
            IconButton(
              onPressed: _onMoreSetting,
              icon: Icon(Icons.more_horiz),
            ),
          ],
        );

  Widget _buildSliderBottom() {
    return Column(
      children: [
        Expanded(child: Container()),
        Container(
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
            color: Color(0x0),
            child: Container(
              width: 35,
              height: 300,
              decoration: BoxDecoration(
                color: Color(0x66000000),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              padding: EdgeInsets.only(top: 10, bottom: 10, left: 6, right: 5),
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
            color: Color(0x0),
            child: Container(
              width: 35,
              height: 300,
              decoration: BoxDecoration(
                color: Color(0x66000000),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
              padding: EdgeInsets.only(top: 10, bottom: 10, left: 5, right: 6),
              child: Center(
                child: _buildSliderWidget(Axis.vertical),
              ),
            ),
          ),
        );

  Widget _buildSliderWidget(Axis axis) {
    return FlutterSlider(
      axis: axis,
      values: [_slider.toDouble()],
      min: 0,
      max: (widget.struct.images.length - 1).toDouble(),
      onDragging: (handlerIndex, lowerValue, upperValue) {
        _slider = (lowerValue.toInt());
      },
      onDragCompleted: (handlerIndex, lowerValue, upperValue) {
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
      step: FlutterSliderStep(
        step: 1,
        isPercentRange: false,
      ),
      tooltip: FlutterSliderTooltip(custom: (value) {
        double a = value + 1;
        return Container(
          padding: EdgeInsets.all(8),
          decoration: ShapeDecoration(
            color: Colors.black.withAlpha(0xCC),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusDirectional.circular(3)),
          ),
          child: Text(
            '${a.toInt()}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildController() {
    switch (currentFullScreenAction()) {
      case FullScreenAction.CONTROLLER:
        return _buildFullScreenController();
      case FullScreenAction.TOUCH_ONCE:
        return _buildTouchOnceController();
      case FullScreenAction.THREE_AREA:
        return _buildThreeAreaController();
      default:
        return Container();
    }
  }

  Widget _buildFullScreenController() {
    if (widget.readerSliderPosition == ReaderSliderPosition.BOTTOM &&
        !widget.struct.fullScreen) {
      return Container();
    }
    return Align(
      alignment: Alignment.bottomLeft,
      child: Material(
        color: Color(0x0),
        child: Container(
          padding: EdgeInsets.only(left: 10, right: 10, top: 4, bottom: 4),
          margin: EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
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
    );
  }

  Widget _buildTouchOnceController() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        widget.struct.onFullScreenChange(!widget.struct.fullScreen);
      },
      child: Container(),
    );
  }

  Widget _buildThreeAreaController() {
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
    showMaterialModalBottomSheet(
      context: context,
      backgroundColor: Color(0xAA000000),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height / 2,
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
    await showMaterialModalBottomSheet(
      context: context,
      backgroundColor: Color(0xAA000000),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height / 2,
          child: _SettingPanel(
            widget.struct.onReloadEp,
            widget.struct.onDownload,
          ),
        );
      },
    );
    if (widget.pagerDirection != gReaderDirection ||
        widget.pagerType != currentReaderType() ||
        currentQuality != currentQualityCode() ||
        widget.fullScreenAction != currentFullScreenAction() ||
        cReaderSliderPosition != currentReaderSliderPosition()) {
      widget.struct.onReloadEp();
    }
  }

  // 给子类调用的方法

  Future _onNextAction() async {
    if (widget.struct.epNameMap.containsKey(widget.struct.epOrder + 1)) {
      widget.struct.onChangeEp(widget.struct.epOrder + 1);
    } else {
      defaultToast(context, "已经到头了");
    }
  }

  bool _hasNextEp() =>
      widget.struct.epNameMap.containsKey(widget.struct.epOrder + 1);

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
          margin: EdgeInsets.only(left: 15, right: 15, top: 5, bottom: 5),
          decoration: BoxDecoration(
            color: widget.epOrder == e.key ? Colors.grey.withAlpha(100) : null,
            border: Border.all(
              color: Color(0xff484c60),
              style: BorderStyle.solid,
              width: .5,
            ),
          ),
          child: MaterialButton(
            onPressed: () {
              widget.onChangeEp(e.key);
            },
            textColor: Colors.white,
            child: Text('${e.value}'),
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
      children: [
        Container(
          child: Row(
            children: [
              _bottomIcon(
                icon: Icons.crop_sharp,
                title: gReaderDirectionName(),
                onPressed: () async {
                  await choosePagerDirection(context);
                  setState(() {});
                },
              ),
              _bottomIcon(
                icon: Icons.view_day_outlined,
                title: currentReaderTypeName(),
                onPressed: () async {
                  await choosePagerType(context);
                  setState(() {});
                },
              ),
              _bottomIcon(
                icon: Icons.image_aspect_ratio_outlined,
                title: currentQualityName(),
                onPressed: () async {
                  await chooseQuality(context);
                  setState(() {});
                },
              ),
              _bottomIcon(
                icon: Icons.control_camera_outlined,
                title: currentFullScreenActionName(),
                onPressed: () async {
                  await chooseFullScreenAction(context);
                  setState(() {});
                },
              ),
            ],
          ),
        ),
        Container(
          child: Row(
            children: [
              _bottomIcon(
                icon: Icons.shuffle,
                title: currentAddressName(),
                onPressed: () async {
                  await chooseAddress(context);
                  setState(() {});
                },
              ),
              _bottomIcon(
                icon: Icons.repeat_one,
                title: currentImageAddressName(),
                onPressed: () async {
                  await chooseImageAddress(context);
                  setState(() {});
                },
              ),
              _bottomIcon(
                icon: Icons.refresh,
                title: "重载页面",
                onPressed: widget.onReloadEp,
              ),
              _bottomIcon(
                icon: Icons.file_download,
                title: "下载本作",
                onPressed: widget.onDownload,
              ),
            ],
          ),
        ),
        Row(
          children: [
            _bottomIcon(
              icon: Icons.straighten_sharp,
              title: currentReaderSliderPositionName(),
              onPressed: () async {
                await chooseReaderSliderPosition(context);
              },
            ),
            Expanded(child: Container()),
            Expanded(child: Container()),
            Expanded(child: Container()),
          ],
        ),
      ],
    );
  }

  Widget _bottomIcon({
    required IconData icon,
    required String title,
    required void Function() onPressed,
  }) {
    return Expanded(
      child: Center(
        child: Column(
          children: [
            IconButton(
              iconSize: 55,
              icon: Column(
                children: [
                  Container(height: 3),
                  Icon(
                    icon,
                    size: 25,
                    color: Colors.white,
                  ),
                  Container(height: 3),
                  Text(
                    title,
                    style: TextStyle(color: Colors.white, fontSize: 10),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                  Container(height: 3),
                ],
              ),
              onPressed: onPressed,
            )
          ],
        ),
      ),
    );
  }
}

///////////////////////////////////////////////////////////////////////////////

class _WebToonReaderState extends _ImageReaderContentState {
  var _controllerTime = DateTime.now().millisecondsSinceEpoch + 400;
  late final List<Size?> _trueSizes = [];
  late final ItemScrollController _itemScrollController;
  late final ItemPositionsListener _itemPositionsListener;

  @override
  void initState() {
    widget.struct.images.forEach((e) {
      if (e.downloadLocalPath != null) {
        _trueSizes.add(Size(e.width!.toDouble(), e.height!.toDouble()));
      } else {
        _trueSizes.add(null);
      }
    });
    _itemScrollController = ItemScrollController();
    _itemPositionsListener = ItemPositionsListener.create();
    _itemPositionsListener.itemPositions.addListener(_onListCurrentChange);
    super.initState();
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_onListCurrentChange);
    super.dispose();
  }

  void _onListCurrentChange() {
    var to = _itemPositionsListener.itemPositions.value.first.index;
    // 包含一个下一章, 假设5张图片 0,1,2,3,4 length=5, 下一章=5
    if (to >= 0 && to < widget.struct.images.length) {
      super._onCurrentChange(to);
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
        index: index, // 减1 当前position 再减少1 前一个
        duration: Duration(milliseconds: 400),
      );
    }
  }

  @override
  Widget _buildViewer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
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
                  (widget.struct.fullScreen
                      ? super._topBarHeight()
                      : super._bottomBarHeight());
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
          var onTrueSize = (Size size) {
            setState(() {
              _trueSizes[currentIndex] = size;
            });
          };
          var e = widget.struct.images[index];
          if (e.downloadLocalPath != null) {
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
        return ScrollablePositionedList.builder(
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
                : ( // 横向滚动
                    widget.struct.fullScreen
                        ? super._topBarHeight() // 全屏时底部和顶部到屏幕边框距离一样保持美观
                        : super._bottomBarHeight())
            // 非全屏时, 顶部去掉顶部BAR的高度, 底部去掉底部BAR的高度, 形成看似填充的效果
            ,
          ),
          itemScrollController: _itemScrollController,
          itemPositionsListener: _itemPositionsListener,
          itemCount: widget.struct.images.length + 1,
          itemBuilder: (BuildContext context, int index) {
            if (widget.struct.images.length == index) {
              return _buildNextEp();
            }
            return _images[index];
          },
        );
      },
    );
  }

  Widget _buildNextEp() {
    return Container(
      padding: EdgeInsets.all(20),
      child: MaterialButton(
        onPressed: () {
          if (super._hasNextEp()) {
            super._onNextAction();
          } else {
            Navigator.of(context).pop();
          }
        },
        textColor: Colors.white,
        child: Container(
          padding: EdgeInsets.only(top: 40, bottom: 40),
          child: Text(super._hasNextEp() ? '下一章' : '结束阅读'),
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
    return RemoteImageData.forData(
      fileSize,
      format,
      width,
      height,
      finalPath,
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
                      await chooseListDialog(context, '请选择', ['重新加载图片']);
                  switch (choose) {
                    case '重新加载图片':
                      setState(() {
                        _future = _load();
                      });
                      break;
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

class _WebToonZoomReaderState extends _WebToonReaderState {
  @override
  Widget _buildList() {
    return GestureZoomBox(child: super._buildList());
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
    duration: Duration(milliseconds: 100),
  );

  @override
  void initState() {
    widget.struct.images.forEach((e) {
      if (e.downloadLocalPath != null) {
        _trueSizes.add(Size(e.width!.toDouble(), e.height!.toDouble()));
      } else {
        _trueSizes.add(null);
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void _needJumpTo(int index, bool animation) {}

  @override
  Widget _buildViewer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
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
                  (widget.struct.fullScreen
                      ? super._topBarHeight()
                      : super._bottomBarHeight());
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
          var onTrueSize = (Size size) {
            setState(() {
              _trueSizes[currentIndex] = size;
            });
          };
          var e = widget.struct.images[index];
          if (e.downloadLocalPath != null) {
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
                : ( // 横向滚动
                    widget.struct.fullScreen
                        ? super._topBarHeight() // 全屏时底部和顶部到屏幕边框距离一样保持美观
                        : super._bottomBarHeight())
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
          minScale: 1,
          maxScale: 2,
          child: list,
        );
        return GestureDetector(
          onDoubleTap: _handleDoubleTap,
          onDoubleTapDown: _handleDoubleTapDown,
          child: viewer,
        );
      },
    );
  }

  Widget _buildNextEp() {
    return Container(
      padding: EdgeInsets.all(20),
      child: MaterialButton(
        onPressed: () {
          if (super._hasNextEp()) {
            super._onNextAction();
          } else {
            Navigator.of(context).pop();
          }
        },
        textColor: Colors.white,
        child: Container(
          padding: EdgeInsets.only(top: 40, bottom: 40),
          child: Text(super._hasNextEp() ? '下一章' : '结束阅读'),
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
      var animation = Tween(begin: 0, end: 1.0).animate(_animationController);
      animation.addListener(() {
        _transformationController.value = Matrix4.identity()
          ..translate(
              -position.dx * animation.value, -position.dy * animation.value)
          ..scale(animation.value + 1.0);
      });
      _animationController.forward(from: 0);
    }
  }
}

///////////////////////////////////////////////////////////////////////////////

class _GalleryReaderState extends _ImageReaderContentState {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    // 需要先初始化 super._startIndex 才能使用, 所以在上面
    _pageController = PageController(initialPage: super._startIndex);
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
        duration: Duration(milliseconds: 400),
        curve: Curves.ease,
      );
    }
  }

  void _onGalleryPageChange(int to) {
    // 包含一个下一章, 假设5张图片 0,1,2,3,4 length=5, 下一章=5
    if (to >= 0 && to < widget.struct.images.length) {
      super._onCurrentChange(to);
    }
  }

  Widget _buildViewer() {
    Widget gallery = PhotoViewGallery.builder(
      scrollDirection: widget.pagerDirection == ReaderDirection.TOP_TO_BOTTOM
          ? Axis.vertical
          : Axis.horizontal,
      reverse: widget.pagerDirection == ReaderDirection.RIGHT_TO_LEFT,
      backgroundDecoration: BoxDecoration(color: Colors.black),
      loadingBuilder: (context, event) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return buildLoading(constraints.maxWidth, constraints.maxHeight);
        },
      ),
      pageController: _pageController,
      onPageChanged: _onGalleryPageChange,
      itemCount: widget.struct.images.length,
      builder: (BuildContext context, int index) {
        var item = widget.struct.images[index];
        if (item.downloadLocalPath != null) {
          return PhotoViewGalleryPageOptions(
            imageProvider:
                ResourceDownloadFileImageProvider(item.downloadLocalPath!),
            errorBuilder: (b, e, s) {
              print("$e,$s");
              return LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return buildError(
                      constraints.maxWidth, constraints.maxHeight);
                },
              );
            },
          );
        }
        return PhotoViewGalleryPageOptions(
          imageProvider:
              ResourceRemoteImageProvider(item.fileServer, item.path),
          errorBuilder: (b, e, s) {
            print("$e,$s");
            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return buildError(constraints.maxWidth, constraints.maxHeight);
              },
            );
          },
          filterQuality: FilterQuality.high,
        );
      },
      allowImplicitScrolling: true,
    );
    gallery = GestureDetector(
      child: gallery,
      onLongPress: () async {
        if (_current >= 0 && _current < widget.struct.images.length) {
          Future<String> Function() load = () async {
            var item = widget.struct.images[_current];
            if (item.downloadLocalPath != null) {
              return method.downloadImagePath(item.downloadLocalPath!);
            }
            var data = await method.remoteImageData(item.fileServer, item.path);
            return data.finalPath;
          };
          String? choose =
              await chooseListDialog(context, '请选择', ['预览图片', '保存图片']);
          switch (choose) {
            case '预览图片':
              try {
                var file = await load();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => FilePhotoViewScreen(file),
                ));
              } catch (e) {
                defaultToast(context, "图片加载失败");
              }
              break;
            case '保存图片':
              try {
                var file = await load();
                saveImage(file, context);
              } catch (e) {
                defaultToast(context, "图片加载失败");
              }
              break;
          }
        }
      },
    );
    gallery = Container(
      padding: EdgeInsets.only(
        top: widget.struct.fullScreen ? 0 : super._topBarHeight(),
        bottom: widget.struct.fullScreen ? 0 : super._bottomBarHeight(),
      ),
      child: gallery,
    );
    return Stack(
      children: [
        gallery,
        _buildNextEpController(),
      ],
    );
  }

  Widget _buildNextEpController() {
    if (_current < widget.struct.images.length - 1) return Container();
    return Align(
      alignment: Alignment.bottomRight,
      child: Material(
        color: Color(0x0),
        child: Container(
          margin: EdgeInsets.only(bottom: 10),
          padding: EdgeInsets.only(left: 10, right: 10, top: 4, bottom: 4),
          decoration: BoxDecoration(
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
            child: Text(_hasNextEp() ? '下一章' : '结束阅读',
                style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

///////////////////////////////////////////////////////////////////////////////
