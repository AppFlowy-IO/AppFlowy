import 'package:flutter/material.dart';

class PropertyTitle extends StatelessWidget {
  const PropertyTitle(this.name, {super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        name,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onBackground,
              fontSize: 16,
            ),
      ),
    );
  }
}
