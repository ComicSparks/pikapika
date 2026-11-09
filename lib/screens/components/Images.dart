import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pikapika/basic/Common.dart';
import 'package:pikapika/basic/Cross.dart';
import 'package:pikapika/basic/Method.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pikapika/basic/config/ImageAddress.dart';
import 'dart:io';
import 'dart:ui' as ui;

import '../../basic/config/IconLoading.dart';
import '../FilePhotoViewScreen.dart';

// 从本地加载图片
class ResourceFileImageProvider
    extends ImageProvider<ResourceFileImageProvider> {
  final String path;
  final double scale;

  ResourceFileImageProvider(this.path, {this.scale = 1.0});

  @override
  ImageStreamCompleter loadImage(
    ResourceFileImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key),
      scale: key.scale,
    );
  }

  @override
  Future<ResourceFileImageProvider> obtainKey(
      ImageConfiguration configuration) {
    return SynchronousFuture<ResourceFileImageProvider>(this);
  }

  Future<ui.Codec> _loadAsync(ResourceFileImageProvider key) async {
    assert(key == this);
    return ui.instantiateImageCodec(await File(path).readAsBytes());
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final ResourceFileImageProvider typedOther = other;
    return path == typedOther.path && scale == typedOther.scale;
  }

  @override
  int get hashCode => Object.hash(path, scale);

  @override
  String toString() => '$runtimeType('
      'path: ${describeIdentity(path)},'
      ' scale: $scale'
      ')';
}

// 从本地加载图片
class ResourceDownloadFileImageProvider
    extends ImageProvider<ResourceDownloadFileImageProvider> {
  final String path;
  final double scale;

  ResourceDownloadFileImageProvider(this.path, {this.scale = 1.0});

  @override
  ImageStreamCompleter loadImage(
    ResourceDownloadFileImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key),
      scale: key.scale,
    );
  }

  @override
  Future<ResourceDownloadFileImageProvider> obtainKey(
      ImageConfiguration configuration) {
    return SynchronousFuture<ResourceDownloadFileImageProvider>(this);
  }

  Future<ui.Codec> _loadAsync(ResourceDownloadFileImageProvider key) async {
    assert(key == this);
    return ui.instantiateImageCodec(
        await File(await method.downloadImagePath(path)).readAsBytes());
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final ResourceDownloadFileImageProvider typedOther = other;
    return path == typedOther.path && scale == typedOther.scale;
  }

  @override
  int get hashCode => Object.hash(path, scale);

  @override
  String toString() => '$runtimeType('
      'path: ${describeIdentity(path)},'
      ' scale: $scale'
      ')';
}

// 从远端加载图片
class ResourceRemoteImageProvider
    extends ImageProvider<ResourceRemoteImageProvider> {
  final String fileServer;
  final String path;
  final double scale;

  ResourceRemoteImageProvider(this.fileServer, this.path, {this.scale = 1.0});

  @override
  ImageStreamCompleter loadImage(
    ResourceRemoteImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key),
      scale: key.scale,
    );
  }

  @override
  Future<ResourceRemoteImageProvider> obtainKey(
      ImageConfiguration configuration) {
    return SynchronousFuture<ResourceRemoteImageProvider>(this);
  }

  Future<ui.Codec> _loadAsync(ResourceRemoteImageProvider key) async {
    assert(key == this);
    var downloadTo = await method.remoteImageData(fileServer, path);
    return ui.instantiateImageCodec(await File(downloadTo.finalPath).readAsBytes());
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final ResourceRemoteImageProvider typedOther = other;
    return fileServer == typedOther.fileServer &&
        path == typedOther.path &&
        scale == typedOther.scale;
  }

  @override
  int get hashCode => Object.hash(fileServer, path, scale);

  @override
  String toString() => '$runtimeType('
      'fileServer: ${describeIdentity(fileServer)},'
      ' path: ${describeIdentity(path)},'
      ' scale: $scale'
      ')';
}

