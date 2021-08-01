import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'flowy_overlay.dart';

class OverlayLayoutDelegate extends SingleChildLayoutDelegate {
  OverlayLayoutDelegate({
    required this.anchorRect,
    required this.anchorDirection,
    required this.overlapBehaviour,
  });

  final Rect anchorRect;
  final AnchorDirection anchorDirection;
  final OverlapBehaviour overlapBehaviour;

  @override
  bool shouldRelayout(OverlayLayoutDelegate oldDelegate) {
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
        // TODO: junlin - resize when overlapBehaviour == .stretch
        return constraints.loosen();
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
      default:
        throw UnimplementedError();
    }
    return Offset(
      math.max(0.0, math.min(size.width, position.dx)),
      math.max(0.0, math.min(size.height, position.dy)),
    );
  }
}
