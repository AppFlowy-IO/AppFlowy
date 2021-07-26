import 'dart:ui';

import 'package:flutter/material.dart';
import 'overlay_basis.dart';

class OverlayLayoutDelegate extends SingleChildLayoutDelegate {
  OverlayLayoutDelegate({
    required this.anchorRect,
    required this.targetRect,
    required this.anchorDirection,
    required this.safeAreaEnabled,
    required this.insets,
  });

  final AnchorDirection anchorDirection;
  final bool safeAreaEnabled;
  final EdgeInsets insets;
  final Rect anchorRect;
  final Rect targetRect;

  @override
  bool shouldRelayout(OverlayLayoutDelegate oldDelegate) {
    return anchorRect != oldDelegate.anchorRect ||
        insets != oldDelegate.insets ||
        safeAreaEnabled != oldDelegate.safeAreaEnabled ||
        anchorDirection != oldDelegate.anchorDirection;
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // calculate the pannel maximum available rect
    var pannelRect = Rect.fromLTWH(0, 0, size.width, size.height);
    pannelRect = insets.deflateRect(pannelRect);
    // apply safearea
    if (safeAreaEnabled) {
      final safeArea = MediaQueryData.fromWindow(window).padding;
      pannelRect = safeArea.deflateRect(pannelRect);
    }

    // clip pannel rect

    // TODO: junlin - calculate child position
    return Offset.zero;
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen();
  }
}
