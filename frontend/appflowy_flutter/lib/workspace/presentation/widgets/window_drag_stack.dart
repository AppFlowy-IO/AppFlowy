import 'package:appflowy/core/frameless_window.dart';
import 'package:flutter/material.dart';

class WindowDragStack extends StatelessWidget {
  const WindowDragStack({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const MoveWindowDetector(),
        Positioned.fill(child: child),
      ],
    );
  }
}
