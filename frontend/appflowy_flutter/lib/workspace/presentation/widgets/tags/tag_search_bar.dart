import 'package:flutter/material.dart';

class TagSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const TagSearchBar({
    super.key,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search by tag...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
