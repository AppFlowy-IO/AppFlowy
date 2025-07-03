import 'package:flutter/material.dart';

class DesktopCoverAlignController extends ChangeNotifier {
  DesktopCoverAlignController(String? offset) {
    double x = 0;
    double y = 0;
    if (offset != null) {
      final splits = offset.split(',');

      try {
        x = double.parse(splits.first);
      } catch (e) {
        x = 0;
      }
      try {
        y = double.parse(splits.last);
      } catch (e) {
        y = 0;
      }
    }

    _initialAlignment = Alignment(x, y);
    _adjustedAlign = _initialAlignment;
  }

  late final Alignment _initialAlignment;

  late Alignment _adjustedAlign;

  Alignment get alignment => _adjustedAlign;

  void reset() {
    _adjustedAlign = Alignment.center;
    notifyListeners();
  }

  void cancel() {
    _adjustedAlign = _initialAlignment;
    notifyListeners();
  }

  void changeAlign(double x, double y) {
    _adjustedAlign = Alignment(x, y);
  }

  bool get isModified => _adjustedAlign != _initialAlignment;

  String getAlignAttribute() {
    return "${_adjustedAlign.x.toStringAsFixed(1)},${_adjustedAlign.y.toStringAsFixed(1)}";
  }
}

class DesktopCoverAlign extends StatefulWidget {
  const DesktopCoverAlign({
    super.key,
    required this.controller,
    required this.imageProvider,
    this.fit = BoxFit.cover,
    this.alignEnable = false,
  });
  final DesktopCoverAlignController controller;
  final ImageProvider imageProvider;
  final BoxFit fit;
  final bool alignEnable;

  @override
  State<DesktopCoverAlign> createState() => _DesktopCoverAlignState();
}

class _DesktopCoverAlignState extends State<DesktopCoverAlign> {
  ImageStreamListener? _imageStreamListener;
  ImageStream? _imageStream;
  Size? _imageSize;

  Size? _frameSize;

  double x = 0;
  double y = 0;
  late final DesktopCoverAlignController controller;

  @override
  void initState() {
    super.initState();
    controller = widget.controller;
    final alignment = controller.alignment;
    x = alignment.x;
    y = alignment.y;
    controller.addListener(updateAlign);
  }

  @override
  void dispose() {
    controller.removeListener(updateAlign);
    super.dispose();

    _stopImageStream();
  }

  @override
  void didChangeDependencies() {
    _resolveImage();
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(DesktopCoverAlign oldWidget) {
    if (widget.imageProvider != oldWidget.imageProvider) {
      controller.reset();
      _resolveImage();
    }
    super.didUpdateWidget(oldWidget);
  }

  void updateAlign() {
    setState(() {
      x = controller.alignment.x;
      y = controller.alignment.y;
    });
  }

  void _resolveImage() {
    final ImageStream newStream = widget.imageProvider.resolve(
      const ImageConfiguration(),
    );
    _updateSourceStream(newStream);
  }

  ImageStreamListener _getOrCreateListener() {
    void handleImageFrame(ImageInfo info, bool synchronousCall) {
      void setupCB() {
        _imageSize = Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        );
      }

      synchronousCall ? setupCB() : setState(setupCB);
    }

    _imageStreamListener = ImageStreamListener(
      handleImageFrame,
    );

    return _imageStreamListener!;
  }

  void _updateSourceStream(ImageStream newStream) {
    if (_imageStream?.key == newStream.key) {
      return;
    }
    _imageStream?.removeListener(_imageStreamListener!);
    _imageStream = newStream;
    _imageStream!.addListener(_getOrCreateListener());
  }

  void _stopImageStream() {
    _imageStream?.removeListener(_imageStreamListener!);
  }

  void _changeAlignOffset(Offset offset) {
    setState(() {
      if (_imageSize == null || _frameSize == null) return;

      final imageRatio = _imageSize!.aspectRatio;
      final frameRatio = _frameSize!.aspectRatio;
      final isVertical = imageRatio < frameRatio;

      final imageFrameHeight =
          _frameSize!.width / _imageSize!.width * _imageSize!.height;
      final imageFrameWidth =
          _frameSize!.height / _imageSize!.height * _imageSize!.width;
      final exceedWidth = imageFrameWidth - _frameSize!.width;
      final exceedHeight = imageFrameHeight - _frameSize!.height;

      if (isVertical) {
        final targetY = y + offset.dy / exceedHeight * 2;
        if (targetY >= -1 && targetY <= 1) {
          y = targetY;
        }
      } else {
        final targetX = x + offset.dx / exceedWidth * 2;
        if (targetX >= -1 && targetX <= 1) {
          x = targetX;
        }
      }
      widget.controller.changeAlign(x, y);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _frameSize =
            Size(constraints.biggest.width, constraints.biggest.height);
        _imageSize ??= _frameSize;

        Widget child = Image(
          image: widget.imageProvider,
          width: _frameSize!.width,
          height: _frameSize!.height,
          fit: widget.fit,
          alignment: Alignment(-x, -y),
        );
        if (widget.alignEnable && _imageSize != null) {
          child = GestureDetector(
            onHorizontalDragUpdate: (details) {
              final delta = details.delta;
              _changeAlignOffset(delta);
            },
            onVerticalDragUpdate: (details) {
              final delta = details.delta;
              _changeAlignOffset(delta);
            },
            child: child,
          );
        }
        return child;
      },
    );
  }
}
