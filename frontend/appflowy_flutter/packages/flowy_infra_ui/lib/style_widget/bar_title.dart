import 'package:flutter/material.dart';

class FlowyBarTitle extends StatelessWidget {
  final String title;

  const FlowyBarTitle({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 24),
    );
  }
}
