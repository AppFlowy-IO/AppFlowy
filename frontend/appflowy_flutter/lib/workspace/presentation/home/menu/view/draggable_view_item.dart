import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/home_draggables.dart';
import 'package:appflowy/workspace/presentation/widgets/draggable_item/combined_draggable_item.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum DraggableHoverPosition {
  none,
  top,
  center,
  bottom,
}

class DraggableViewItem extends StatefulWidget {
  DraggableViewItem({
    super.key,
    required ViewPB view,
    this.feedback,
    required this.child,
    this.isFirstChild = false,
  }) : view = CrossDraggablesEntity(draggable: view);

  final Widget child;
  final WidgetBuilder? feedback;
  final CrossDraggablesEntity view;
  final bool isFirstChild;

  @override
  State<DraggableViewItem> createState() => _DraggableViewItemState();
}

class _DraggableViewItemState extends State<DraggableViewItem> {
  DraggableHoverPosition position = DraggableHoverPosition.none;

  @override
  Widget build(BuildContext context) {
    // add top border if the draggable item is on the top of the list
    // highlight the draggable item if the draggable item is on the center
    // add bottom border if the draggable item is on the bottom of the list
    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // only show the top border when the draggable item is the first child
        if (widget.isFirstChild)
          Divider(
            height: 2,
            thickness: 2,
            color: position == DraggableHoverPosition.top
                ? Theme.of(context).colorScheme.secondary
                : Colors.transparent,
          ),
        Container(
          color: position == DraggableHoverPosition.center
              ? Theme.of(context).colorScheme.secondary.withOpacity(0.5)
              : Colors.transparent,
          child: widget.child,
        ),
        Divider(
          height: 2,
          thickness: 2,
          color: position == DraggableHoverPosition.bottom
              ? Theme.of(context).colorScheme.secondary
              : Colors.transparent,
        ),
      ],
    );

    return CombinedDraggableItem<CrossDraggablesEntity>(
      data: widget.view,
      onWillAccept: (data) => true,
      onMove: (data) {
        if (data.data.crossDraggableType == CrossDraggableType.view) {
          final view = data.data.draggable as ViewPB;
          final renderBox = context.findRenderObject() as RenderBox;
          final offset = renderBox.globalToLocal(data.offset);
          final position = _computeHoverPosition(offset, renderBox.size);
          if (!_shouldAccept(view, position)) {
            return;
          }
          setState(() {
            Log.debug(
              'offset: $offset, position: $position, size: ${renderBox.size}',
            );
            this.position = position;
          });
        }
      },
      onLeave: (_) => setState(
        () => position = DraggableHoverPosition.none,
      ),
      onAccept: (data) {
        if (data.crossDraggableType == CrossDraggableType.view) {
          final from = data.draggable as ViewPB;
          _move(from, widget.view.draggable as ViewPB);
          setState(
            () => position = DraggableHoverPosition.none,
          );
        }
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

  void _move(ViewPB from, ViewPB to) {
    if (position == DraggableHoverPosition.center &&
        to.layout != ViewLayoutPB.Document) {
      // not support moving into a database
      return;
    }

    switch (position) {
      case DraggableHoverPosition.top:
        context.read<ViewBloc>().add(
              ViewEvent.move(
                from,
                to.parentViewId,
                null,
              ),
            );
        break;
      case DraggableHoverPosition.bottom:
        context.read<ViewBloc>().add(
              ViewEvent.move(
                from,
                to.parentViewId,
                to.id,
              ),
            );
        break;
      case DraggableHoverPosition.center:
        context.read<ViewBloc>().add(
              ViewEvent.move(
                from,
                to.id,
                to.childViews.lastOrNull?.id,
              ),
            );
        break;
      case DraggableHoverPosition.none:
        break;
    }
  }

  DraggableHoverPosition _computeHoverPosition(Offset offset, Size size) {
    final threshold = size.height / 3.0;
    if (widget.isFirstChild && offset.dy < -5.0) {
      return DraggableHoverPosition.top;
    }
    if (offset.dy > threshold) {
      return DraggableHoverPosition.bottom;
    }
    return DraggableHoverPosition.center;
  }

  bool _shouldAccept(ViewPB data, DraggableHoverPosition position) {
    final view = widget.view.draggable as ViewPB;
    // could not move the view to a database
    if (view.layout.isDatabaseView &&
        position == DraggableHoverPosition.center) {
      return false;
    }

    // ignore moving the view to itself
    if (data.id == view.id) {
      return false;
    }

    // ignore moving the view to its child view
    if (data.containsView(view)) {
      return false;
    }

    return true;
  }
}

extension on ViewPB {
  bool containsView(ViewPB view) {
    if (id == view.id) {
      return true;
    }

    return childViews.any((v) => v.containsView(view));
  }
}
