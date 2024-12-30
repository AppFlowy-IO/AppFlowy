import 'package:flutter/material.dart';

class FlowyBarTitle extends StatelessWidget {
  final String title;

  const FlowyBarTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 24),
    );
  }
}
