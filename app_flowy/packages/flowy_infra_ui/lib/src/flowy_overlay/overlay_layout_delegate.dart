import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'flowy_overlay.dart';

class OverlayLayoutDelegate extends SingleChildLayoutDelegate {
  OverlayLayoutDelegate({
    required this.anchorRect,
    required this.anchorDirection,
  });

  final Rect anchorRect;
  final AnchorDirection anchorDirection;

  @override
  bool shouldRelayout(OverlayLayoutDelegate oldDelegate) {
    return anchorRect != oldDelegate.anchorRect || anchorDirection != oldDelegate.anchorDirection;
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen();
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // TODO: junlin - calculate child position
    return Offset(anchorRect.width / 2, anchorRect.height / 2);
  }
}
