import 'package:appflowy/workspace/application/panes/panes.dart';
import 'package:appflowy/workspace/application/panes/panes_cubit/panes_cubit.dart';
import 'package:appflowy/workspace/presentation/widgets/draggable_item/draggable_item.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vector_math/vector_math.dart' as math;
import 'dart:math';
import 'package:flutter/material.dart';

class DraggablePaneItem extends StatefulWidget {
  const DraggablePaneItem({
    super.key,
    required this.pane,
    this.feedback,
    required this.child,
    required this.paneContext,
  });

  final PaneNode pane; //pass target pane
  final WidgetBuilder? feedback;
  final Widget child;
  final BuildContext paneContext;

  @override
  State<DraggablePaneItem> createState() => _DraggablePaneItemState();
}

class _DraggablePaneItemState extends State<DraggablePaneItem> {
  PaneDraggableHoverPosition position = PaneDraggableHoverPosition.none;
  Size? size;
  @override
  Widget build(BuildContext context) {
    return DraggableItem<PaneNode>(
      data: widget.pane,
      onWillAccept: (data) => true,
      onMove: (data) {
        final renderBox = widget.paneContext.findRenderObject() as RenderBox;
        final offset = renderBox.globalToLocal(data.offset);
        setState(() {
          size = renderBox.size;
        });
        final positionN = _computeHoverPosition(offset, renderBox);
        if (!_shouldAccept(data.data, position)) {
          return;
        }
        setState(() {
          position = positionN;
        });
      },
      onLeave: (_) => setState(() {
        position = PaneDraggableHoverPosition.none;
      }),
      onAccept: (data) {
        _move(data, widget.pane);
        setState(() {
          position = PaneDraggableHoverPosition.none;
        });
      },
      enableAutoScroll: false,
      feedback: Material(
        child: IntrinsicWidth(
          child: Opacity(
            opacity: 0.5,
            child: widget.feedback?.call(context) ?? widget.child,
          ),
        ),
      ),
      child: Stack(
        children: [
          widget.child,
          _buildChildren(widget.paneContext, position),
        ],
      ),
    );
  }

  Widget _buildChildren(
    BuildContext context,
    PaneDraggableHoverPosition position,
  ) {
    return switch (position) {
      PaneDraggableHoverPosition.top => Positioned(
          top: 0,
          child: Container(
            height: (size!.height) / 2,
            width: size!.width,
            color: Colors.blue.withOpacity(0.5),
          ),
        ),
      PaneDraggableHoverPosition.none => const SizedBox.shrink(),
      PaneDraggableHoverPosition.left => Positioned(
          left: 0,
          child: Container(
            width: size!.width / 2,
            height: size!.height,
            color: Colors.blue.withOpacity(0.5),
          ),
        ),
      PaneDraggableHoverPosition.right => Positioned(
          left: size!.width / 2,
          child: Container(
            width: size!.width / 2,
            height: size!.height,
            color: Colors.blue.withOpacity(0.5),
          ),
        ),
      PaneDraggableHoverPosition.bottom => Positioned(
          top: size!.height / 2,
          child: Container(
            height: size!.height / 2,
            width: size!.width,
            color: Colors.blue.withOpacity(0.5),
          ),
        ),
      PaneDraggableHoverPosition.whole => Positioned(
          bottom: 0,
          left: 0,
          top: 0,
          right: 0,
          child: Container(
            height: size!.height,
            width: size!.width,
            color: Colors.blue.withOpacity(0.5),
          ),
        ),
    };
  }

  PaneDraggableHoverPosition _computeHoverPosition(
    Offset offset,
    RenderBox box,
  ) {
    final Offset center = Offset(size!.width / 2, size!.height / 2);
    final double angleInRadians =
        atan2(offset.dy - center.dy, offset.dx - center.dx);

    final double angleInDegrees = math.degrees(angleInRadians);
    double normalizedAngle = angleInDegrees % 360;
    if (normalizedAngle < 0) {
      normalizedAngle += 360;
    }
    // Determine the quadrant of the offset
    if (normalizedAngle >= 315 || normalizedAngle < 45) {
      return PaneDraggableHoverPosition.right;
    } else if (normalizedAngle >= 45 && normalizedAngle < 135) {
      return PaneDraggableHoverPosition.bottom;
    } else if (normalizedAngle >= 135 && normalizedAngle < 225) {
      return PaneDraggableHoverPosition.left;
    } else if (normalizedAngle >= 225 && normalizedAngle < 315) {
      return PaneDraggableHoverPosition.top;
    } else {
      return PaneDraggableHoverPosition.none;
    }
  }

  bool _shouldAccept(PaneNode data, PaneDraggableHoverPosition position) {
    return true;
  }

  void _move(PaneNode from, PaneNode to) {
    context.read<PanesCubit>().movePane(from, to, position);
  }
}
