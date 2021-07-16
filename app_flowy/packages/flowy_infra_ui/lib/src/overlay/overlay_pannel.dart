import 'dart:ui';

import 'package:flutter/material.dart';
import 'overlay_basis.dart';

class OverlayPannel extends SingleChildLayoutDelegate {
  OverlayPannel({
    required this.targetRect,
    this.anchorDirection = AnchorDirection.topRight,
    this.safeAreaEnabled = false,
    this.insets = EdgeInsets.zero,
  });

  final AnchorDirection anchorDirection;
  final bool safeAreaEnabled;
  final EdgeInsets insets;
  final Rect targetRect;

  @override
  bool shouldRelayout(OverlayPannel oldDelegate) {
    return targetRect != oldDelegate.targetRect ||
        insets != oldDelegate.insets ||
        safeAreaEnabled != oldDelegate.safeAreaEnabled ||
        anchorDirection != oldDelegate.anchorDirection;
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    var pannelRect = targetRect;
    if (safeAreaEnabled) {
      final safeArea = MediaQueryData.fromWindow(window).padding;
      pannelRect = safeArea.deflateRect(pannelRect);
    }

    // TODO: junlin - calculate child position
    return Offset.zero;
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen();
  }
}
