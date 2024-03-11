import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:async/async.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/widget/mouse_hover_builder.dart';
import 'package:styled_widget/styled_widget.dart';

class StyledScrollbar extends StatefulWidget {
  const StyledScrollbar({
    super.key,
    this.size,
    required this.axis,
    required this.controller,
    this.onDrag,
    this.contentSize,
    this.showTrack = false,
    this.autoHideScrollbar = true,
    this.handleColor,
    this.trackColor,
  });

  final double? size;
  final Axis axis;
  final ScrollController controller;
  final Function(double)? onDrag;
  final bool showTrack;
  final bool autoHideScrollbar;
  final Color? handleColor;
  final Color? trackColor;

  // ignore: todo
  // TODO: Remove contentHeight if we can fix this issue
  // https://stackoverflow.com/questions/60855712/flutter-how-to-force-scrollcontroller-to-recalculate-position-maxextents
  final double? contentSize;

  @override
  ScrollbarState createState() => ScrollbarState();
}

class ScrollbarState extends State<StyledScrollbar> {
  double _viewExtent = 100;
  CancelableOperation? _hideScrollbarOperation;
  bool hideHandler = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScrollChanged);
    widget.controller.position.isScrollingNotifier
        .addListener(_hideScrollbarInTime);
  }

  @override
  void dispose() {
    if (widget.controller.hasClients) {
      widget.controller.removeListener(_onScrollChanged);
      widget.controller.position.isScrollingNotifier
          .removeListener(_hideScrollbarInTime);
    }
    super.dispose();
  }

  void _onScrollChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, BoxConstraints constraints) {
        double maxExtent;
        final double? contentSize = widget.contentSize;

        switch (widget.axis) {
          case Axis.vertical:
            // Use supplied contentSize if we have it, otherwise just fallback to maxScrollExtents
            if (contentSize != null && contentSize > 0) {
              maxExtent = contentSize - constraints.maxHeight;
            } else {
              maxExtent = widget.controller.position.maxScrollExtent;
            }

            _viewExtent = constraints.maxHeight;

            break;
          case Axis.horizontal:
            // Use supplied contentSize if we have it, otherwise just fallback to maxScrollExtents
            if (contentSize != null && contentSize > 0) {
              maxExtent = contentSize - constraints.maxWidth;
            } else {
              maxExtent = widget.controller.position.maxScrollExtent;
            }
            _viewExtent = constraints.maxWidth;

            break;
        }

        final contentExtent = maxExtent + _viewExtent;
        // Calculate the alignment for the handle, this is a value between 0 and 1,
        // it automatically takes the handle size into acct
        // ignore: omit_local_variable_types
        double handleAlignment =
            maxExtent == 0 ? 0 : widget.controller.offset / maxExtent;

        // Convert handle alignment from [0, 1] to [-1, 1]
        handleAlignment *= 2.0;
        handleAlignment -= 1.0;

        // Calculate handleSize by comparing the total content size to our viewport
        double handleExtent = _viewExtent;
        if (contentExtent > _viewExtent) {
          // Make sure handle is never small than the minSize
          handleExtent = max(60, _viewExtent * _viewExtent / contentExtent);
        }

        // Hide the handle if content is < the viewExtent
        var showHandle = hideHandler
            ? false
            : contentExtent > _viewExtent && contentExtent > 0;

        // Handle color
        var handleColor = widget.handleColor ??
            (Theme.of(context).brightness == Brightness.dark
                ? AFThemeExtension.of(context).lightGreyHover
                : AFThemeExtension.of(context).greyHover);
        // Track color
        var trackColor = widget.trackColor ??
            (Theme.of(context).brightness == Brightness.dark
                ? AFThemeExtension.of(context).lightGreyHover
                : AFThemeExtension.of(context).greyHover);

        // Layout the stack, it just contains a child, and
        return Stack(
          children: [
            /// TRACK, thin strip, aligned along the end of the parent
            if (widget.showTrack)
              Align(
                alignment: const Alignment(1, 1),
                child: Container(
                  color: trackColor,
                  width: widget.axis == Axis.vertical
                      ? widget.size
                      : double.infinity,
                  height: widget.axis == Axis.horizontal
                      ? widget.size
                      : double.infinity,
                ),
              ),

            /// HANDLE - Clickable shape that changes scrollController when dragged
            Align(
              // Use calculated alignment to position handle from -1 to 1, let Alignment do the rest of the work
              alignment: Alignment(
                widget.axis == Axis.vertical ? 1 : handleAlignment,
                widget.axis == Axis.horizontal ? 1 : handleAlignment,
              ),
              child: GestureDetector(
                onVerticalDragUpdate: _handleVerticalDrag,
                onHorizontalDragUpdate: _handleHorizontalDrag,
                // HANDLE SHAPE
                child: MouseHoverBuilder(
                  builder: (_, isHovered) => Container(
                    width: widget.axis == Axis.vertical
                        ? widget.size
                        : handleExtent,
                    height: widget.axis == Axis.horizontal
                        ? widget.size
                        : handleExtent,
                    decoration: BoxDecoration(
                      color: handleColor.withOpacity(isHovered ? 1 : .85),
                      borderRadius: Corners.s3Border,
                    ),
                  ),
                ),
              ),
            )
          ],
        ).opacity(showHandle ? 1.0 : 0.0, animate: true);
      },
    );
  }

  void _hideScrollbarInTime() {
    if (!mounted || !widget.autoHideScrollbar) return;

    _hideScrollbarOperation?.cancel();

    if (!widget.controller.position.isScrollingNotifier.value) {
      _hideScrollbarOperation = CancelableOperation.fromFuture(
        Future.delayed(const Duration(seconds: 2)),
      ).then((_) {
        hideHandler = true;
        if (mounted) {
          setState(() {});
        }
      });
    } else {
      hideHandler = false;
    }
  }

  void _handleHorizontalDrag(DragUpdateDetails details) {
    var pos = widget.controller.offset;
    var pxRatio = (widget.controller.position.maxScrollExtent + _viewExtent) /
        _viewExtent;
    widget.controller.jumpTo((pos + details.delta.dx * pxRatio)
        .clamp(0.0, widget.controller.position.maxScrollExtent));
    widget.onDrag?.call(details.delta.dx);
  }

  void _handleVerticalDrag(DragUpdateDetails details) {
    var pos = widget.controller.offset;
    var pxRatio = (widget.controller.position.maxScrollExtent + _viewExtent) /
        _viewExtent;
    widget.controller.jumpTo((pos + details.delta.dy * pxRatio)
        .clamp(0.0, widget.controller.position.maxScrollExtent));
    widget.onDrag?.call(details.delta.dy);
  }
}

