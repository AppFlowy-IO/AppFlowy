import 'package:flutter/material.dart';

class IgnoreParentGestureWidget extends StatelessWidget {
  const IgnoreParentGestureWidget({
    super.key,
    required this.child,
    this.onPress,
  });

  final Widget child;
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    // https://docs.flutter.dev/development/ui/advanced/gestures#gesture-disambiguation
    // https://github.com/AppFlowy-IO/AppFlowy/issues/1290
    return Listener(
      onPointerDown: (event) {
        onPress?.call();
      },
      onPointerSignal: (event) {},
      onPointerMove: (event) {},
      onPointerUp: (event) {},
      onPointerHover: (event) {},
      onPointerPanZoomStart: (event) {},
      onPointerPanZoomUpdate: (event) {},
      onPointerPanZoomEnd: (event) {},
      child: child,
    );
  }
}
