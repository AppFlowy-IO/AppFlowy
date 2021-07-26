import 'package:flutter/material.dart';

import 'overlay_basis.dart';
import 'overlay_layout_delegate.dart';

class OverlayPannel extends StatelessWidget {
  const OverlayPannel({
    Key? key,
    required this.child,
    required this.targetRect,
    required this.anchorRect,
    this.safeAreaEnabled = true,
    this.anchorDirection = AnchorDirection.topRight,
    this.insets = EdgeInsets.zero,
  }) : super(key: key);

  final AnchorDirection anchorDirection;
  final bool safeAreaEnabled;
  final EdgeInsets insets;
  final Rect targetRect;
  final Rect anchorRect;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomSingleChildLayout(
      delegate: OverlayLayoutDelegate(
        targetRect: targetRect,
        anchorRect: anchorRect,
        safeAreaEnabled: safeAreaEnabled,
        anchorDirection: anchorDirection,
        insets: insets,
      ),
      child: child,
    );
  }
}
