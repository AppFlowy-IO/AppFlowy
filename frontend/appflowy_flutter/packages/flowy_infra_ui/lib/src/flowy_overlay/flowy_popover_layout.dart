import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'flowy_overlay.dart';

class PopoverLayoutDelegate extends SingleChildLayoutDelegate {
  PopoverLayoutDelegate({
    required this.anchorRect,
    required this.anchorDirection,
    required this.overlapBehaviour,
  });

  final Rect anchorRect;
  final AnchorDirection anchorDirection;
  final OverlapBehaviour overlapBehaviour;

  @override
  bool shouldRelayout(PopoverLayoutDelegate oldDelegate) {
    return anchorRect != oldDelegate.anchorRect ||
        anchorDirection != oldDelegate.anchorDirection ||
        overlapBehaviour != oldDelegate.overlapBehaviour;
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    switch (overlapBehaviour) {
      case OverlapBehaviour.none:
        return constraints.loosen();
      case OverlapBehaviour.stretch:
        BoxConstraints childConstraints;
        switch (anchorDirection) {
          case AnchorDirection.topLeft:
            childConstraints = BoxConstraints.loose(Size(
              anchorRect.left,
              anchorRect.top,
            ));
            break;
          case AnchorDirection.topRight:
            childConstraints = BoxConstraints.loose(Size(
              constraints.maxWidth - anchorRect.right,
              anchorRect.top,
            ));
            break;
          case AnchorDirection.bottomLeft:
            childConstraints = BoxConstraints.loose(Size(
              anchorRect.left,
              constraints.maxHeight - anchorRect.bottom,
            ));
            break;
          case AnchorDirection.bottomRight:
            childConstraints = BoxConstraints.loose(Size(
              constraints.maxWidth - anchorRect.right,
              constraints.maxHeight - anchorRect.bottom,
            ));
            break;
          case AnchorDirection.center:
            childConstraints = BoxConstraints.loose(Size(
              constraints.maxWidth,
              constraints.maxHeight,
            ));
            break;
          case AnchorDirection.topWithLeftAligned:
            childConstraints = BoxConstraints.loose(Size(
              constraints.maxWidth - anchorRect.left,
              anchorRect.top,
            ));
            break;
          case AnchorDirection.topWithCenterAligned:
            childConstraints = BoxConstraints.loose(Size(
              constraints.maxWidth,
              anchorRect.top,
            ));
            break;
          case AnchorDirection.topWithRightAligned:
            childConstraints = BoxConstraints.loose(Size(
              anchorRect.right,
              anchorRect.top,
            ));
            break;
          case AnchorDirection.rightWithTopAligned:
            childConstraints = BoxConstraints.loose(Size(
              constraints.maxWidth - anchorRect.right,
              constraints.maxHeight - anchorRect.top,
            ));
            break;
          case AnchorDirection.rightWithCenterAligned:
            childConstraints = BoxConstraints.loose(Size(
              constraints.maxWidth - anchorRect.right,
              constraints.maxHeight,
            ));
            break;
          case AnchorDirection.rightWithBottomAligned:
            childConstraints = BoxConstraints.loose(Size(
              constraints.maxWidth - anchorRect.right,
              anchorRect.bottom,
            ));
            break;
          case AnchorDirection.bottomWithLeftAligned:
            childConstraints = BoxConstraints.loose(Size(
              anchorRect.left,
              constraints.maxHeight - anchorRect.bottom,
            ));
            break;
          case AnchorDirection.bottomWithCenterAligned:
            childConstraints = BoxConstraints.loose(Size(
              constraints.maxWidth,
              constraints.maxHeight - anchorRect.bottom,
            ));
            break;
          case AnchorDirection.bottomWithRightAligned:
            childConstraints = BoxConstraints.loose(Size(
              anchorRect.right,
              constraints.maxHeight - anchorRect.bottom,
            ));
            break;
          case AnchorDirection.leftWithTopAligned:
            childConstraints = BoxConstraints.loose(Size(
              anchorRect.left,
              constraints.maxHeight - anchorRect.top,
            ));
            break;
          case AnchorDirection.leftWithCenterAligned:
            childConstraints = BoxConstraints.loose(Size(
              anchorRect.left,
              constraints.maxHeight,
            ));
            break;
          case AnchorDirection.leftWithBottomAligned:
            childConstraints = BoxConstraints.loose(Size(
              anchorRect.left,
              anchorRect.bottom,
            ));
            break;
          case AnchorDirection.custom:
            childConstraints = constraints.loosen();
            break;
          default:
            throw UnimplementedError();
        }
        return childConstraints;
    }
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    Offset position;
    switch (anchorDirection) {
      case AnchorDirection.topLeft:
        position = Offset(
          anchorRect.left - childSize.width,
          anchorRect.top - childSize.height,
        );
        break;
      case AnchorDirection.topRight:
        position = Offset(
          anchorRect.right,
          anchorRect.top - childSize.height,
        );
        break;
      case AnchorDirection.bottomLeft:
        position = Offset(
          anchorRect.left - childSize.width,
          anchorRect.bottom,
        );
        break;
      case AnchorDirection.bottomRight:
        position = Offset(
          anchorRect.right,
          anchorRect.bottom,
        );
        break;
      case AnchorDirection.center:
        position = anchorRect.center;
        break;
      case AnchorDirection.topWithLeftAligned:
        position = Offset(
          anchorRect.left,
          anchorRect.top - childSize.height,
        );
        break;
      case AnchorDirection.topWithCenterAligned:
        position = Offset(
          anchorRect.left + anchorRect.width / 2.0 - childSize.width / 2.0,
          anchorRect.top - childSize.height,
        );
        break;
      case AnchorDirection.topWithRightAligned:
        position = Offset(
          anchorRect.right - childSize.width,
          anchorRect.top - childSize.height,
        );
        break;
      case AnchorDirection.rightWithTopAligned:
        position = Offset(anchorRect.right, anchorRect.top);
        break;
      case AnchorDirection.rightWithCenterAligned:
        position = Offset(
          anchorRect.right,
          anchorRect.top + anchorRect.height / 2.0 - childSize.height / 2.0,
        );
        break;
      case AnchorDirection.rightWithBottomAligned:
        position = Offset(
          anchorRect.right,
          anchorRect.bottom - childSize.height,
        );
        break;
      case AnchorDirection.bottomWithLeftAligned:
        position = Offset(
          anchorRect.left,
          anchorRect.bottom,
        );
        break;
      case AnchorDirection.bottomWithCenterAligned:
        position = Offset(
          anchorRect.left + anchorRect.width / 2.0 - childSize.width / 2.0,
          anchorRect.bottom,
        );
        break;
      case AnchorDirection.bottomWithRightAligned:
        position = Offset(
          anchorRect.right - childSize.width,
          anchorRect.bottom,
        );
        break;
      case AnchorDirection.leftWithTopAligned:
        position = Offset(
          anchorRect.left - childSize.width,
          anchorRect.top,
        );
        break;
      case AnchorDirection.leftWithCenterAligned:
        position = Offset(
          anchorRect.left - childSize.width,
          anchorRect.top + anchorRect.height / 2.0 - childSize.height / 2.0,
        );
        break;
      case AnchorDirection.leftWithBottomAligned:
        position = Offset(
          anchorRect.left - childSize.width,
          anchorRect.bottom - childSize.height,
        );
        break;
      default:
        throw UnimplementedError();
    }
    return Offset(
      math.max(0.0, math.min(size.width - childSize.width, position.dx)),
      math.max(0.0, math.min(size.height - childSize.height, position.dy)),
    );
  }
}
