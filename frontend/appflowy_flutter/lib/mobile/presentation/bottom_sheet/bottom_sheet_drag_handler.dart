import 'package:flutter/material.dart';

class MobileBottomSheetDragHandler extends StatelessWidget {
  const MobileBottomSheetDragHandler({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Container(
        width: 60,
        height: 4,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2.0),
          color: Theme.of(context).hintColor,
        ),
      ),
    );
  }
}
