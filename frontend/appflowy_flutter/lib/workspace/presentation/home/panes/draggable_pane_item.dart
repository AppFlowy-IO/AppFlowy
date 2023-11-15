import 'package:appflowy/workspace/presentation/home/home_draggables.dart';
import 'package:appflowy/workspace/presentation/widgets/draggable_item/draggable_item.dart';
import 'package:flutter/material.dart';

class DraggablePaneItem extends StatefulWidget {
  const DraggablePaneItem({
    super.key,
    required this.pane,
    required this.child,
    required this.paneContext,
    required this.size,
    required this.allowPaneDrag,
    this.feedback,
  });

  final CrossDraggablesEntity pane; // Pass target pane
  final Widget child;
  final BuildContext paneContext;
  final Size size;
  final bool allowPaneDrag;
  final WidgetBuilder? feedback;

  @override
  State<DraggablePaneItem> createState() => _DraggablePaneItemState();
}

class _DraggablePaneItemState extends State<DraggablePaneItem> {
  @override
  Widget build(BuildContext context) {
    if (!widget.allowPaneDrag) {
      return widget.child;
    }

    return DraggableItem<CrossDraggablesEntity>(
      dragAnchorStrategy: pointerDragAnchorStrategy,
      data: widget.pane,
      enableAutoScroll: false,
      feedback: Material(
        child: Opacity(
          opacity: 0.5,
          child: widget.feedback?.call(context) ?? widget.child,
        ),
      ),
      child: widget.child,
    );
  }
}
