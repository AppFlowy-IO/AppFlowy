import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import './popover.dart';

class PopoverLayoutDelegate extends SingleChildLayoutDelegate {
  PopoverLayoutDelegate({
    required this.link,
    required this.direction,
    required this.offset,
    required this.windowPadding,
    this.position,
    this.showAtCursor = false,
  });

  PopoverLink link;
  PopoverDirection direction;
  final Offset offset;
  final EdgeInsets windowPadding;

  /// Required when [showAtCursor] is true.
  ///
  final Offset? position;

  /// If true, the popover will be shown at the cursor position.
  /// This will ignore the [direction], and the child size.
  ///
  final bool showAtCursor;

  @override
  bool shouldRelayout(PopoverLayoutDelegate oldDelegate) {
    if (direction != oldDelegate.direction) {
      return true;
    }

    if (link != oldDelegate.link) {
      return true;
    }

    if (link.leaderOffset != oldDelegate.link.leaderOffset) {
      return true;
    }

    if (link.leaderSize != oldDelegate.link.leaderSize) {
      return true;
    }

    return false;
  }

  @override
  Size getSize(BoxConstraints constraints) {
    return Size(
      constraints.maxWidth - windowPadding.left - windowPadding.right,
      constraints.maxHeight - windowPadding.top - windowPadding.bottom,
    );
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      maxWidth: constraints.maxWidth - windowPadding.left - windowPadding.right,
      maxHeight:
          constraints.maxHeight - windowPadding.top - windowPadding.bottom,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final effectiveOffset = link.leaderOffset;
    final leaderSize = link.leaderSize;

    if (effectiveOffset == null || leaderSize == null) {
      return Offset.zero;
    }

    Offset position;
    if (showAtCursor && this.position != null) {
      position = this.position! +
          Offset(
            effectiveOffset.dx + offset.dx,
            effectiveOffset.dy + offset.dy,
          );
    } else {
      final anchorRect = Rect.fromLTWH(
        effectiveOffset.dx + offset.dx,
        effectiveOffset.dy + offset.dy,
        leaderSize.width,
        leaderSize.height,
      );

      switch (direction) {
        case PopoverDirection.topLeft:
          position = Offset(
            anchorRect.left - childSize.width,
            anchorRect.top - childSize.height,
          );
          break;
        case PopoverDirection.topRight:
          position = Offset(
            anchorRect.right,
            anchorRect.top - childSize.height,
          );
          break;
        case PopoverDirection.bottomLeft:
          position = Offset(
            anchorRect.left - childSize.width,
            anchorRect.bottom,
          );
          break;
        case PopoverDirection.bottomRight:
          position = Offset(
            anchorRect.right,
            anchorRect.bottom,
          );
          break;
        case PopoverDirection.center:
          position = anchorRect.center;
          break;
        case PopoverDirection.topWithLeftAligned:
          position = Offset(
            anchorRect.left,
            anchorRect.top - childSize.height,
          );
          break;
        case PopoverDirection.topWithCenterAligned:
          position = Offset(
            anchorRect.left + anchorRect.width / 2.0 - childSize.width / 2.0,
            anchorRect.top - childSize.height,
          );
          break;
        case PopoverDirection.topWithRightAligned:
          position = Offset(
            anchorRect.right - childSize.width,
            anchorRect.top - childSize.height,
          );
          break;
        case PopoverDirection.rightWithTopAligned:
          position = Offset(anchorRect.right, anchorRect.top);
          break;
        case PopoverDirection.rightWithCenterAligned:
          position = Offset(
            anchorRect.right,
            anchorRect.top + anchorRect.height / 2.0 - childSize.height / 2.0,
          );
          break;
        case PopoverDirection.rightWithBottomAligned:
          position = Offset(
            anchorRect.right,
            anchorRect.bottom - childSize.height,
          );
          break;
        case PopoverDirection.bottomWithLeftAligned:
          position = Offset(
            anchorRect.left,
            anchorRect.bottom,
          );
          break;
        case PopoverDirection.bottomWithCenterAligned:
          position = Offset(
            anchorRect.left + anchorRect.width / 2.0 - childSize.width / 2.0,
            anchorRect.bottom,
          );
          break;
        case PopoverDirection.bottomWithRightAligned:
          position = Offset(
            anchorRect.right - childSize.width,
            anchorRect.bottom,
          );
          break;
        case PopoverDirection.leftWithTopAligned:
          position = Offset(
            anchorRect.left - childSize.width,
            anchorRect.top,
          );
          break;
        case PopoverDirection.leftWithCenterAligned:
          position = Offset(
            anchorRect.left - childSize.width,
            anchorRect.top + anchorRect.height / 2.0 - childSize.height / 2.0,
          );
          break;
        case PopoverDirection.leftWithBottomAligned:
          position = Offset(
            anchorRect.left - childSize.width,
            anchorRect.bottom - childSize.height,
          );
          break;
        default:
          throw UnimplementedError();
      }
    }

    return Offset(
      math.max(
        windowPadding.left,
        math.min(
          windowPadding.left + size.width - childSize.width,
          position.dx,
        ),
      ),
      math.max(
        windowPadding.top,
        math.min(
          windowPadding.top + size.height - childSize.height,
          position.dy,
        ),
      ),
    );
  }

  PopoverLayoutDelegate copyWith({
    PopoverLink? link,
    PopoverDirection? direction,
    Offset? offset,
    EdgeInsets? windowPadding,
    Offset? position,
    bool? showAtCursor,
  }) {
    return PopoverLayoutDelegate(
      link: link ?? this.link,
      direction: direction ?? this.direction,
      offset: offset ?? this.offset,
      windowPadding: windowPadding ?? this.windowPadding,
      position: position ?? this.position,
      showAtCursor: showAtCursor ?? this.showAtCursor,
    );
  }
}

class PopoverTarget extends SingleChildRenderObjectWidget {
  const PopoverTarget({
    super.key,
    super.child,
    required this.link,
  });

  final PopoverLink link;

  @override
  PopoverTargetRenderBox createRenderObject(BuildContext context) {
    return PopoverTargetRenderBox(
      link: link,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    PopoverTargetRenderBox renderObject,
  ) {
    renderObject.link = link;
  }
}

class PopoverTargetRenderBox extends RenderProxyBox {
  PopoverTargetRenderBox({
    required this.link,
    RenderBox? child,
  }) : super(child);

  PopoverLink link;

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  void performLayout() {
    super.performLayout();
    link.leaderSize = size;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    link.leaderOffset = localToGlobal(Offset.zero);
    super.paint(context, offset);
  }

  @override
  void detach() {
    super.detach();
    link.leaderOffset = null;
    link.leaderSize = null;
  }

  @override
  void attach(covariant PipelineOwner owner) {
    super.attach(owner);
    if (hasSize) {
      // The leaderSize was set after [performLayout], but was
      // set to null when [detach] get called.
      //
      // set the leaderSize when attach get called
      link.leaderSize = size;
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<PopoverLink>('link', link));
  }
}

class PopoverLink {
  Offset? leaderOffset;
  Size? leaderSize;
}
