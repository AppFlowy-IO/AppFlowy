import 'package:flutter/material.dart';

class FlowyBoxContainer extends StatelessWidget {
  const FlowyBoxContainer({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 6.0,
        vertical: 8.0,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.onSecondary,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: child,
    );
  }
}
