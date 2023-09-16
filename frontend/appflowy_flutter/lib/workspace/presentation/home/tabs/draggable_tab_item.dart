import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/home_draggables.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/widgets/draggable_item/draggable_item.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/workspace/application/tabs/tabs.dart';
import 'package:provider/provider.dart';

enum TabDraggableHoverPosition {
  none,
  left,
  center,
  right,
}

//TODO(squidrye):refactor crossdraggable and add edge cases for tabs
class DraggableTabItem extends StatefulWidget {
  DraggableTabItem({
    super.key,
    this.feedback,
    required this.child,
    required this.pageManager,
    required Tabs tabs,
    required this.tabContext,
  }) : tabs = CrossDraggablesEntity(draggable: (tabs, pageManager));

  final Widget child;
  final WidgetBuilder? feedback;
  final CrossDraggablesEntity tabs;
  final PageManager pageManager;
  final BuildContext tabContext;

  @override
  State<DraggableTabItem> createState() => _DraggabletabItemState();
}

class _DraggabletabItemState extends State<DraggableTabItem> {
  TabDraggableHoverPosition position = TabDraggableHoverPosition.none;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      decoration: BoxDecoration(
        border: Border(
          right: position == TabDraggableHoverPosition.right
              ? BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 5,
                )
              : BorderSide.none,
          left: position == TabDraggableHoverPosition.left
              ? BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 5,
                )
              : BorderSide.none,
        ),
      ),
      child: widget.child,
    );

    return DraggableItem<CrossDraggablesEntity>(
      enableAutoScroll: false,
      data: widget.tabs,
      onWillAccept: (data) => true,
      onMove: (data) {
        (Tabs, PageManager)? tab;
        if (data.data.crossDraggableType == CrossDraggableType.pane) {
          return;
        } else if (data.data.crossDraggableType == CrossDraggableType.view) {
          tab = (
            Tabs(
              currentIndex: 0,
              pageManagers: [
                PageManager()
                  ..setPlugin((data.data.draggable as ViewPB).plugin())
              ],
            ),
            PageManager()..setPlugin((data.data.draggable as ViewPB).plugin())
          );
        } else {
          tab = data.data.draggable as (Tabs, PageManager);
        }
        final renderBox = widget.tabContext.findRenderObject() as RenderBox;
        final offset = renderBox.globalToLocal(data.offset);
        final position = _computeHoverPosition(offset, renderBox.size);
        if (!_shouldAccept(tab, position)) {
          return;
        }
        setState(() {
          this.position = position;
        });
      },
      onLeave: (_) => setState(
        () {
          position = TabDraggableHoverPosition.none;
        },
      ),
      onAccept: (data) {
        final to = widget.tabs.draggable as (Tabs, PageManager);
        (Tabs, PageManager)? from;
        if (data.crossDraggableType == CrossDraggableType.pane) {
          return;
        } else if (data.crossDraggableType == CrossDraggableType.view) {
          from = (
            Tabs(currentIndex: 0, pageManagers: [
              PageManager()..setPlugin((data.draggable as ViewPB).plugin())
            ]),
            PageManager()..setPlugin((data.draggable as ViewPB).plugin())
          );
        } else {
          from = data.draggable as (Tabs, PageManager);
        }
        _move(from, to);
        setState(
          () => position = TabDraggableHoverPosition.none,
        );
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

  void _move((Tabs, PageManager) from, (Tabs, PageManager) to) {
    from.$1.closeView(from.$2.notifier.plugin.id);
    Provider.of<Tabs>(context, listen: false).move(
      from: from.$2,
      to: to.$2,
      position: position,
    );
  }

  TabDraggableHoverPosition _computeHoverPosition(Offset offset, Size size) {
    final thresholdL = size.width / 4;
    final thresholdR = size.width * 4 / 3;
    if (offset.dx < thresholdL) {
      return TabDraggableHoverPosition.left;
    } else if (offset.dx > thresholdR) {
      Log.warn("Right");
      return TabDraggableHoverPosition.right;
    } else {
      return TabDraggableHoverPosition.center;
    }
  }

  bool _shouldAccept(
      (Tabs, PageManager) data, TabDraggableHoverPosition position) {
    return true;
  }
}
