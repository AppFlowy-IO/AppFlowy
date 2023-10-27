import 'package:flutter/material.dart';

class AppBarBackButton extends StatelessWidget {
  const AppBarBackButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppBarButton(
      onTap: onTap,
      child: const Icon(Icons.arrow_back_ios_new),
    );
  }
}

class AppBarMoreButton extends StatelessWidget {
  const AppBarMoreButton({
    super.key,
    required this.onTap,
  });

  final void Function(BuildContext context) onTap;

  @override
  Widget build(BuildContext context) {
    return AppBarButton(
      onTap: () => onTap(context),
      child: const Icon(
        // replace with flowy icon
        Icons.more_horiz_sharp,
      ),
    );
  }
}

class AppBarButton extends StatelessWidget {
  const AppBarButton({
    super.key,
    this.extent = 16.0,
    required this.onTap,
    required this.child,
  });

  // used to extend the hit area of the more button
  final double extent;

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      enableFeedback: true,
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(extent),
        child: child,
      ),
    );
  }
}
