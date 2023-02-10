import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/core/location/position.dart';
import 'package:appflowy_editor/src/core/location/selection.dart';
import 'package:appflowy_editor/src/extensions/object_extensions.dart';
import 'package:appflowy_editor/src/render/selection/selectable.dart';
import 'package:flutter/material.dart';

class ImageNodeWidget extends StatefulWidget {
  const ImageNodeWidget({
    Key? key,
    required this.node,
    required this.src,
    this.width,
    required this.alignment,
    required this.onResize,
  }) : super(key: key);

  final Node node;
  final String src;
  final double? width;
  final Alignment alignment;
  final void Function(double width) onResize;

  @override
  State<ImageNodeWidget> createState() => _ImageNodeWidgetState();
}

class _ImageNodeWidgetState extends State<ImageNodeWidget>
    with SelectableMixin {
  RenderBox get _renderBox => context.findRenderObject() as RenderBox;

  final _imageKey = GlobalKey();

  double? _imageWidth;
  double _initial = 0;
  double _distance = 0;
  bool _onFocus = false;

  ImageStream? _imageStream;
  late ImageStreamListener _imageStreamListener;

  @override
  void initState() {
    super.initState();

    _imageWidth = widget.width;
    _imageStreamListener = ImageStreamListener(
      (image, _) {
        _imageWidth = _imageKey.currentContext
            ?.findRenderObject()
            ?.unwrapOrNull<RenderBox>()
            ?.size
            .width;
      },
    );
  }

  @override
  void dispose() {
    _imageStream?.removeListener(_imageStreamListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // only support network image.
    return Container(
      key: _imageKey,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: _buildNetworkImage(context),
    );
  }

  @override
  bool get shouldCursorBlink => false;

  @override
  CursorStyle get cursorStyle => CursorStyle.borderLine;

  @override
  Position start() {
    return Position(path: widget.node.path, offset: 0);
  }

  @override
  Position end() {
    return start();
  }

  @override
  Position getPositionInOffset(Offset start) {
    return end();
  }

  @override
  Rect? getCursorRectInPosition(Position position) {
    final size = _renderBox.size;
    return Rect.fromLTWH(-size.width / 2.0, 0, size.width, size.height);
  }

  @override
  List<Rect> getRectsInSelection(Selection selection) {
    final renderBox = context.findRenderObject() as RenderBox;
    return [Offset.zero & renderBox.size];
  }

  @override
  Selection getSelectionInRange(Offset start, Offset end) {
    if (start <= end) {
      return Selection(start: this.start(), end: this.end());
    } else {
      return Selection(start: this.end(), end: this.start());
    }
  }

  @override
  Offset localToGlobal(Offset offset) {
    final renderBox = context.findRenderObject() as RenderBox;
    return renderBox.localToGlobal(offset);
  }

  Widget _buildNetworkImage(BuildContext context) {
    return Align(
      alignment: widget.alignment,
      child: MouseRegion(
        onEnter: (event) => setState(() {
          _onFocus = true;
        }),
        onExit: (event) => setState(() {
          _onFocus = false;
        }),
        child: _buildResizableImage(context),
      ),
    );
  }

  Widget _buildResizableImage(BuildContext context) {
    final networkImage = Image.network(
      widget.src,
      width: _imageWidth == null ? null : _imageWidth! - _distance,
      gaplessPlayback: true,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null ||
            loadingProgress.cumulativeBytesLoaded ==
                loadingProgress.expectedTotalBytes) return child;
        return _buildLoading(context);
      },
      errorBuilder: (context, error, stackTrace) {
        // _imageWidth ??= defaultMaxTextNodeWidth;
        return _buildError(context);
      },
    );
    if (_imageWidth == null) {
      _imageStream = networkImage.image.resolve(const ImageConfiguration())
        ..addListener(_imageStreamListener);
    }
    return Stack(
      children: [
        networkImage,
        _buildEdgeGesture(
          context,
          top: 0,
          left: 0,
          bottom: 0,
          width: 5,
          onUpdate: (distance) {
            setState(() {
              _distance = distance;
            });
          },
        ),
        _buildEdgeGesture(
          context,
          top: 0,
          right: 0,
          bottom: 0,
          width: 5,
          onUpdate: (distance) {
            setState(() {
              _distance = -distance;
            });
          },
        ),
      ],
    );
  }

  Widget _buildLoading(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox.fromSize(
            size: const Size(18, 18),
            child: const CircularProgressIndicator(),
          ),
          SizedBox.fromSize(
            size: const Size(10, 10),
          ),
          const Text('Loading'),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Container(
      height: 100,
      width: _imageWidth,
      alignment: Alignment.center,
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(4.0)),
        border: Border.all(width: 1, color: Colors.black),
      ),
      child: const Text('Could not load the image'),
    );
  }

  Widget _buildEdgeGesture(
    BuildContext context, {
    double? top,
    double? left,
    double? right,
    double? bottom,
    double? width,
    void Function(double distance)? onUpdate,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      width: width,
      child: GestureDetector(
        onHorizontalDragStart: (details) {
          _initial = details.globalPosition.dx;
        },
        onHorizontalDragUpdate: (details) {
          if (onUpdate != null) {
            onUpdate(details.globalPosition.dx - _initial);
          }
        },
        onHorizontalDragEnd: (details) {
          _imageWidth = _imageWidth! - _distance;
          _initial = 0;
          _distance = 0;

          widget.onResize(_imageWidth!);
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeLeftRight,
          child: _onFocus
              ? Center(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(5.0),
                      ),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
