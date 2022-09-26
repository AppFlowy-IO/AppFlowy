import 'package:appflowy_editor/src/extensions/object_extensions.dart';
import 'package:appflowy_editor/src/document/node.dart';
import 'package:appflowy_editor/src/document/position.dart';
import 'package:appflowy_editor/src/document/selection.dart';
import 'package:appflowy_editor/src/infra/flowy_svg.dart';
import 'package:appflowy_editor/src/render/selection/selectable.dart';
import 'package:flutter/material.dart';

class VideoNodeWidget extends StatefulWidget {
  const VideoNodeWidget({
    Key? key,
    required this.node,
    required this.src,
    this.width,
    required this.alignment,
    required this.onCopy,
    required this.onDelete,
    required this.onAlign,
    required this.onResize,
  }) : super(key: key);

  final Node node;
  final String src;
  final double? width;
  final Alignment alignment;
  final VoidCallback onCopy;
  final VoidCallback onDelete;
  final void Function(Alignment alignment) onAlign;
  final void Function(double width) onResize;

  @override
  State<VideoNodeWidget> createState() => _VideoNodeWidgetState();
}

class _VideoNodeWidgetState extends State<VideoNodeWidget>
    with SelectableMixin {
  final _videoKey = GlobalKey();

  double? _videoWidth;
  double _initial = 0;
  double _distance = 0;
  bool _onFocus = false;

  // VideoStream? _videoStream;
  // late VideoStreamListener _videoStreamListener;

  @override
  void initState() {
    super.initState();

    _videoWidth = widget.width;
    // _videoStreamListener = VideoStreamListener(
    //   (video, _) {
    //     _videoWidth = _videoKey.currentContext
    //         ?.findRenderObject()
    //         ?.unwrapOrNull<RenderBox>()
    //         ?.size
    //         .width;
    //   },
    // );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // only support network video.
    return Container(
      key: _videoKey,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: _buildNetworkVideo(context),
    );
  }

  @override
  Position start() {
    return Position(path: widget.node.path, offset: 0);
  }

  @override
  Position end() {
    return Position(path: widget.node.path, offset: 1);
  }

  @override
  Position getPositionInOffset(Offset start) {
    return end();
  }

  @override
  Rect? getCursorRectInPosition(Position position) {
    return null;
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

  Widget _buildNetworkVideo(BuildContext context) {
    return Align(
      alignment: widget.alignment,
      child: MouseRegion(
        onEnter: (event) => setState(() {
          _onFocus = true;
        }),
        onExit: (event) => setState(() {
          _onFocus = false;
        }),
        child: _buildResizableVideo(context),
      ),
    );
  }

  Widget _buildResizableVideo(BuildContext context) {
    // TODO: replace by video widget
    final networkVideo = Image.network(
      widget.src,
      width: _videoWidth == null ? null : _videoWidth! - _distance,
      gaplessPlayback: true,
      loadingBuilder: (context, child, loadingProgress) =>
          loadingProgress == null ? child : _buildLoading(context),
      errorBuilder: (context, error, stackTrace) {
        // _imageWidth ??= defaultMaxTextNodeWidth;
        return _buildError(context);
      },
    );
    // if (_videoWidth == null) {
    //   _videoStream = networkVideo.video.resolve(const ImageConfiguration())
    //     ..addListener(_videoStreamListener);
    // }
    return Stack(
      children: [
        networkVideo,
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
          VideoToolbar(
            top: 8,
            right: 8,
            height: 30,
            alignment: widget.alignment,
            onAlign: widget.onAlign,
            onCopy: widget.onCopy,
            onDelete: widget.onDelete,
          )
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
      width: _videoWidth,
      alignment: Alignment.center,
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(4.0)),
        border: Border.all(width: 1, color: Colors.black),
      ),
      child: const Text('Could not load the video'),
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
          _videoWidth = _videoWidth! - _distance;
          _initial = 0;
          _distance = 0;

          widget.onResize(_videoWidth!);
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

@visibleForTesting
class VideoToolbar extends StatelessWidget {
  const VideoToolbar({
    Key? key,
    required this.top,
    required this.right,
    required this.height,
    required this.alignment,
    required this.onCopy,
    required this.onDelete,
    required this.onAlign,
  }) : super(key: key);

  final double top;
  final double right;
  final double height;
  final Alignment alignment;
  final VoidCallback onCopy;
  final VoidCallback onDelete;
  final void Function(Alignment alignment) onAlign;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
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
                name: 'video_toolbar/align_left',
                color: alignment == Alignment.centerLeft
                    ? const Color(0xFF00BCF0)
                    : null,
              ),
              onPressed: () {
                onAlign(Alignment.centerLeft);
              },
            ),
            IconButton(
              hoverColor: Colors.transparent,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.fromLTRB(0.0, 4.0, 0.0, 4.0),
              icon: FlowySvg(
                name: 'video_toolbar/align_center',
                color: alignment == Alignment.center
                    ? const Color(0xFF00BCF0)
                    : null,
              ),
              onPressed: () {
                onAlign(Alignment.center);
              },
            ),
            IconButton(
              hoverColor: Colors.transparent,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.fromLTRB(0.0, 4.0, 4.0, 4.0),
              icon: FlowySvg(
                name: 'video_toolbar/align_right',
                color: alignment == Alignment.centerRight
                    ? const Color(0xFF00BCF0)
                    : null,
              ),
              onPressed: () {
                onAlign(Alignment.centerRight);
              },
            ),
            const Center(
              child: FlowySvg(
                name: 'video_toolbar/divider',
              ),
            ),
            IconButton(
              hoverColor: Colors.transparent,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.fromLTRB(4.0, 4.0, 0.0, 4.0),
              icon: const FlowySvg(
                name: 'video_toolbar/copy',
              ),
              onPressed: () {
                onCopy();
              },
            ),
            IconButton(
              hoverColor: Colors.transparent,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.fromLTRB(0.0, 4.0, 6.0, 4.0),
              icon: const FlowySvg(
                name: 'video_toolbar/delete',
              ),
              onPressed: () {
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}
