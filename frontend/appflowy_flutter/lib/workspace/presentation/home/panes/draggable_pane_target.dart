import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/panes/panes.dart';
import 'package:appflowy/workspace/application/panes/panes_cubit/panes_cubit.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/home_draggables.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/widgets/draggable_item/draggable_target.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:vector_math/vector_math.dart' as math;
import 'dart:math';
import 'package:flutter/material.dart';

enum FlowyDraggableHoverPosition { none, top, left, right, bottom, tab }

class DraggablePaneTarget extends StatefulWidget {
  const DraggablePaneTarget({
    super.key,
    required this.pane,
    required this.child,
    required this.paneContext,
    required this.size,
    this.allowDrag = true,
  });

  final CrossDraggablesEntity pane; //pass target pane
  final Widget child;
  final BuildContext paneContext;
  final bool allowDrag;
  final Size size;

  @override
  State<DraggablePaneTarget> createState() => _DraggablePaneTargetState();
}

class _DraggablePaneTargetState extends State<DraggablePaneTarget> {
  FlowyDraggableHoverPosition position = FlowyDraggableHoverPosition.none;
  @override
  Widget build(BuildContext context) {
    return DraggableItemTarget<CrossDraggablesEntity>(
      onWillAccept: (data) => _shouldAccept(data!, position),
      onMove: (data) {
        final renderBox = widget.paneContext.findRenderObject() as RenderBox;
        final offset = renderBox.globalToLocal(data.offset);
        final positionN = _computeHoverPosition(
          offset,
          renderBox,
          data.data.crossDraggableType,
        );
        if (!_shouldAccept(data.data, position)) {
          return;
        }

        setState(() {
          position = positionN;
        });
      },
      onLeave: (_) => setState(() {
        position = FlowyDraggableHoverPosition.none;
      }),
      onAccept: (data) {
        _move(data, widget.pane);
        setState(() {
          position = FlowyDraggableHoverPosition.none;
        });
      },
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
            height: (widget.size.height) / 2,
            width: widget.size.width,
            color: Theme.of(context).hoverColor.withOpacity(0.5),
          ),
        ),
      FlowyDraggableHoverPosition.left => Positioned(
          left: 0,
          top: top,
          child: Container(
            width: widget.size.width / 2,
            height: widget.size.height,
            color: Theme.of(context).hoverColor.withOpacity(0.5),
          ),
        ),
      FlowyDraggableHoverPosition.right => Positioned(
          top: top,
          left: widget.size.width / 2,
          child: Container(
            width: widget.size.width / 2,
            height: widget.size.height,
            color: Theme.of(context).hoverColor.withOpacity(0.5),
          ),
        ),
      FlowyDraggableHoverPosition.bottom => Positioned(
          top: widget.size.height / 2,
          child: Container(
            height: widget.size.height / 2,
            width: widget.size.width,
            color: Theme.of(context).hoverColor.withOpacity(0.5),
          ),
        ),
      FlowyDraggableHoverPosition.tab => Positioned(
          top: 0,
          child: Container(
            height: top,
            width: widget.size.width,
            color: Theme.of(context).hoverColor.withOpacity(0.5),
          ),
        ),
      FlowyDraggableHoverPosition.none => const SizedBox.shrink(),
    };
  }

  FlowyDraggableHoverPosition _computeHoverPosition(
    Offset offset,
    RenderBox box,
    CrossDraggableType type,
  ) {
    final top = (widget.pane.draggable as PaneNode).tabs.pages > 1
        ? HomeSizes.tabBarHeigth + HomeSizes.topBarHeight
        : HomeSizes.topBarHeight;

    if (offset.dy <= top) {
      return FlowyDraggableHoverPosition.tab;
    }

    final Offset center = Offset(widget.size.width / 2, widget.size.height / 2);
    final double angleInRadians = atan2(
      offset.dy - center.dy,
      offset.dx - center.dx,
    );
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
    CrossDraggablesEntity data,
    FlowyDraggableHoverPosition position,
  ) {
    if (data.crossDraggableType == CrossDraggableType.pane &&
        (data.draggable as PaneNode).paneId ==
            (widget.pane.draggable as PaneNode).paneId) return false;
    return true;
  }

  void _move(CrossDraggablesEntity from, CrossDraggablesEntity to) {
    if (position == FlowyDraggableHoverPosition.tab) {
      switch (from.crossDraggableType) {
        case CrossDraggableType.view:
          (to.draggable as PaneNode)
              .tabs
              .openView((from.draggable as ViewPB).plugin());
          return;
        case CrossDraggableType.tab:
          {
            final fromTab = from.draggable as TabNode;
            (to.draggable as PaneNode)
                .tabs
                .openView(fromTab.pageManager.plugin);
            fromTab.tabs.closeView(fromTab.pageManager.plugin.id);
            return;
          }
        default:
          return;
      }
    }

    final direction = switch (position) {
      FlowyDraggableHoverPosition.top => SplitDirection.up,
      FlowyDraggableHoverPosition.bottom => SplitDirection.down,
      FlowyDraggableHoverPosition.left => SplitDirection.left,
      FlowyDraggableHoverPosition.right => SplitDirection.right,
      FlowyDraggableHoverPosition.none => SplitDirection.none,
      FlowyDraggableHoverPosition.tab => SplitDirection.none,
    };

    switch (from.crossDraggableType) {
      case CrossDraggableType.pane:
        getIt<PanesCubit>().movePane(
          from.draggable as PaneNode,
          to.draggable as PaneNode,
          position,
        );
        return;

      case CrossDraggableType.tab:
        final plugin = (from.draggable as TabNode).pageManager.plugin;
        (from.draggable as TabNode).tabs.closeView(plugin.id);
        getIt<PanesCubit>().split(
          plugin: plugin,
          splitDirection: direction,
          targetPaneId: (to.draggable as PaneNode).paneId,
        );
        return;

      case CrossDraggableType.view:
        getIt<PanesCubit>().split(
          plugin: (from.draggable as ViewPB).plugin(),
          splitDirection: direction,
          targetPaneId: (to.draggable as PaneNode).paneId,
        );
        return;

      case CrossDraggableType.none:
        return;
    }
  }
}
