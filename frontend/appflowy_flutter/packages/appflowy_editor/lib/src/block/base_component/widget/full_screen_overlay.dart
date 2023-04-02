import 'package:flutter/material.dart';

extension FullScreenOverlayEntry on OverlayEntry {
  static OverlayEntry build({
    required VoidCallback onDismiss,
    required Offset offset,
    required Widget child,
  }) {
    late OverlayEntry entry;
    entry = OverlayEntry(builder: (context) {
      final size = MediaQuery.of(context).size;
      return Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            width: size.width,
            height: size.height,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => entry.remove(),
            ),
          ),
          Positioned(
            top: offset.dy,
            left: offset.dx,
            child: child,
          ),
        ],
      );
    });
    return entry;
  }
}