// 下载的图片
class DownloadImage extends StatefulWidget {
  final String path;
  final double? width;
  final double? height;

  const DownloadImage({
    Key? key,
    required this.path,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DownloadImageState();
}

class _DownloadImageState extends State<DownloadImage> {
  late final Future<String> _future = method.downloadImagePath(widget.path);

  @override
  Widget build(BuildContext context) {
    return pathFutureImage(
      _future,
      widget.width,
      widget.height,
      context: context,
    );
  }
}

// 远端图片
class RemoteImage extends StatefulWidget {
  final String fileServer;
  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;

  const RemoteImage({
    Key? key,
    required this.fileServer,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RemoteImageState();
}

class _RemoteImageState extends State<RemoteImage> {
  late bool _mock;
  late Future<String> _future;

  @override
  void initState() {
    _mock = widget.fileServer == "" ||
        (widget.fileServer.contains(".xyz/") && currentImageAddress() < 0);
    if (!_mock) {
      _future = method
          .remoteImageData(widget.fileServer, widget.path)
          .then((value) => value.finalPath);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_mock) {
      return buildMock(widget.width, widget.height);
    }
    return pathFutureImage(
      _future,
      widget.width,
      widget.height,
      fit: widget.fit,
      context: context,
    );
  }
}

Widget pathFutureImage(Future<String> future, double? width, double? height,
    {BoxFit fit = BoxFit.cover, BuildContext? context}) {
  return FutureBuilder(
      future: future,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.hasError) {
          print("${snapshot.error}");
          print("${snapshot.stackTrace}");
          return buildError(width, height);
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return buildLoading(width, height);
        }
        return buildFile(
          snapshot.data!,
          width,
          height,
          fit: fit,
          context: context,
        );
      });
}

// 通用方法

Widget buildSvg(String source, double? width, double? height,
    {Color? color, double? margin}) {
  var widget = Container(
    width: width,
    height: height,
    padding: margin != null ? const EdgeInsets.all(10) : null,
    child: Center(
      child: SvgPicture.asset(
        source,
        width: width,
        height: height,
        color: color,
      ),
    ),
  );
  return GestureDetector(onLongPress: () {}, child: widget);
}

Widget buildMock(double? width, double? height) {
  var widget = Container(
    width: width,
    height: height,
    padding: const EdgeInsets.all(10),
    child: Center(
      child: SvgPicture.asset(
        'lib/assets/unknown.svg',
        width: width,
        height: height,
        color: Colors.grey.shade600,
      ),
    ),
  );
  return GestureDetector(onLongPress: () {}, child: widget);
}

Widget buildError(double? width, double? height) {
  double? size;
  if (width != null && height != null) {
    size = width < height ? width : height;
  }
  return SizedBox(
    width: width,
    height: height,
    child: Center(
      child: Icon(
        Icons.error_outline,
        size: size,
        color: Colors.grey,
      ),
    ),
  );
}

Widget buildLoading(double? width, double? height) {
  double? size;
  if (width != null && height != null) {
    size = width < height ? width : height;
  }
  return SizedBox(
    width: width,
    height: height,
    child: Center(
      child: Icon(
        Icons.downloading,
        size: size,
        color: Colors.grey,
      ),
    ),
  );
}

Widget buildFile(String file, double? width, double? height,
    {BoxFit fit = BoxFit.cover, BuildContext? context}) {
  var image = Image(
    image: ResourceFileImageProvider(file),
    width: width,
    height: height,
    errorBuilder: (a, b, c) {
      print("$b");
      print("$c");
      return buildError(width, height);
    },
    fit: fit,
  );
  if (context == null) return image;
  return GestureDetector(
    onLongPress: () async {
      String? choose = await chooseListDialog(context, '请选择', ['预览图片', '保存图片']);
      switch (choose) {
        case '预览图片':
          Navigator.of(context).push(mixRoute(
            builder: (context) => FilePhotoViewScreen(file),
          ));
          break;
        case '保存图片':
          saveImage(file, context);
          break;
      }
    },
    child: image,
  );
}
