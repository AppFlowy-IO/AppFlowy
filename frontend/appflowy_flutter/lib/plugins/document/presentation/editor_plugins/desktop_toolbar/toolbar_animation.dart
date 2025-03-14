import 'package:flutter/material.dart';

class ToolbarAnimationWidget extends StatefulWidget {
  const ToolbarAnimationWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
    this.beginOpacity = 0.0,
    this.endOpacity = 1.0,
    this.beginScaleFactor = 0.9,
    this.endScaleFactor = 1.0,
  });

  final Widget child;
  final Duration duration;
  final double beginScaleFactor;
  final double endScaleFactor;
  final double beginOpacity;
  final double endOpacity;

  @override
  State<ToolbarAnimationWidget> createState() => _ToolbarAnimationWidgetState();
}

class _ToolbarAnimationWidgetState extends State<ToolbarAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> fadeAnimation;
  late Animation<double> scaleAnimation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    fadeAnimation = _buildFadeAnimation();
    scaleAnimation = _buildScaleAnimation();
    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, child) => Opacity(
        opacity: fadeAnimation.value,
        child: Transform.scale(
          scale: scaleAnimation.value,
          child: child,
        ),
      ),
      child: widget.child,
    );
  }

  Animation<double> _buildFadeAnimation() {
    return Tween<double>(
      begin: widget.beginOpacity,
      end: widget.endOpacity,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  Animation<double> _buildScaleAnimation() {
    return Tween<double>(
      begin: widget.beginScaleFactor,
      end: widget.endScaleFactor,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ),
    );
  }
}
