import 'package:flutter/material.dart';

class PropertyEditContainer extends StatelessWidget {
  const PropertyEditContainer({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.centerLeft,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8),
      child: child,
    );
  }
}
