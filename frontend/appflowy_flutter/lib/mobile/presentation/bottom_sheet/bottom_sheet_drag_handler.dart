import 'package:flutter/material.dart';

class MobileBottomSheetDragHandler extends StatelessWidget {
  const MobileBottomSheetDragHandler({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 12.0),
      child: Container(
        width: 64,
        height: 4,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2.0),
          color: Colors.grey,
        ),
      ),
    );
  }
}
