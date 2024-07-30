import 'package:appflowy/shared/feedback_gesture_detector.dart';
import 'package:flutter/material.dart';

class AnimatedGestureDetector extends StatefulWidget {
  const AnimatedGestureDetector({
    super.key,
    this.scaleFactor = 0.98,
    this.feedback = true,
    this.duration = const Duration(milliseconds: 100),
    this.alignment = Alignment.center,
    this.behavior = HitTestBehavior.opaque,
    required this.onTapUp,
    required this.child,
  });

  final Widget child;
  final double scaleFactor;
  final Duration duration;
  final Alignment alignment;
  final bool feedback;
  final HitTestBehavior behavior;
  final VoidCallback onTapUp;

  @override
  State<AnimatedGestureDetector> createState() =>
      _AnimatedGestureDetectorState();
}

class _AnimatedGestureDetectorState extends State<AnimatedGestureDetector> {
  double scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapUp: (details) {
        setState(() => scale = 1.0);

        HapticFeedbackType.light.call();

        widget.onTapUp();
      },
      onTapDown: (details) {
        setState(() => scale = widget.scaleFactor);
      },
      child: AnimatedScale(
        scale: scale,
        alignment: widget.alignment,
        duration: widget.duration,
        child: widget.child,
      ),
    );
  }
}
