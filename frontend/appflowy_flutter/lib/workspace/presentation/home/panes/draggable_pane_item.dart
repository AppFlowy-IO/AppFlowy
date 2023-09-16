import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/panes/panes.dart';
import 'package:appflowy/workspace/application/panes/panes_cubit/panes_cubit.dart';
import 'package:appflowy/workspace/application/tabs/tabs.dart';
import 'package:appflowy/workspace/presentation/home/home_draggables.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/widgets/draggable_item/draggable_item.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:vector_math/vector_math.dart' as math;
import 'dart:math';
import 'package:flutter/material.dart';

//TODO(squidrye):refactor cross draggables and add edge cases
enum FlowyDraggableHoverPosition {
  none,
  top,
  left,
  right,
  bottom,
}

class DraggablePaneItem extends StatefulWidget {
  const DraggablePaneItem({
    super.key,
    required this.pane,
    this.feedback,
    required this.child,
    required this.paneContext,
    this.allowDrag = true,
  });

  final CrossDraggablesEntity pane; //pass target pane
  final WidgetBuilder? feedback;
  final Widget child;
  final BuildContext paneContext;
  final bool allowDrag;

  @override
  State<DraggablePaneItem> createState() => _DraggablePaneItemState();
}

class _DraggablePaneItemState extends State<DraggablePaneItem> {
  FlowyDraggableHoverPosition position = FlowyDraggableHoverPosition.none;
  Size? size;
  @override
  Widget build(BuildContext context) {
    return DraggableItem<CrossDraggablesEntity>(
      data: widget.pane,
      onWillAccept: (data) =>
          data?.crossDraggableType == CrossDraggableType.pane
              ? widget.allowDrag
              : true,
      onMove: widget.allowDrag
          ? (data) {
              final renderBox =
                  widget.paneContext.findRenderObject() as RenderBox;
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
            }
          : null,
      onLeave: (_) => setState(() {
        position = FlowyDraggableHoverPosition.none;
      }),
      onAccept: (data) {
        _move(data, widget.pane);
        setState(() {
          position = FlowyDraggableHoverPosition.none;
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
    FlowyDraggableHoverPosition position,
  ) {
    final top = (widget.pane.draggable as PaneNode).tabs.pages > 1
        ? HomeSizes.tabBarHeigth + HomeSizes.topBarHeight
        : HomeSizes.topBarHeight;
    return switch (position) {
      FlowyDraggableHoverPosition.top => Positioned(
          top: top,
          child: Container(
            height: (size!.height) / 2,
            width: size!.width,
            color: Theme.of(context).hoverColor.withOpacity(0.5),
          ),
        ),
      FlowyDraggableHoverPosition.none => const SizedBox.shrink(),
      FlowyDraggableHoverPosition.left => Positioned(
          left: 0,
          top: top,
          child: Container(
            width: size!.width / 2,
            height: size!.height,
            color: Theme.of(context).hoverColor.withOpacity(0.5),
          ),
        ),
      FlowyDraggableHoverPosition.right => Positioned(
          top: top,
          left: size!.width / 2,
          child: Container(
            width: size!.width / 2,
            height: size!.height,
            color: Theme.of(context).hoverColor.withOpacity(0.5),
          ),
        ),
      FlowyDraggableHoverPosition.bottom => Positioned(
          top: size!.height / 2,
          child: Container(
            height: size!.height / 2,
            width: size!.width,
            color: Theme.of(context).hoverColor.withOpacity(0.5),
          ),
        ),
    };
  }

  FlowyDraggableHoverPosition _computeHoverPosition(
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
      return FlowyDraggableHoverPosition.right;
    } else if (normalizedAngle >= 45 && normalizedAngle < 135) {
      return FlowyDraggableHoverPosition.bottom;
    } else if (normalizedAngle >= 135 && normalizedAngle < 225) {
      return FlowyDraggableHoverPosition.left;
    } else if (normalizedAngle >= 225 && normalizedAngle < 315) {
      return FlowyDraggableHoverPosition.top;
    } else {
      return FlowyDraggableHoverPosition.none;
    }
  }

  bool _shouldAccept(
      CrossDraggablesEntity data, FlowyDraggableHoverPosition position) {
    return true;
  }

  void _move(CrossDraggablesEntity from, CrossDraggablesEntity to) async {
    Log.warn("From ${from.crossDraggableType} TO ${to.crossDraggableType}");
    final direction = switch (position) {
      FlowyDraggableHoverPosition.top => SplitDirection.down,
      FlowyDraggableHoverPosition.bottom => SplitDirection.down,
      FlowyDraggableHoverPosition.left => SplitDirection.right,
      FlowyDraggableHoverPosition.right => SplitDirection.right,
      FlowyDraggableHoverPosition.none => SplitDirection.down,
    };
    if (from.crossDraggableType == CrossDraggableType.view) {
      getIt<PanesCubit>().split(
        (from.draggable as ViewPB),
        direction,
        targetPaneId: (to.draggable as PaneNode).paneId,
      );
      return;
    } else if (from.crossDraggableType == CrossDraggableType.tab) {
      final view = await (from.draggable as (Tabs, PageManager)).$2.view;
      Log.warn(view);
      if (view == null) {
        return;
      }
      getIt<PanesCubit>().split(
        view,
        direction,
        targetPaneId: (to.draggable as PaneNode).paneId,
      );
      return;
    }
    getIt<PanesCubit>().movePane(
      from.draggable as PaneNode,
      to.draggable as PaneNode,
      position,
    );
  }
}
