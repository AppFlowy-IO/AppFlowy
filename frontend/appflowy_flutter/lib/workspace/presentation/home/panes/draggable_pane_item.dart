import 'package:appflowy/workspace/presentation/home/home_draggables.dart';
import 'package:appflowy/workspace/presentation/widgets/draggable_item/draggable_item.dart';
import 'package:flutter/material.dart';

class DraggablePaneItem extends StatefulWidget {
  const DraggablePaneItem({
    super.key,
    required this.pane,
    this.feedback,
    required this.child,
    required this.paneContext,
    required this.size,
  });

  final CrossDraggablesEntity pane; //pass target pane
  final WidgetBuilder? feedback;
  final Widget child;
  final BuildContext paneContext;
  final Size size;

  @override
  State<DraggablePaneItem> createState() => _DraggablePaneItemState();
}

class _DraggablePaneItemState extends State<DraggablePaneItem> {
  @override
  Widget build(BuildContext context) {
    return DraggableItem<CrossDraggablesEntity>(
      dragAnchorStrategy: pointerDragAnchorStrategy,
      data: widget.pane,
      enableAutoScroll: false,
      feedback: Material(
        child: IntrinsicWidth(
          child: Opacity(
            opacity: 0.5,
            child: widget.feedback?.call(context) ?? widget.child,
          ),
        ),
      ),
      child: widget.child,
    );
  }
}
