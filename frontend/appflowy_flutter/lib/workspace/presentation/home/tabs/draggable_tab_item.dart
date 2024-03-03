import 'package:appflowy/workspace/application/tabs/tabs_controller.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/home_draggables.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/widgets/draggable_item/combined_draggable_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter/material.dart';

enum TabDraggableHoverPosition { none, left, right }

class DraggableTabItem extends StatefulWidget {
  DraggableTabItem({
    super.key,
    required this.child,
    required this.pageManager,
    required TabsController tabs,
    this.feedback,
  }) : tabs = CrossDraggablesEntity(draggable: TabNode(tabs, pageManager));

  final Widget child;
  final PageManager pageManager;
  final CrossDraggablesEntity tabs;
  final WidgetBuilder? feedback;

  @override
  State<DraggableTabItem> createState() => _DraggabletabItemState();
}

class _DraggabletabItemState extends State<DraggableTabItem> {
  TabDraggableHoverPosition position = TabDraggableHoverPosition.none;

  @override
  Widget build(BuildContext context) {
    final child = DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          right: position == TabDraggableHoverPosition.right
              ? BorderSide(
                  color: Theme.of(context).colorScheme.secondary,
                  width: 5,
                )
              : BorderSide.none,
          left: position == TabDraggableHoverPosition.left
              ? BorderSide(
                  color: Theme.of(context).colorScheme.secondary,
                  width: 5,
                )
              : BorderSide.none,
        ),
      ),
      child: widget.child,
    );

    return CombinedDraggableItem<CrossDraggablesEntity>(
      dragAnchorStrategy: pointerDragAnchorStrategy,
      enableAutoScroll: false,
      data: widget.tabs,
      onWillAcceptWithDetails: (data) => true,
      onMove: (data) {
        final renderBox = context.findRenderObject() as RenderBox;
        final offset = renderBox.globalToLocal(data.offset);

        final position = _computeHoverPosition(
          offset,
          renderBox.size,
          data.data,
        );
        setState(() => this.position = position);
      },
      onLeave: (_) => setState(() => position = TabDraggableHoverPosition.none),
      onAcceptWithDetails: (data) {
        _move(data.data, widget.tabs, data.data.crossDraggableType);
        setState(() => position = TabDraggableHoverPosition.none);
      },
      feedback: IntrinsicWidth(
        child: Opacity(
          opacity: 0.5,
          child: widget.feedback?.call(context) ?? child,
        ),
      ),
      child: child,
    );
  }

  void _move(
    CrossDraggablesEntity from,
    CrossDraggablesEntity to,
    CrossDraggableType type,
  ) {
    if (position == TabDraggableHoverPosition.none) {
      return;
    }

    final to = widget.tabs.draggable as TabNode;
    if (type == CrossDraggableType.view) {
      final fromView = from.draggable as ViewPB;
      to.tabs.openView(fromView.plugin());
    } else if (type == CrossDraggableType.tab) {
      final fromTab = from.draggable as TabNode;
      final plugin = (from.draggable as TabNode).pageManager.plugin;

      if (fromTab.tabs != to.tabs) {
        fromTab.tabs.closeView(plugin.id, move: true);
      } else {
        to.tabs.closeView(plugin.id, move: true);
      }

      to.tabs.move(
        from: fromTab.pageManager,
        to: to.pageManager,
        position: position,
      );
    }
  }

  TabDraggableHoverPosition _computeHoverPosition(
    Offset offset,
    Size size,
    CrossDraggablesEntity draggable,
  ) {
    if (draggable.crossDraggableType == CrossDraggableType.tab) {
      final data = draggable.draggable as TabNode;
      if (data.pageManager == widget.pageManager) {
        return TabDraggableHoverPosition.none;
      }

      final threshold = size.width / 2;
      if (offset.dx < threshold) {
        return TabDraggableHoverPosition.left;
      }

      return TabDraggableHoverPosition.right;
    }

    return TabDraggableHoverPosition.none;
  }
}
