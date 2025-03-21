import 'package:appflowy/workspace/application/menu/sidebar_sections_bloc.dart';
import 'package:appflowy/workspace/application/view/folder_view_ext.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/experimental/bloc/page/page_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/draggable_view_item.dart';
import 'package:appflowy/workspace/presentation/widgets/draggable_item/draggable_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:universal_platform/universal_platform.dart';

const kDraggableFolderViewItemDividerHeight = 2.0;

class DraggableFolderViewItem extends StatefulWidget {
  const DraggableFolderViewItem({
    super.key,
    required this.view,
    this.feedback,
    required this.child,
    this.isFirstChild = false,
    this.centerHighlightColor,
    this.topHighlightColor,
    this.bottomHighlightColor,
    this.onDragging,
    this.onMove,
  });

  final Widget child;
  final WidgetBuilder? feedback;
  final FolderViewPB view;
  final bool isFirstChild;
  final Color? centerHighlightColor;
  final Color? topHighlightColor;
  final Color? bottomHighlightColor;
  final void Function(bool isDragging)? onDragging;
  final void Function(FolderViewPB from, FolderViewPB to)? onMove;

  @override
  State<DraggableFolderViewItem> createState() =>
      _DraggableFolderViewItemState();
}

class _DraggableFolderViewItemState extends State<DraggableFolderViewItem> {
  DraggableHoverPosition position = DraggableHoverPosition.none;

  final hoverColor = const Color(0xFF00C8FF);

  @override
  Widget build(BuildContext context) {
    // add top border if the draggable item is on the top of the list
    // highlight the draggable item if the draggable item is on the center
    // add bottom border if the draggable item is on the bottom of the list
    final child = UniversalPlatform.isMobile
        ? _buildMobileDraggableItem()
        : _buildDesktopDraggableItem();

    return DraggableItem<FolderViewPB>(
      data: widget.view,
      onDragging: widget.onDragging,
      onWillAcceptWithDetails: (data) => true,
      onMove: (data) {
        final renderBox = context.findRenderObject() as RenderBox;
        final offset = renderBox.globalToLocal(data.offset);

        if (offset.dx > renderBox.size.width) {
          return;
        }

        final position = _computeHoverPosition(offset, renderBox.size);
        if (!_shouldAccept(data.data, position)) {
          return;
        }
        _updatePosition(position);
      },
      onLeave: (_) => _updatePosition(
        DraggableHoverPosition.none,
      ),
      onAcceptWithDetails: (details) {
        final data = details.data;
        _move(data, widget.view);
        _updatePosition(DraggableHoverPosition.none);
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

  Widget _buildDesktopDraggableItem() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // only show the top border when the draggable item is the first child
        if (widget.isFirstChild)
          Divider(
            height: kDraggableFolderViewItemDividerHeight,
            thickness: kDraggableFolderViewItemDividerHeight,
            color: position == DraggableHoverPosition.top
                ? widget.topHighlightColor ?? hoverColor
                : Colors.transparent,
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.0),
            color: position == DraggableHoverPosition.center
                ? widget.centerHighlightColor ??
                    hoverColor.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
          child: widget.child,
        ),
        Divider(
          height: kDraggableFolderViewItemDividerHeight,
          thickness: kDraggableFolderViewItemDividerHeight,
          color: position == DraggableHoverPosition.bottom
              ? widget.bottomHighlightColor ?? hoverColor
              : Colors.transparent,
        ),
      ],
    );
  }

  Widget _buildMobileDraggableItem() {
    return Stack(
      children: [
        if (widget.isFirstChild)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: kDraggableFolderViewItemDividerHeight,
            child: Divider(
              height: kDraggableFolderViewItemDividerHeight,
              thickness: kDraggableFolderViewItemDividerHeight,
              color: position == DraggableHoverPosition.top
                  ? widget.topHighlightColor ??
                      Theme.of(context).colorScheme.secondary
                  : Colors.transparent,
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4.0),
            color: position == DraggableHoverPosition.center
                ? widget.centerHighlightColor ??
                    Theme.of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: 0.5)
                : Colors.transparent,
          ),
          child: widget.child,
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: kDraggableFolderViewItemDividerHeight,
          child: Divider(
            height: kDraggableFolderViewItemDividerHeight,
            thickness: kDraggableFolderViewItemDividerHeight,
            color: position == DraggableHoverPosition.bottom
                ? widget.bottomHighlightColor ??
                    Theme.of(context).colorScheme.secondary
                : Colors.transparent,
          ),
        ),
      ],
    );
  }

  void _updatePosition(DraggableHoverPosition position) {
    if (UniversalPlatform.isMobile && position != this.position) {
      HapticFeedback.mediumImpact();
    }
    setState(() => this.position = position);
  }

  void _move(FolderViewPB from, FolderViewPB to) {
    if (position == DraggableHoverPosition.center &&
        to.layout != ViewLayoutPB.Document) {
      // not support moving into a database
      return;
    }

    if (widget.onMove != null) {
      widget.onMove?.call(from, to);
      return;
    }

    final fromSection = getViewSection(from);
    final toSection = getViewSection(to);

    switch (position) {
      case DraggableHoverPosition.top:
        context.read<FolderViewBloc>().add(
              FolderViewEvent.move(
                from,
                '', //fixme: from.parentViewId
                null,
                fromSection,
                toSection,
              ),
            );
        break;
      case DraggableHoverPosition.bottom:
        context.read<FolderViewBloc>().add(
              FolderViewEvent.move(
                from,
                '', //fixme: from.parentViewId
                null,
                fromSection,
                toSection,
              ),
            );
        break;
      case DraggableHoverPosition.center:
        context.read<FolderViewBloc>().add(
              FolderViewEvent.move(
                from,
                '', //fixme: from.parentViewId
                null,
                fromSection,
                toSection,
              ),
            );
        break;
      case DraggableHoverPosition.none:
        break;
    }
  }

  DraggableHoverPosition _computeHoverPosition(Offset offset, Size size) {
    final threshold = size.height / 5.0;
    if (widget.isFirstChild && offset.dy < -5.0) {
      return DraggableHoverPosition.top;
    }
    if (offset.dy > threshold) {
      return DraggableHoverPosition.bottom;
    }
    return DraggableHoverPosition.center;
  }

  bool _shouldAccept(FolderViewPB data, DraggableHoverPosition position) {
    // could not move the view to a database
    if (widget.view.layout.isDatabaseView &&
        position == DraggableHoverPosition.center) {
      return false;
    }

    // ignore moving the view to itself
    if (data.viewId == widget.view.viewId) {
      return false;
    }

    // ignore moving the view to its child view
    if (data.containsView(widget.view)) {
      return false;
    }

    return true;
  }

  ViewSectionPB? getViewSection(FolderViewPB view) {
    return context.read<SidebarSectionsBloc>().getViewSection(view.viewPB);
  }
}

extension on FolderViewPB {
  bool containsView(FolderViewPB view) {
    if (viewId == view.viewId) {
      return true;
    }

    return children.any((v) => v.containsView(view));
  }
}
