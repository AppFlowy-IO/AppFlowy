import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/panes/panes.dart';
import 'package:appflowy/workspace/application/panes/panes_cubit/panes_cubit.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/home_draggables.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/widgets/draggable_item/draggable_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vector_math/vector_math.dart' as math;
import 'dart:math';
import 'package:flutter/material.dart';

//TODO(squidrye):refactor cross draggables and add edge cases
enum FlowyDraggableHoverPosition { none, top, left, right, bottom, tab }

class DraggablePaneItem extends StatefulWidget {
  const DraggablePaneItem({
    super.key,
    required this.pane,
    this.feedback,
    required this.child,
    required this.paneContext,
    required this.size,
    this.allowDrag = true,
  });

  final CrossDraggablesEntity pane; //pass target pane
  final WidgetBuilder? feedback;
  final Widget child;
  final BuildContext paneContext;
  final bool allowDrag;
  final Size size;

  @override
  State<DraggablePaneItem> createState() => _DraggablePaneItemState();
}

class _DraggablePaneItemState extends State<DraggablePaneItem> {
  FlowyDraggableHoverPosition position = FlowyDraggableHoverPosition.none;
  final ValueNotifier<Offset> dragStartPosition = ValueNotifier(Offset.zero);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      dragStartBehavior: DragStartBehavior.down,
      onPanDown: (details) {
        dragStartPosition.value = details.localPosition;
        context.read<PanesCubit>().setOffset(details.localPosition);
      },
      child: DraggableItem<CrossDraggablesEntity>(
        data: widget.pane,
        onWillAccept: (data) =>
            (data?.crossDraggableType == CrossDraggableType.pane &&
                    (data?.draggable as PaneNode).paneId ==
                        (widget.pane.draggable as PaneNode).paneId)
                ? false
                : true,
        onMove: (data) {
          final renderBox = widget.paneContext.findRenderObject() as RenderBox;
          final offset = renderBox.globalToLocal(data.offset);
          final positionN = _computeHoverPosition(
            offset,
            renderBox,
            context.read<PanesCubit>().state.dragOffset,
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
        enableAutoScroll: false,
        feedback: Transform.translate(
          offset: context.read<PanesCubit>().state.dragOffset,
          child: Material(
            child: IntrinsicWidth(
              child: Opacity(
                opacity: 0.5,
                child: widget.feedback?.call(context) ?? widget.child,
              ),
            ),
          ),
        ),
        child: Stack(
          children: [
            widget.child,
            _buildChildren(widget.paneContext, position),
          ],
        ),
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
    Offset dragOffset,
    CrossDraggableType type,
  ) {
    final top = (widget.pane.draggable as PaneNode).tabs.pages > 1
        ? HomeSizes.tabBarHeigth + HomeSizes.topBarHeight
        : HomeSizes.topBarHeight;

    final relativeOffset = switch (type) {
      CrossDraggableType.none => offset,
      CrossDraggableType.tab => offset,
      CrossDraggableType.view => offset,
      CrossDraggableType.pane =>
        Offset(offset.dx + dragOffset.dx, offset.dy + dragOffset.dy),
    };
    if (relativeOffset.dy <= top) {
      return FlowyDraggableHoverPosition.tab;
    }

    final Offset center = Offset(widget.size.width / 2, widget.size.height / 2);
    final double angleInRadians = atan2(
      relativeOffset.dy - center.dy,
      relativeOffset.dx - center.dx,
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
            fromTab.tabs.closeView(fromTab.pageManager.plugin.id);
            (to.draggable as PaneNode)
                .tabs
                .transferTab(pm: fromTab.pageManager);
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
          plugin,
          direction,
          targetPaneId: (to.draggable as PaneNode).paneId,
        );
        return;

      case CrossDraggableType.view:
        getIt<PanesCubit>().split(
          (from.draggable as ViewPB).plugin(),
          direction,
          targetPaneId: (to.draggable as PaneNode).paneId,
        );
        return;

      case CrossDraggableType.none:
        return;
    }
  }
}
