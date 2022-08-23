import 'package:appflowy_editor/src/infra/flowy_svg.dart';
import 'package:appflowy_editor/src/render/rich_text/rich_text_style.dart';
import 'package:flutter/material.dart';

class ImageNodeWidget extends StatefulWidget {
  const ImageNodeWidget({
    Key? key,
    required this.src,
    required this.alignment,
    required this.onCopy,
    required this.onDelete,
    required this.onAlign,
  }) : super(key: key);

  final String src;
  final Alignment alignment;
  final VoidCallback onCopy;
  final VoidCallback onDelete;
  final void Function(Alignment alignment) onAlign;

  @override
  State<ImageNodeWidget> createState() => _ImageNodeWidgetState();
}

class _ImageNodeWidgetState extends State<ImageNodeWidget> {
  double? imageWidth = defaultMaxTextNodeWidth;
  double _initial = 0;
  double _distance = 0;
  bool _onFocus = false;

  @override
  Widget build(BuildContext context) {
    // only support network image.
    return _buildNetworkImage(context);
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
      width: imageWidth == null ? null : imageWidth! - _distance,
      loadingBuilder: (context, child, loadingProgress) =>
          loadingProgress == null
              ? child
              : SizedBox(
                  width: imageWidth,
                  height: 300,
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
                ),
    );
    if (imageWidth == null) {
      networkImage.image.resolve(const ImageConfiguration()).addListener(
        ImageStreamListener(
          (image, _) {
            imageWidth = image.image.width.toDouble();
          },
        ),
      );
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
        if (_onFocus)
          _buildImageToolbar(
            context,
            top: 8,
            right: 8,
            height: 30,
          ),
      ],
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
          imageWidth = imageWidth! - _distance;
          _initial = 0;
          _distance = 0;
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

  Widget _buildImageToolbar(
    BuildContext context, {
    double? top,
    double? left,
    double? right,
    double? width,
    double? height,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF333333),
          boxShadow: [
            BoxShadow(
              blurRadius: 5,
              spreadRadius: 1,
              color: Colors.black.withOpacity(0.1),
            ),
          ],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              hoverColor: Colors.transparent,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.fromLTRB(6.0, 4.0, 0.0, 4.0),
              icon: FlowySvg(
                name: 'image_toolbar/align_left',
                color: widget.alignment == Alignment.centerLeft
                    ? const Color(0xFF00BCF0)
                    : null,
              ),
              onPressed: () {
                widget.onAlign(Alignment.centerLeft);
              },
            ),
            IconButton(
              hoverColor: Colors.transparent,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.fromLTRB(0.0, 4.0, 0.0, 4.0),
              icon: FlowySvg(
                name: 'image_toolbar/align_center',
                color: widget.alignment == Alignment.center
                    ? const Color(0xFF00BCF0)
                    : null,
              ),
              onPressed: () {
                widget.onAlign(Alignment.center);
              },
            ),
            IconButton(
              hoverColor: Colors.transparent,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.fromLTRB(0.0, 4.0, 4.0, 4.0),
              icon: FlowySvg(
                name: 'image_toolbar/align_right',
                color: widget.alignment == Alignment.centerRight
                    ? const Color(0xFF00BCF0)
                    : null,
              ),
              onPressed: () {
                widget.onAlign(Alignment.centerRight);
              },
            ),
            const Center(
              child: FlowySvg(
                name: 'image_toolbar/divider',
              ),
            ),
            IconButton(
              hoverColor: Colors.transparent,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.fromLTRB(4.0, 4.0, 0.0, 4.0),
              icon: const FlowySvg(
                name: 'image_toolbar/copy',
              ),
              onPressed: () {
                widget.onCopy();
              },
            ),
            IconButton(
              hoverColor: Colors.transparent,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.fromLTRB(0.0, 4.0, 6.0, 4.0),
              icon: const FlowySvg(
                name: 'image_toolbar/delete',
              ),
              onPressed: () {
                widget.onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}
