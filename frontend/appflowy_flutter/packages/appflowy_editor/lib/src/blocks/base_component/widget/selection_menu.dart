import 'package:flutter/material.dart';

extension FullScreenOverlayEntry on OverlayEntry {
  static OverlayEntry build({
    required VoidCallback onDismiss,
    required Offset offset,
    required Widget child,
  }) {
    return OverlayEntry(builder: (context) {
      final size = MediaQuery.of(context).size;
      return Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            width: size.width,
            height: size.height,
            child: GestureDetector(
              onTap: () => onDismiss(),
              child: Container(
                color: Colors.red.withOpacity(0.5),
              ),
            ),
          ),
          Positioned(
            top: offset.dy,
            left: offset.dx,
            child: child,
          )
        ],
      );
    });
  }
}
