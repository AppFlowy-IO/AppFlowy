import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flutter/material.dart';

class AppBarBackButton extends StatelessWidget {
  const AppBarBackButton({
    super.key,
    this.extent = 16.0,
    required this.onTap,
  });

  // used to extend the hit area of the back button
  final double extent;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      enableFeedback: true,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(extent),
        child: const FlowySvg(
          FlowySvgs.back_m,
          size: Size.square(12.0),
        ),
      ),
    );
  }
}

class AppBarMoreButton extends StatelessWidget {
  const AppBarMoreButton({
    super.key,
    this.extent = 16.0,
    required this.onTap,
  });

  // used to extend the hit area of the more button
  final double extent;

  final void Function(BuildContext context) onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      enableFeedback: true,
      onTap: () => onTap(context),
      child: Padding(
        padding: EdgeInsets.all(extent),
        child: const FlowySvg(
          FlowySvgs.three_dots_s,
          size: Size.square(20.0),
        ),
      ),
    );
  }
}
