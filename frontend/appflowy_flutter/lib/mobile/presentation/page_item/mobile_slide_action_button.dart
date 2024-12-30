import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class MobileSlideActionButton extends StatelessWidget {
  const MobileSlideActionButton({
    super.key,
    required this.svg,
    this.size = 32.0,
    this.backgroundColor = Colors.transparent,
    this.borderRadius = BorderRadius.zero,
    required this.onPressed,
  });

  final FlowySvgData svg;
  final double size;
  final Color backgroundColor;
  final SlidableActionCallback onPressed;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return CustomSlidableAction(
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      onPressed: (context) {
        HapticFeedback.mediumImpact();
        onPressed(context);
      },
      padding: EdgeInsets.zero,
      child: FlowySvg(
        svg,
        size: Size.square(size),
        color: Colors.white,
      ),
    );
  }
}
