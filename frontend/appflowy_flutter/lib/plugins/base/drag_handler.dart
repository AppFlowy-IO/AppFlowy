import 'package:flutter/material.dart';

class DragHandler extends StatelessWidget {
  const DragHandler({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      width: 40,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
