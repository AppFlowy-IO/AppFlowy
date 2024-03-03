import 'dart:math';

import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/panes/panes.dart';
import 'package:appflowy/workspace/application/panes/panes_bloc/panes_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/home_draggables.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/widgets/draggable_item/draggable_target.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as math;

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

  final CrossDraggablesEntity pane;
  final Widget child;
  final BuildContext paneContext;
  final Size size;
  final bool allowDrag;

  @override
  State<DraggablePaneTarget> createState() => _DraggablePaneTargetState();
}

class _DraggablePaneTargetState extends State<DraggablePaneTarget> {
  FlowyDraggableHoverPosition position = FlowyDraggableHoverPosition.none;
  @override
  Widget build(BuildContext context) {
    return DraggableItemTarget<CrossDraggablesEntity>(
      onWillAcceptWithDetails: (data) => _shouldAccept(data.data, position),
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

        setState(() => position = positionN);
      },
      onLeave: (_) => setState(
        () => position = FlowyDraggableHoverPosition.none,
      ),
      onAcceptWithDetails: (data) {
        _move(data.data, widget.pane);
        setState(() => position = FlowyDraggableHoverPosition.none);
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
    if (position == FlowyDraggableHoverPosition.none) {
      return const SizedBox.shrink();
    }

    final (left, top, height, width) = _getHoverWidgetPosition(position);

    return Positioned(
      top: top,
      left: left,
      child: Container(
        height: height,
        width: width,
        color: Theme.of(context).hoverColor.withOpacity(0.5),
      ),
    );
  }

  (
    double? left,
    double? top,
    double? height,
    double? width,
  ) _getHoverWidgetPosition(FlowyDraggableHoverPosition position) {
    double? left, top, height, width;

    final topOffset = (widget.pane.draggable as PaneNode).tabsController.pages > 1
        ? HomeSizes.tabBarHeight + HomeSizes.topBarHeight
        : HomeSizes.topBarHeight;

    switch (position) {
      case FlowyDraggableHoverPosition.top:
        top = topOffset;
        left = null;
        height = widget.size.height / 2;
        width = widget.size.width;
        break;
      case FlowyDraggableHoverPosition.left:
        top = topOffset;
        left = 0;
        height = widget.size.height;
        width = widget.size.width / 2;
        break;
      case FlowyDraggableHoverPosition.right:
        top = topOffset;
        left = widget.size.width / 2;
        height = widget.size.height;
        width = widget.size.width / 2;
        break;
      case FlowyDraggableHoverPosition.bottom:
        top = widget.size.height / 2;
        height = widget.size.height / 2;
        width = widget.size.width;
        left = null;
        break;
      case FlowyDraggableHoverPosition.tab:
        top = 0;
        left = 0;
        height = topOffset;
        width = widget.size.width;
        break;
      default:
        break;
    }

    return (left, top, height, width);
  }

  FlowyDraggableHoverPosition _computeHoverPosition(
    Offset offset,
    RenderBox box,
    CrossDraggableType type,
  ) {
    final top = (widget.pane.draggable as PaneNode).tabsController.pages > 1
        ? HomeSizes.tabBarHeight + HomeSizes.topBarHeight
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
    }

    return FlowyDraggableHoverPosition.none;
  }

  bool _shouldAccept(
    CrossDraggablesEntity data,
    FlowyDraggableHoverPosition position,
  ) {
    if (data.crossDraggableType == CrossDraggableType.pane &&
        (data.draggable as PaneNode).paneId == (widget.pane.draggable as PaneNode).paneId) {
      return false;
    }

    return true;
  }

  void _move(CrossDraggablesEntity from, CrossDraggablesEntity to) {
    if (position == FlowyDraggableHoverPosition.tab) {
      switch (from.crossDraggableType) {
        case CrossDraggableType.view:
          (to.draggable as PaneNode).tabsController.openView((from.draggable as ViewPB).plugin());
          return;
        case CrossDraggableType.tab:
          final fromTab = from.draggable as TabNode;
          final destinationPaneNode = to.draggable as PaneNode;
          bool contains = false;
          for (final element in destinationPaneNode.tabsController.pageManagers) {
            if (element.plugin.id == fromTab.pageManager.plugin.id) {
              contains = true;
              break;
            }
          }

          if (!contains) {
            fromTab.tabs.closeView(fromTab.pageManager.plugin.id);
            destinationPaneNode.tabsController.openView(
              fromTab.pageManager.plugin,
            );
          }

          return;
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
        getIt<PanesBloc>().add(
          MovePane(
            from: from.draggable as PaneNode,
            to: to.draggable as PaneNode,
            position: position,
          ),
        );
        return;

      case CrossDraggableType.tab:
        final plugin = (from.draggable as TabNode).pageManager.plugin;
        (from.draggable as TabNode).tabs.closeView(plugin.id);
        getIt<PanesBloc>().add(
          SplitPane(
            plugin: plugin,
            splitDirection: direction,
            targetPaneId: (to.draggable as PaneNode).paneId,
          ),
        );
        return;

      case CrossDraggableType.view:
        getIt<PanesBloc>().add(
          SplitPane(
            plugin: (from.draggable as ViewPB).plugin(),
            splitDirection: direction,
            targetPaneId: (to.draggable as PaneNode).paneId,
          ),
        );
        return;

      case CrossDraggableType.none:
        return;
    }
  }
}