class ScrollbarListStack extends StatelessWidget {
  const ScrollbarListStack({
    super.key,
    required this.barSize,
    required this.axis,
    required this.child,
    required this.controller,
    this.contentSize,
    this.scrollbarPadding,
    this.handleColor,
    this.autoHideScrollbar = true,
    this.trackColor,
    this.showTrack = false,
    this.includeInsets = true,
  });

  final double barSize;
  final Axis axis;
  final Widget child;
  final ScrollController controller;
  final double? contentSize;
  final EdgeInsets? scrollbarPadding;
  final Color? handleColor;
  final Color? trackColor;
  final bool showTrack;
  final bool autoHideScrollbar;
  final bool includeInsets;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// Wrap with a bit of padding on the right or bottom to make room for the scrollbar
        Padding(
          padding: !includeInsets
              ? EdgeInsets.zero
              : EdgeInsets.only(
                  right: axis == Axis.vertical ? barSize + Insets.m : 0,
                  bottom: axis == Axis.horizontal ? barSize + Insets.m : 0,
                ),
          child: child,
        ),

        /// Display the scrollbar
        Padding(
          padding: scrollbarPadding ?? EdgeInsets.zero,
          child: StyledScrollbar(
            size: barSize,
            axis: axis,
            controller: controller,
            contentSize: contentSize,
            trackColor: trackColor,
            handleColor: handleColor,
            autoHideScrollbar: autoHideScrollbar,
            showTrack: showTrack,
          ),
        )
            // The animate will be used by the children that are using styled_widget.
            .animate(const Duration(milliseconds: 250), Curves.easeOut),
      ],
    );
  }
}
