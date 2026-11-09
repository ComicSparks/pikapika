import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pikapika/basic/Method.dart';
import 'dart:ui' as ui;
import 'Images.dart';
import 'dart:typed_data';

// 从本地加载图片
class PkzImageProvider extends ImageProvider<PkzImageProvider> {
  final String pkzPath;
  final String path;
  final double scale;

  PkzImageProvider(this.pkzPath, this.path, {this.scale = 1.0});

  @override
  ImageStreamCompleter loadImage(
    PkzImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key),
      scale: key.scale,
    );
  }

  @override
  Future<PkzImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<PkzImageProvider>(this);
  }

  Future<ui.Codec> _loadAsync(PkzImageProvider key) async {
    assert(key == this);
    return ui.instantiateImageCodec(await method.loadPkzFile(pkzPath, path));
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final PkzImageProvider typedOther = other;
    return pkzPath == typedOther.pkzPath &&
        path == typedOther.path &&
        scale == typedOther.scale;
  }

  @override
  int get hashCode => Object.hash(pkzPath, path, scale);

  @override
  String toString() => '$runtimeType('
      ' pkzPath: ${describeIdentity(pkzPath)},'
      ' path: ${describeIdentity(path)},'
      ' scale: $scale'
      ')';
}

// 远端图片
class PkzImage extends StatefulWidget {
  final String pkzPath;
  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;

  const PkzImage({
    Key? key,
    required this.pkzPath,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PkzImageState();
}

class _PkzImageState extends State<PkzImage> {
  late bool _mock;

  @override
  void initState() {
    _mock = widget.path == "";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_mock) {
      return buildMock(widget.width, widget.height);
    }
    return Image(
      image: PkzImageProvider(widget.pkzPath, widget.path),
      width: widget.width,
      height: widget.height,
      errorBuilder: (a, b, c) {
        print("$b");
        print("$c");
        return buildError(widget.width, widget.height);
      },
      fit: widget.fit,
    );
  }
}

// 远端图片
class PkzLoadingImage extends StatefulWidget {
  final String pkzPath;
  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Function(Size)? onTrueSize;

  const PkzLoadingImage({
    Key? key,
    required this.pkzPath,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.onTrueSize,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PkzLoadingImageState();
}

class _PkzLoadingImageState extends State<PkzLoadingImage> {
  late bool _mock;
  late Future<Uint8List> data;

  @override
  void initState() {
    _mock = widget.path == "";
    if (!_mock) {
      data = () async {
        final data = await method.loadPkzFile(widget.pkzPath, widget.path);
        if (widget.onTrueSize != null) {
          var decodedImage = await decodeImageFromList(data);
          widget.onTrueSize!(
            Size(
              decodedImage.width.toDouble(),
              decodedImage.height.toDouble(),
            ),
          );
        }
        return data;
      }();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_mock) {
      return buildMock(widget.width, widget.height);
    }
    return Image(
      image: PkzImageProvider(widget.pkzPath, widget.path),
      width: widget.width,
      height: widget.height,
      errorBuilder: (a, b, c) {
        print("$b");
        print("$c");
        return buildError(widget.width, widget.height);
      },
      fit: widget.fit,
    );
  }
}
